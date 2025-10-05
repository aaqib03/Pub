You got it! Here’s a single, copy-paste end-to-end implementation (infra + code) that adds Bedrock Guardrails to your MVP while keeping everything fast and simple (Option-A: single KB + server-side metadata filters).

Save this as MVP_WITH_GUARDRAILS.md in your repo and follow it top-to-bottom.


---

# ⚡ AI Onboarding Chatbot (MVP) — with Bedrock Guardrails
**Goal:** Google Chat → API Gateway → Lambda (Python) → Bedrock Knowledge Base (S3)  
**Safety:** Server-side ABAC filters (department/region) + **Bedrock Guardrails**  
**Infra:** Terraform (AWS), no VPC needed for MVP (fast cold starts)  

> Assumes you already have: **S3 bucket** (docs) and **KMS key**.  
> We’ll pass your **KB ID** and **Guardrail ID** into Lambda via Terraform variables.

---

## 0) Repo Layout (copy this)

mvp/ ├─ terraform/ │  ├─ providers.tf │  ├─ variables.tf │  ├─ locals.tf │  ├─ iam.tf │  ├─ dynamodb.tf │  ├─ lambda.tf │  ├─ api_gw.tf │  ├─ cloudwatch.tf │  └─ outputs.tf ├─ lambda/ │  ├─ chat_webhook.py │  ├─ requirements.txt │  └─ utils/ │     ├─ ddb.py │     ├─ filters.py │     └─ log.py ├─ scripts/ │  ├─ create_kb_once.sh │  ├─ trigger_ingestion.sh │  └─ create_guardrail_once.sh └─ docs-examples/ ├─ it/vpn_access.md └─ it/vpn_access.md.metadata.json

---

## 1) Bedrock Knowledge Base & Guardrail (one-time)

### 1.1 Create (or confirm) the Knowledge Base (KB)
- Console: **Amazon Bedrock → Knowledge Bases → Create**  
  - Data source: **S3** (your bucket/prefix)  
  - Embedding model: **Amazon Titan Embeddings G1 – Text**  
  - Encryption: select your **KMS key**  
- Record the **Knowledge Base ID** and **Data Source ID**.

> Sidecar metadata for every file (for ABAC filtering):
```json
// s3://<bucket>/docs/it/vpn_access.md.metadata.json
{
  "department": "IT",
  "region": ["US","GLOBAL"],
  "sensitivity": "internal",
  "owner": "it-ops@example.com",
  "version": "v1"
}

1.2 Create a Guardrail (console or script)

Console: Bedrock → Guardrails → Create

Name: onboard-guardrail

Policies:

PII: Block exposure (detect & redact)

Safety: block harassment, sexual, hate (balanced)

Topic rules (optional): block “security architecture”, “source code”, etc.


Output: note Guardrail ID and version (typically "1")



Or use the helper script (edit config inline to meet policy):

# scripts/create_guardrail_once.sh
#!/usr/bin/env bash
set -euo pipefail
REGION=${REGION:-us-east-1}
NAME=${1:-onboard-guardrail}
CFG='{
  "name": "'$NAME'",
  "description": "Guardrail for onboarding chatbot: PII redaction, unsafe content blocks, cross-dept leakage discourage.",
  "blockedInputMessaging": "Your request appears unsafe or outside your access scope.",
  "blockedOutputsMessaging": "I can’t share that. Please ask HR/IT directly.",
  "policiesConfig": {
    "harm": {
      "hate": "MEDIUM",
      "sexual": "MEDIUM",
      "selfHarm": "HIGH",
      "violence": "MEDIUM"
    },
    "pii": { "policy": "REDACT", "maskMode": "REPLACE" }
  }
}'
aws bedrock create-guardrail --region $REGION --cli-input-json "$CFG"

Output prints a JSON containing "guardrailId" and "version"; keep them.


---

2) Terraform — Infrastructure

terraform/providers.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws    = { source = "hashicorp/aws",    version = ">= 5.50.0" }
    archive= { source = "hashicorp/archive",version = ">= 2.5.0" }
  }
}
provider "aws" { region = var.aws_region }

terraform/variables.tf

variable "project"            { type = string  default = "onboard-mvp" }
variable "aws_region"         { type = string  default = "us-east-1" }

# existing resources
variable "kb_s3_bucket_name"  { type = string }   # S3 with docs
variable "kms_key_arn"        { type = string }   # your KMS key ARN

# created earlier (console or script)
variable "bedrock_kb_id"      { type = string }   # kb-xxxxxxxxxxxxxxxx
variable "guardrail_id"       { type = string }   # gr-xxxxxxxxxxxxxxxx
variable "guardrail_version"  { type = string  default = "1" }

# model for RAG
variable "bedrock_model_arn" {
  type    = string
  default = "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
}

# MVP shared secret (swap later with Google signature verify)
variable "chat_shared_secret" { type = string, sensitive = true, default = "" }

terraform/locals.tf

locals {
  lambda_name    = "${var.project}-chat-webhook"
  role_name      = "${var.project}-lambda-role"
  api_name       = "${var.project}-httpapi"
  ddb_user_table = "${var.project}-user-profile"
  ddb_log_table  = "${var.project}-chat-logs"
}

terraform/iam.tf

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["lambda.amazonaws.com"] }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid     = "Logs"
    actions = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    sid     = "DynamoDB"
    actions = ["dynamodb:GetItem","dynamodb:PutItem","dynamodb:UpdateItem"]
    resources = [
      aws_dynamodb_table.user_profile.arn,
      aws_dynamodb_table.chat_logs.arn
    ]
  }
  statement {
    sid     = "BedrockAgentRuntime"
    actions = ["bedrock:Retrieve","bedrock:RetrieveAndGenerate"]
    resources = ["*"]
  }
  statement {
    sid     = "S3ReadDocs"
    actions = ["s3:GetObject","s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.kb_s3_bucket_name}",
      "arn:aws:s3:::${var.kb_s3_bucket_name}/*"
    ]
  }
  statement {
    sid     = "KMSDecrypt"
    actions = ["kms:Decrypt"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_policy" "lambda_inline" {
  name   = "${var.project}-lambda-inline"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_inline.arn
}

terraform/dynamodb.tf

resource "aws_dynamodb_table" "user_profile" {
  name         = local.ddb_user_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  attribute { name = "user_id" type = "S" }
}

resource "aws_dynamodb_table" "chat_logs" {
  name         = local.ddb_log_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "log_id"
  attribute { name = "log_id" type = "S" }
  ttl { attribute_name = "ttl" enabled = true }
}

terraform/cloudwatch.tf

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_metric_alarm" "lambda_p95_high" {
  alarm_name          = "${var.project}-lambda-p95-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "p95"
  threshold           = 2500
  dimensions = { FunctionName = local.lambda_name }
}

terraform/lambda.tf

data "archive_file" "chat_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda.zip"
}

resource "aws_lambda_function" "chat" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.12"
  handler       = "chat_webhook.handler"
  filename      = data.archive_file.chat_zip.output_path
  timeout       = 10
  memory_size   = 512
  environment {
    variables = {
      AWS_REGION          = var.aws_region
      KNOWLEDGE_BASE_ID   = var.bedrock_kb_id
      MODEL_ARN           = var.bedrock_model_arn
      GUARDRAIL_ID        = var.guardrail_id
      GUARDRAIL_VERSION   = var.guardrail_version
      DDB_USER_TABLE      = aws_dynamodb_table.user_profile.name
      DDB_LOG_TABLE       = aws_dynamodb_table.chat_logs.name
      CHAT_SHARED_SECRET  = var.chat_shared_secret
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}

terraform/api_gw.tf

resource "aws_apigatewayv2_api" "http" {
  name          = local.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_int" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.chat.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "chat" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_int.id}"
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

terraform/outputs.tf

output "http_api_invoke_url" { value = aws_apigatewayv2_api.http.api_endpoint }
output "ddb_user_table"      { value = aws_dynamodb_table.user_profile.name }
output "ddb_chat_logs"       { value = aws_dynamodb_table.chat_logs.name }


---

3) Lambda — Code (with Guardrails + Filters)

lambda/requirements.txt

boto3==1.34.131

lambda/utils/ddb.py

import os, boto3
TBL = os.environ.get("DDB_USER_TABLE")
ddb = boto3.client("dynamodb")

def get_user_profile(user_id: str) -> dict:
    if not TBL or not user_id:
        return {}
    res = ddb.get_item(TableName=TBL, Key={"user_id": {"S": user_id}})
    if "Item" not in res: return {}
    it = res["Item"]
    return {
        "department": it.get("department", {}).get("S"),
        "region":     it.get("region", {}).get("S", "GLOBAL"),
    }

lambda/utils/filters.py

def build_retrieval_filter(dept: str|None, region: str|None) -> dict:
    # Fail-closed if we don't know the user
    if not dept or not region:
        return {"equals": {"key":"department","value":"__deny__"}}
    return {
        "andAll": [
            {"equals": {"key": "department", "value": dept}},
            {"in":     {"key": "region",     "value": [region, "GLOBAL"]}},
            {"equals": {"key": "sensitivity","value": "internal"}}
        ]
    }

lambda/utils/log.py

import json, os, time, uuid, boto3
LOG_TBL = os.environ.get("DDB_LOG_TABLE")
ddb = boto3.client("dynamodb")

def log_interaction(user_id: str, text: str, answer: str, sources: list, latency_ms: int, blocked: bool=False):
    if not LOG_TBL: return
    now = int(time.time())
    item = {
        "log_id":   {"S": str(uuid.uuid4())},
        "user_id":  {"S": user_id or "unknown"},
        "ts":       {"N": str(now)},
        "latency":  {"N": str(latency_ms)},
        "blocked":  {"BOOL": bool(blocked)},
        "q":        {"S": text[:1000]},
        "a":        {"S": (answer or "")[:1500]},
        "sources":  {"S": json.dumps(sources)[:1500]},
        "ttl":      {"N": str(now + 90*24*3600)}
    }
    ddb.put_item(TableName=LOG_TBL, Item=item)

lambda/chat_webhook.py

import os, json, time, boto3, base64
from utils.ddb import get_user_profile
from utils.filters import build_retrieval_filter
from utils.log import log_interaction

REGION   = os.environ["AWS_REGION"]
KB_ID    = os.environ["KNOWLEDGE_BASE_ID"]
MODEL    = os.environ["MODEL_ARN"]
GR_ID    = os.environ.get("GUARDRAIL_ID")
GR_VER   = os.environ.get("GUARDRAIL_VERSION","1")
SECRET   = os.environ.get("CHAT_SHARED_SECRET","")

agentrt = boto3.client("bedrock-agent-runtime", region_name=REGION)

def _parse_event(event: dict) -> tuple[str,str]:
    body = event.get("body")
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")
    data = json.loads(body or "{}")
    # MVP shared secret header (switch to Google JWT later)
    headers = { (k or "").lower(): v for k,v in (event.get("headers") or {}).items() }
    if SECRET and headers.get("x-chat-shared-secret") != SECRET:
        raise PermissionError("Bad shared secret")
    # Google Chat (simplified)
    text = (data.get("message") or {}).get("text") or data.get("text") or ""
    user = (data.get("message") or {}).get("sender",{}).get("email") \
           or (data.get("user") or {}).get("email") \
           or "unknown@example.com"
    return user, text.strip()

def handler(event, context):
    t0 = time.time()
    blocked = False
    try:
        user_id, text = _parse_event(event)
        profile = get_user_profile(user_id)
        dept    = profile.get("department")
        region  = profile.get("region", "GLOBAL")
        filt    = build_retrieval_filter(dept, region)

        # Guardrail prompt prefix (belt-and-suspenders)
        # The guardrail service will also enforce configured policies server-side.
        safety_preface = (
          "You are an onboarding assistant. Only answer using retrieved documents "
          "that match the user's department and region. If none match, politely say you don't know. "
          "Never disclose content for other departments or regions."
        )

        req = {
          "input": {"text": f"{safety_preface}\n\nUser: {text}"},
          "retrieveAndGenerateConfiguration": {
            "knowledgeBaseConfiguration": {
              "knowledgeBaseId": KB_ID,
              "modelArn": MODEL,
              "retrievalConfiguration": {
                "vectorSearchConfiguration": {
                  "numberOfResults": 8,
                  "filter": filt
                }
              }
            },
            "type": "KNOWLEDGE_BASE"
          }
        }

        # Attach Guardrail if provided
        if GR_ID:
            req["guardrailConfiguration"] = {
              "guardrailId": GR_ID,
              "guardrailVersion": GR_VER
            }

        resp = agentrt.retrieve_and_generate(**req)

        answer = resp.get("output",{}).get("text","")
        cites  = []
        for it in (resp.get("citations") or []):
            for ref in (it.get("retrievedReferences") or []):
                cites.append({
                  "source": ref.get("location",{}).get("s3Location",{}).get("uri"),
                  "score":  ref.get("score")
                })

        latency_ms = int((time.time() - t0) * 1000)
        log_interaction(user_id, text, answer, cites, latency_ms, blocked)
        # Google Chat expects { "text": "..." }
        return {
          "statusCode": 200,
          "headers": {"content-type":"application/json"},
          "body": json.dumps({ "text": answer })
        }

    except PermissionError as e:
        return {"statusCode": 401, "body": json.dumps({ "text": str(e) })}
    except Exception as e:
        blocked = True
        latency_ms = int((time.time() - t0) * 1000)
        log_interaction("unknown", "EXCEPTION", str(e), [], latency_ms, blocked)
        return {"statusCode": 500, "body": json.dumps({ "text": "Sorry, something went wrong." })}


---

4) Deploy

cd mvp/terraform

# Create terraform.tfvars with your values
cat > terraform.tfvars <<EOF
project            = "onboard-mvp"
aws_region         = "us-east-1"
kb_s3_bucket_name  = "YOUR-KB-BUCKET"
kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/xxxx-xxxx"
bedrock_kb_id      = "kb-xxxxxxxxxxxxxxxx"
guardrail_id       = "gr-xxxxxxxxxxxxxxxx"
guardrail_version  = "1"
chat_shared_secret = "super-long-random-string"
EOF

terraform init
terraform apply -auto-approve

# Get endpoint
API=$(terraform output -raw http_api_invoke_url)
echo "Invoke URL: $API"

Seed two users for ABAC:

aws dynamodb put-item --table-name onboard-mvp-user-profile --item '{
  "user_id":   {"S": "alice@example.com"},
  "department":{"S": "IT"},
  "region":    {"S": "US"}
}'
aws dynamodb put-item --table-name onboard-mvp-user-profile --item '{
  "user_id":   {"S": "bob@example.com"},
  "department":{"S": "HR"},
  "region":    {"S": "EU"}
}'

Upload a sample doc + metadata and run ingestion in the console (or):

aws s3 sync ../docs-examples/ s3://YOUR-KB-BUCKET/docs/
# start an ingestion job (console) or:
# ./scripts/trigger_ingestion.sh <KB_ID> <DATA_SOURCE_ID>


---

5) Smoke Test (without Google Chat yet)

curl -s -X POST "$API/chat" \
  -H "content-type: application/json" \
  -H "x-chat-shared-secret: super-long-random-string" \
  -d '{
    "text": "How do I request VPN access?",
    "user": {"email":"alice@example.com"}
  }' | jq

You should see { "text": "..." } with the correct answer based on IT docs.

Try cross-dept:

curl -s -X POST "$API/chat" \
  -H "content-type: application/json" \
  -H "x-chat-shared-secret: super-long-random-string" \
  -d '{
    "text": "Show me HR leave policy",
    "user": {"email":"alice@example.com"}   # IT user
  }' | jq

Expected: polite refusal or “I don’t have that info” (no HR docs retrieved due to filter).


---

6) Hook Up Google Chat (HTTP integration)

In Google Chat developer console, set your bot’s App URL to:
POST {http_api_invoke_url}/chat

(Keep shared secret header in your proxy or replace with Google signature verify later.)

Start a DM with the bot and ask questions.



---

7) Guardrails — What’s active?

Server-side Bedrock Guardrail (by ID/version)

Blocks unsafe categories; redacts PII; replaces with safe strings.


Prompt preface (in Lambda)

Instructs model to only use dept/region-matched docs; refuse others.


ABAC RetrievalFilter

Prevents cross-department/region content from being retrieved at all.


Fail-closed filter if user attributes are missing.

Logs (blocked flag) for post-hoc audits.



---

8) Tuning & Ops

Prefer Markdown/TXT for source docs (faster/better chunks).

Set Provisioned Concurrency = 1 on Lambda for demos if cold start bothers you.

Add alerts on 5xx and p95 > 2.5s (already in Terraform).

If ingestion finds no metadata, add the .metadata.json file then re-ingest.

When ready, replace the shared secret with Google JWT verification (authorizer or in-Lambda).



---

9) What’s next (Phase-2 preview)

Add Action Mode (Bedrock Agent + Action Group) and tool Lambdas (e.g., submit_access_request).

Enforce RBAC, human approvals, and immutable audit.

Optional MCP bridge via a router Lambda.



---

You’re done.
This repo gives you a secure, fast MVP with Guardrails + ABAC filtering over a single KB.
Paste it in, set the few variables, run terraform apply, upload docs+metadata, ingest, and test with curl/Chat.

Want me to also include a **GitHub Action** that syncs `/docs/` to S3 and triggers ingestion automatically on every push?0

