# CloudGuard AI — Architecture Improvement Plan
## Principal Architect Review | Based on Full Codebase Audit (CG-107)
### Version 1.0

---

## 1. Architectural Assessment — Where You Are Today

Before prescribing improvements, it is important to be precise about what you have built and what it actually is.

CloudGuard AI today is a **well-structured single-agent streaming platform with a multi-agent facade**. The tile-click routing, single-adapter-per-turn constraint, and absence of cross-agent synthesis mean that despite having multiple specialized agents, users are effectively talking to one agent at a time with no orchestration intelligence between them. The platform *looks* multi-agent from the outside but does not yet *reason* like one.

This is not a criticism — it is a precise diagnosis. The foundation is genuinely good: streaming is implemented correctly, the tool result compaction pattern is clean, session isolation is sound, and the observability substrate is in place. The gaps are at the **intelligence layer**, not the plumbing layer. That is the better problem to have.

The target state this plan aims for is a **context-aware, memory-augmented, self-validating multi-agent reasoning system** that feels like Claude — not because it mimics Claude's surface behaviour, but because it applies the same underlying principles: rich context, honest uncertainty, multi-step reasoning, and consistent persona.

---

## 2. Architecture Layers — Diagnosis by Layer

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 6: EVALUATION & LEARNING                                  │
│  Status: ❌ Not built — observability substrate only             │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 5: OUTPUT QUALITY & POST-PROCESSING                       │
│  Status: ⚠️  Minimal — sanitize + action-gate only              │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 4: AGENT REASONING LOOPS                                  │
│  Status: ✅ Security/FinOps good | ❌ DevOps deterministic       │
│          ❌ Compliance mock | ❌ No cross-agent reasoning         │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 3: CONTEXT & MEMORY                                       │
│  Status: ⚠️  Short-term raw/unbounded | ❌ No long-term memory   │
│          ⚠️  Keyword retrieval | ❌ No global context            │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2: ORCHESTRATION & ROUTING                                │
│  Status: ❌ Tile-click only | ❌ No fan-out | ❌ No decomposition │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1: INFRASTRUCTURE & RELIABILITY                           │
│  Status: ✅ Streaming ✅ Session isolation ✅ Error handling      │
│          ⚠️  No retry/backoff | ❌ No circuit breaker            │
└─────────────────────────────────────────────────────────────────┘
```

The bottom layer (infrastructure) is solid. Every layer above it has meaningful gaps. The plan below addresses each layer from most impactful to least.

---

## 3. Improvement Plan — Phased by Impact

### PHASE 1: Intelligence Foundation (Weeks 1–3)
*Fix the things that are directly causing "feels generic" responses today*

---

### 1.1 — Critic / Self-Check Gate
**Gap addressed:** G6 — No post-answer validation  
**Impact:** Highest single ROI improvement. Catches irrelevant, incomplete, or unsupported responses before they reach the user.  
**File:** `orchestration/src/aggregator/aggregator.py`

**How it works:**
After the agent produces its response, before `build_envelope()` returns to the user, make one additional lightweight Bedrock call — a "critic" that scores the response against the original question and the context that was injected.

**Critic prompt template:**
```
You are a response quality auditor for an AWS operations platform.

Original user question: {user_query}

Context provided to the agent: {injected_context_summary}

Agent response: {agent_response}

Evaluate on three dimensions only. Respond in JSON:
{
  "answers_the_question": true/false,
  "grounded_in_context": true/false,  
  "contains_unsupported_claims": true/false,
  "verdict": "pass" | "retry" | "flag",
  "reason": "one sentence"
}

Rules:
- "pass" if answers_the_question=true AND grounded_in_context=true
- "retry" if the question is not answered but context exists to answer it
- "flag" if claims are made that contradict or exceed the provided context
```

**Orchestrator behaviour based on verdict:**
- `pass` → return response as-is
- `retry` → re-invoke agent with enriched context (max 1 retry)
- `flag` → append a `[!] Note: This response could not be fully verified against available data` disclaimer to the response, log the flag

**Important constraint:** Use `claude-haiku` or `amazon.nova-lite` for the critic call — keep it fast and cheap. The critic should add <500ms, not another 5 seconds.

---

### 1.2 — Conversation History Summarization + Length Guard
**Gap addressed:** G4 — Raw unbounded history passed every turn  
**Impact:** Prevents context dilution on long sessions, reduces token cost, improves focus of agent responses  
**File:** `orchestration/src/session_store.py`, `orchestration/src/models.py`

**How it works:**
Introduce a rolling summarization policy. When the transcript exceeds a threshold (e.g. 12 turns), summarize the oldest N turns into a compact summary block and store it alongside the raw recent turns.

**Implementation pattern:**
```python
# In session_store.py — new method
def get_context_window(self, state: ConversationState) -> dict:
    RECENT_TURNS = 6        # always pass last 6 turns verbatim
    SUMMARY_THRESHOLD = 12  # summarize when transcript exceeds this
    
    transcript = state.transcript
    
    if len(transcript) <= RECENT_TURNS:
        return {"summary": None, "recent": transcript}
    
    if len(transcript) > SUMMARY_THRESHOLD:
        older = transcript[:-RECENT_TURNS]
        # summarize older turns if not already summarized
        if not state.history_summary:
            state.history_summary = _summarize_turns(older)
        return {
            "summary": state.history_summary,
            "recent": transcript[-RECENT_TURNS:]
        }
    
    return {"summary": None, "recent": transcript[-RECENT_TURNS:]}
```

**Summarization prompt (called once, cached in ConversationState):**
```
Summarize the following conversation turns into a compact factual record 
for an AWS operations assistant. Preserve: teams mentioned, issues discussed, 
resolutions reached, user preferences stated, open questions. 
Discard: pleasantries, repeated confirmations, verbose tool output descriptions.
Maximum 150 words.

Turns: {older_turns}
```

**What to add to `ConversationState` in `models.py`:**
```python
history_summary: Optional[str] = None   # rolling summary of older turns
active_team: Optional[str] = None       # persisted team, not re-derived each turn
active_team_context: Optional[str] = None  # cached team brief for this session
```

---

### 1.3 — Active Team Persistence in Session State
**Gap addressed:** G15 — Team re-derived from transcript scan every turn  
**Impact:** Eliminates repeated team detection overhead, ensures consistent team grounding throughout a session  
**File:** `orchestration/src/models.py`, `orchestration/src/context/injector.py`, `agents/security/adapter/team_knowledge.py`

**How it works:**
When `detect_teams()` successfully identifies a team, write it to `ConversationState.active_team`. On subsequent turns, `injector.fetch()` reads `state.active_team` first — only calling `detect_teams()` if it is null or if the user explicitly mentions a different team name.

```python
# In injector.fetch()
if state.active_team and team not explicitly changed in text:
    team_context = state.active_team_context  # cached, no re-read
else:
    detected = detect_teams(text)
    if detected:
        state.active_team = detected[0]
        state.active_team_context = team_brief(text, agent)
        session_store.save_state(state)
```

This also enables the critic to see which team context was actually used, making its grounding check accurate.

---

### 1.4 — Wire LLM Routing (BedrockBrain) — Suggest-Then-Confirm Pattern
**Gap addressed:** G1 — Tile-click only routing, BedrockBrain commented out  
**Impact:** Enables the platform to handle natural language queries without requiring users to click a tile first  
**File:** `orchestration/src/orchestrator.py _decide()`, `orchestration/src/brain/__init__.py`

**Critical design decision:** Do NOT wire BedrockBrain as hard-routing. The reason it was deferred was likely latency and correctness concerns — both valid. The right pattern is **suggest-then-confirm**:

```python
# New _decide() logic
def _decide(self, request, state):
    # 1. Explicit tile click — always authoritative
    if request.panel is not None:
        return request.panel, True, ""
    
    # 2. Active agent — sticks unless user signals switch
    if state.active_agent is not None:
        switch_signal = self._detect_switch_intent(request.text, state)
        if not switch_signal:
            return state.active_agent, False, ""
    
    # 3. Cold start or switch detected — use BedrockBrain
    suggestion = self.brain.select(request.text)  # NOW WIRED IN
    
    if suggestion.confidence >= 0.85:
        # High confidence — route directly, tell user which agent
        return suggestion.agent, True, f"_routing_to:{suggestion.agent}"
    else:
        # Low confidence — ask user to confirm
        return None, False, ASK_TO_PICK  # with suggestion hint in response
```

**Switch intent detection — lightweight heuristic (NOT an LLM call):**
```python
SWITCH_SIGNALS = [
    "actually", "instead", "switch to", "ask about cost",
    "security question", "what about the", "different question"
]
def _detect_switch_intent(self, text, state) -> bool:
    return any(s in text.lower() for s in SWITCH_SIGNALS)
```

This keeps latency near-zero for the common case (active agent sticks) and only invokes Bedrock for cold starts or explicit switches.

---

### PHASE 2: Memory & Knowledge Architecture (Weeks 3–5)
*Build the institutional memory that makes the platform feel like it knows your teams*

---

### 2.1 — Long-Term Cross-Session Memory
**Gap addressed:** G5 — Every session starts completely fresh  
**Impact:** The single biggest shift from "chatbot" to "platform that knows us." After this, returning users feel like they are continuing a relationship, not starting over.  
**New file:** `orchestration/src/long_term_store.py`

**Architecture:**

```
DynamoDB Table: cloudguard-long-term-memory
PK: team#{team_slug}
SK: memory#{type}#{timestamp}

Record types:
- incident_resolution: {incident_type, root_cause, resolution, date, agent}
- team_preference: {preference_key, value, set_by, date}  
- recurring_issue: {issue_pattern, frequency, last_seen, typical_resolution}
- open_question: {question, asked_by, date, status}
```

**When to write:**
After every session close (or after an agent produces a `high` confidence resolution), extract memory-worthy facts with a lightweight extraction prompt:

```
From this conversation, extract any facts worth remembering for this team's 
future sessions. Include: issues resolved + how, preferences stated, 
recurring patterns, open items. Return JSON array of memory records.
If nothing memory-worthy occurred, return [].

Conversation summary: {session_summary}
Team: {team_slug}
```

**When to read:**
At session start, inject a `[Team Memory]` block into the first turn's context:

```
[Team Memory — {team_slug}]
Recent resolved issues: {last_3_resolutions}
Known recurring patterns: {top_2_patterns}  
Stated preferences: {preferences}
Open items from last session: {open_items}
```

This block goes into the same per-turn user content block as the team brief — not the system prompt.

---

### 2.2 — Global Context Layer
**Gap addressed:** G8 — No company-wide context available to all agents  
**Impact:** Agents can reference org-wide policies, shared infrastructure, global compliance requirements without being explicitly told  
**New file:** `orchestration/src/context/global_context.py`

**What goes in global context:**
```markdown
# CloudGuard Global Context

## Organization
Fintech company. Primary cloud: AWS. On-premises systems also in scope.
Regulatory frameworks: PCI-DSS, FFIEC, internal InfoSec policy v3.2

## Shared Infrastructure
- Primary VPC: vpc-xxxxxxxx (us-east-1)
- Shared services: Secrets Manager, CloudTrail (all-regions), GuardDuty (org-level)
- Tagging convention: team={slug}, env={prod|staging|dev}, cost-centre={code}
- Jira workspace: CSY project, sprint cadence: 2 weeks

## Global Compliance Baselines
- All S3 buckets must have encryption enabled (SSE-KMS)
- No public S3 buckets permitted
- IAM: least-privilege, no root key usage
- CloudTrail: must be enabled in all regions
- MFA: required for all console access

## Team Registry
{dynamically injected from jira_routing.known_teams()}
```

**Injection point:** `injector.fetch()` prepends global context before the team-specific brief. Keep it under 300 tokens — it is always present so must be compact.

---

### 2.3 — Semantic Retrieval via Bedrock Knowledge Bases
**Gap addressed:** G7 — Keyword scoring only, no semantic retrieval  
**Impact:** Queries that don't use exact team names or section headers will find relevant context. Cross-team implicit references will work. SOP retrieval will be far more accurate.  
**File:** `orchestration/src/knowledge.py` (swap the retrieval backend)

**Migration path (preserve the `TeamContext` interface):**

The codebase already documented the swap-seam: `KnowledgeBase.retrieve()` → `RetrieveAndGenerate`. The interface stays the same — only the implementation changes.

```python
# knowledge.py — new backend, same interface
class BedrockKnowledgeBase(KnowledgeBase):
    def __init__(self, kb_id: str, bedrock_client):
        self.kb_id = kb_id
        self.client = bedrock_client
    
    def retrieve(self, query: str, top_k: int = 5) -> list[KBResult]:
        response = self.client.retrieve(
            knowledgeBaseId=self.kb_id,
            retrievalQuery={"text": query},
            retrievalConfiguration={
                "vectorSearchConfiguration": {"numberOfResults": top_k}
            }
        )
        return [
            KBResult(
                content=r["content"]["text"],
                score=r["score"],
                source=r["location"]["s3Location"]["uri"]
            )
            for r in response["retrievalResults"]
        ]
```

**What to ingest into the Bedrock Knowledge Base:**
- `playbooks/teams/*.md` — all team profiles
- `playbooks/*.md` — all procedure documents
- `orchestration/knowledge/*.md` — per-agent KB files
- Incident resolution records (from long-term memory, exported periodically)

**Bedrock KB setup:** S3 bucket as data source, auto-sync enabled, chunking strategy: by `##` header (semantic chunking aligned to your existing document structure).

---

### 2.4 — Team Dependency Graph
**Gap addressed:** G22 — No cross-team relationship modelling  
**Impact:** When a File Transfer failure is caused by a Networking VPC change, the agent can reason about it. When a Jenkins deployment breaks a Lambda, the agent knows the connection.  
**New file:** `playbooks/team_dependencies.json`, read by `team_knowledge.py`

**Structure (simple, not a graph database — JSON is sufficient at this scale):**
```json
{
  "file-transfer": {
    "depends_on": ["networking", "jenkins"],
    "dependency_detail": {
      "networking": "VPC routing + NAT Gateway for outbound SFTP",
      "jenkins": "CI/CD pipeline deploys Lambda versions"
    },
    "downstream_of": [],
    "shared_resources": ["vpc-xxxxxxxx", "secrets/sftp-keys"]
  },
  "networking": {
    "depends_on": [],
    "downstream_of": ["file-transfer", "payments"],
    "shared_resources": ["vpc-xxxxxxxx", "tgw-xxxxxxxx"]
  }
}
```

**Usage in agent context injection:**
When `active_team` is set and a cross-team reference is detected in the query, inject a `[Team Dependencies]` block:

```
[Team Dependencies — file-transfer]
Depends on: Networking (VPC routing + NAT Gateway), Jenkins (Lambda deployments)
Shared resources: vpc-xxxxxxxx, secrets/sftp-keys
Issues in these upstream teams may cause File Transfer failures.
```

---

### PHASE 3: Agent Intelligence Upgrades (Weeks 5–7)
*Upgrade individual agents to full LLM reasoning loops and add the missing Compliance agent*

---

### 3.1 — DevOps Agent: Deterministic → LLM Reasoning Loop
**Gap addressed:** G10 — DevOps agent is deterministic Python, no RCA reasoning depth  
**Impact:** Transforms troubleshooting from "here are your firing alarms" to "here is why this happened, what it means for your architecture, and what to do"  
**File:** `orchestration/src/agents/devops_agent.py`

**Current state:** `_reason()` is deterministic Python. It reads CloudWatch alarms, adds team grounding, formats output. No LLM in the reasoning path.

**Target state:** Same loop pattern as Security agent (`loop.py _run_bedrock_loop`), with DevOps-specific tools and system prompt.

**DevOps agent system prompt (key sections):**
```
You are the CloudGuard DevOps agent, specialising in incident investigation 
and root cause analysis for AWS infrastructure.

CORE RULES:
- Always start by reading the current CloudWatch alarms for the relevant team
- Cross-reference alarm details with the team's architecture before concluding
- Check the runbook for this alarm type if one exists (use read_playbook tool)
- If a past incident matches this pattern, say so explicitly
- Never guess at root cause — only state what the data supports
- If you cannot determine root cause from available data, say exactly what 
  additional information would help

RCA FORMAT:
1. What is firing (alarm name, threshold, current value)
2. What it means in context of this team's architecture  
3. Most likely root cause (with confidence: high/medium/low)
4. Immediate action recommended
5. Runbook reference if applicable
6. Whether this matches a known pattern (from team memory)
```

**DevOps-specific tools to add:**
```python
# Add to devops tools
describe_alarms(team)           # existing — keep
get_cloudwatch_logs(log_group, start_time, filter_pattern)  # NEW
get_cloudtrail_events(resource_arn, hours=2)                # NEW  
get_lambda_invocations(function_name, hours=1)              # NEW
read_playbook(name)             # existing — add to DevOps
search_incident_memory(pattern) # NEW — queries long-term memory
```

---

### 3.2 — Compliance Agent: Mock → Real Implementation
**Gap addressed:** G11 — Compliance agent is a mock  
**New file:** `agents/compliance/adapter/compliance_adapter.py`

**What this agent does:**
Reads AWS Config rules evaluation results and AWS Security Hub findings, maps them to compliance framework controls (PCI-DSS, FFIEC), and generates audit-ready evidence records.

**Compliance agent system prompt (key sections):**
```
You are the CloudGuard Compliance agent. You help engineering teams understand 
their compliance posture against PCI-DSS and FFIEC requirements, and generate 
audit-ready evidence records.

CORE RULES:
- Always attribute findings to specific control IDs (e.g. PCI Requirement 3.4)
- Distinguish between active violations and historical evidence of compliance
- When a violation is found, always report: what drifted, when detected, 
  current status (open/resolved), and time-to-resolve if resolved
- Generate evidence records in structured format suitable for audit packages
- Never make compliance assertions you cannot back with tool data

COMPLIANCE POSTURE FORMAT:
Framework: {PCI-DSS | FFIEC}
Assessment date: {today}
Controls assessed: N
Controls passing: N  
Controls failing: N (list each with severity)
Evidence records: [attached]
```

**Compliance agent tools:**
```python
get_config_compliance(rule_name, team)      # AWS Config rule evaluations
get_security_hub_findings(framework, team)  # Security Hub mapped to framework
get_config_drift_history(resource_arn, days)  # Config change history
generate_evidence_record(finding_id, rca_summary)  # combines finding + RCA
export_audit_package(team, framework, date_range)  # PDF-ready export
```

---

### 3.3 — Security Agent: Add False Positive Detection
**Gap addressed:** G12 — Findings listed but not filtered by team architecture context  
**File:** `agents/security/adapter/tools.py`, `agents/security/adapter/system_prompt.py`

**How it works:**
Inject the team's architecture context into a new tool `assess_false_positive(finding_id, team_architecture_context)` that asks the model to reason about whether a finding is a genuine risk given the team's known design.

**Add to system prompt:**
```
FALSE POSITIVE ASSESSMENT:
When presenting findings, always consider the team's architecture context 
provided in your background. If a finding contradicts an intentional design 
decision (e.g. a security group rule that is intentionally permissive for 
a client-facing SFTP endpoint), flag it as a POTENTIAL FALSE POSITIVE and 
explain why, citing the architecture context. Never suppress findings — 
always show them, but annotate appropriately.

Format: 
🔴 CONFIRMED: {finding} — {why it is genuine}
🟡 REVIEW: {finding} — POTENTIAL FALSE POSITIVE: {reason based on architecture}
```

---

### 3.4 — Multi-Agent Fan-Out for Complex Queries
**Gap addressed:** G2, G3 — No parallel routing, no cross-agent aggregation  
**File:** `orchestration/src/orchestrator.py`, `orchestration/src/aggregator/aggregator.py`

**Architecture:**

This is the most architecturally significant change. Introduce a query decomposer that runs before agent selection on complex queries.

```
User query: "Why did our Lambda cost spike and is it a security risk?"
                            ↓
              Query Decomposer (lightweight LLM call)
                            ↓
        {
          "primary": "finops",    (cost spike)
          "secondary": ["security"],  (security risk)
          "decomposed": [
            {"agent": "finops", "sub_query": "Why did Lambda cost spike?"},
            {"agent": "security", "sub_query": "Are there security findings on this Lambda?"}
          ]
        }
                            ↓
          ┌─────────────────┴──────────────────┐
          ▼                                    ▼
    FinOps Agent                      Security Agent
    (parallel invocation)             (parallel invocation)
          │                                    │
          └──────────────┬─────────────────────┘
                         ▼
              Synthesis Aggregator
              (single LLM call combining both results)
                         ↓
              Single coherent response to user
```

**Query decomposer prompt:**
```
You are a query router for a multi-agent AWS operations platform.
Available agents: security (Wiz findings, CVEs), finops (costs, optimization), 
devops (incidents, RCA, CloudWatch), compliance (PCI/FFIEC posture).

Analyse this query and determine if it requires one or multiple agents.
Return JSON only:
{
  "requires_fanout": true/false,
  "primary_agent": "agent_name",
  "secondary_agents": [],
  "decomposed_queries": [
    {"agent": "name", "sub_query": "focused version of query for this agent"}
  ]
}

Query: {user_query}
Context: {active_team}, {recent_topic_from_history}
```

**Synthesis aggregator prompt (only called on fan-out):**
```
You are synthesising responses from multiple specialist agents into one 
coherent answer for an AWS operations engineer.

Primary response (from {primary_agent}): {primary_response}
Secondary response (from {secondary_agent}): {secondary_response}

Synthesise into a single response that:
- Leads with the most critical finding
- Clearly attributes information to its source agent
- Identifies any cross-domain connections (e.g. cost spike caused by security misconfiguration)
- Does not repeat information
- Ends with a unified action recommendation
```

**Phasing recommendation:** Ship single-agent with BedrockBrain routing first (Phase 1). Add fan-out as a separate, clearly-flagged feature in Phase 3. Fan-out adds latency and complexity — do not introduce it before the single-agent path is solid.

---

### PHASE 4: Reliability & Observability Hardening (Weeks 7–8)
*Make the system production-grade and measurable*

---

### 4.1 — Bedrock Retry with Exponential Backoff
**Gap addressed:** G13 — One failure = full degrade, no retry  
**File:** `agents/security/adapter/loop.py` (and equivalent in finops)

```python
import time
import random

def _bedrock_call_with_retry(client, **kwargs):
    MAX_RETRIES = 3
    BASE_DELAY = 0.5  # seconds
    
    for attempt in range(MAX_RETRIES):
        try:
            return client.converse(**kwargs)
        except client.exceptions.ThrottlingException as e:
            if attempt == MAX_RETRIES - 1:
                raise
            delay = BASE_DELAY * (2 ** attempt) + random.uniform(0, 0.3)
            time.sleep(delay)
        except client.exceptions.ServiceUnavailableException as e:
            if attempt == MAX_RETRIES - 1:
                raise
            time.sleep(BASE_DELAY * (2 ** attempt))
```

---

### 4.2 — Circuit Breaker for AWS API Calls
**Gap addressed:** G18 — No circuit breaker, each call fully independent  
**New file:** `orchestration/src/reliability/circuit_breaker.py`

```python
class CircuitBreaker:
    def __init__(self, name: str, failure_threshold: int = 3, 
                 recovery_timeout: int = 30):
        self.name = name
        self.failures = 0
        self.threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.last_failure_time = None
        self.state = "closed"  # closed=normal, open=failing, half-open=testing
    
    def call(self, func, *args, fallback=None, **kwargs):
        if self.state == "open":
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = "half-open"
            else:
                return fallback() if fallback else {"error": f"{self.name} unavailable"}
        try:
            result = func(*args, **kwargs)
            if self.state == "half-open":
                self.state = "closed"
                self.failures = 0
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure_time = time.time()
            if self.failures >= self.threshold:
                self.state = "open"
            raise
```

Apply to: `query_cost_explorer`, `describe_alarms`, `get_config_compliance`, Jira API calls.

---

### 4.3 — LLM-Judge Evaluation Layer
**Gap addressed:** G14 — Response quality not measured  
**New file:** `orchestration/src/evaluation/judge.py`

**How it works:**
After every turn, asynchronously (non-blocking, does not affect response latency) invoke a lightweight judge model to score the response. Store scores in the observability log.

```python
# Called async after response is returned to user
async def judge_response(query, context_summary, response, agent, team):
    prompt = f"""
    Rate this agent response on a scale of 1-5 for each dimension.
    Return JSON only.
    
    Query: {query}
    Agent: {agent} | Team: {team}
    Context available: {context_summary}
    Response: {response[:500]}  # truncate for cost
    
    {{
      "relevance": 1-5,      // Does it answer the actual question?
      "groundedness": 1-5,   // Is it supported by context/tools?
      "completeness": 1-5,   // Does it address all parts of the query?
      "clarity": 1-5,        // Is it clear and well-structured?
      "overall": 1-5,
      "flags": []            // ["hallucination_risk", "off_topic", "incomplete"]
    }}
    """
    # Use nova-lite for speed and cost
    score = invoke_bedrock_lite(prompt)
    observability.record_quality_score(turn_id, score)
```

**Dashboard metric:** Rolling 7-day average quality score per agent. Alerts if any agent drops below 3.5/5.

---

### 4.4 — PII Detection Gate
**Gap addressed:** G21 — Only prompt-injection prefilter, no PII detection  
**File:** `orchestration/src/guardrails/gate.py`

```python
import re

PII_PATTERNS = {
    "aws_key": r"AKIA[0-9A-Z]{16}",
    "aws_secret": r"[0-9a-zA-Z/+]{40}",
    "credit_card": r"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b",
    "ssn": r"\b\d{3}-\d{2}-\d{4}\b",
    "private_key": r"-----BEGIN (RSA |EC )?PRIVATE KEY-----",
}

def check_for_pii(text: str) -> dict:
    detected = []
    for pii_type, pattern in PII_PATTERNS.items():
        if re.search(pattern, text):
            detected.append(pii_type)
    return {"detected": detected, "safe": len(detected) == 0}
```

**Behaviour:** If PII detected → strip the sensitive value from the query, log the detection, continue with sanitized query. Do NOT reject the query — just scrub it.

---

### 4.5 — Hardcode Elimination
**Gap addressed:** G63 — Secret ARN and model ID hardcoded  
**Files:** `jira_tool.py`, `jira_routing.py`, and all files referencing `amazon.nova-pro-v1:0`

```python
# config.py — single source of truth
import os

BEDROCK_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "amazon.nova-pro-v1:0")
BEDROCK_CRITIC_MODEL_ID = os.environ.get("BEDROCK_CRITIC_MODEL_ID", "amazon.nova-lite-v1:0")
JIRA_SECRET_ARN = os.environ.get("JIRA_SECRET_ARN")  # NO fallback — must be set
JIRA_DEFAULT_PROJECT = os.environ.get("JIRA_DEFAULT_PROJECT", "CSY")
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
```

---

### PHASE 5: Knowledge Evolution (Weeks 8–10)
*Make the knowledge base self-maintaining and the platform continuously improving*

---

### 5.1 — Automatic Team Profile Enrichment
**Gap addressed:** G17 — Team markdown files manually maintained  
**New file:** `orchestration/src/knowledge/profile_enricher.py`

**How it works:**
After 20 sessions for a team, run a weekly enrichment job that:
1. Reads the last 20 session summaries for that team from long-term memory
2. Extracts patterns not captured in the current team profile
3. Proposes additions to the team's markdown file as a Jira ticket for human review

This is semi-automated — it suggests, humans approve. Keeps team profiles alive without making them fully autonomous.

---

### 5.2 — Context Regression Test Harness
**Gap addressed:** G23 — No context-specific regression test on KB updates  
**New file:** `tests/knowledge_regression.py`

**How it works:**
Each team has a golden query set — 5–10 questions with expected answer characteristics (not exact text). When a team's markdown file or playbook is updated, the CI pipeline runs the golden query set and the LLM-judge scores the outputs. If average score drops more than 0.5 points, the update is flagged for human review before merge.

```python
GOLDEN_QUERIES = {
    "file-transfer": [
        {"query": "What is the file transfer team's SFTP architecture?",
         "must_contain": ["SFTP", "Lambda", "S3"],
         "must_not_contain": ["I don't know", "unclear"]},
        {"query": "What are the common failure modes for file transfer?",
         "must_contain": ["naming convention", "Lambda", "bucket"]},
    ]
}
```

---

## 4. Revised Target Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                    CLOUDGUARD AI — TARGET ARCHITECTURE               │
├──────────────────────────────────────────────────────────────────────┤
│  FRONTEND                                                            │
│  CloudFront → React (split-panel: chat + live dashboard)             │
│  WebSocket / SSE streaming                                           │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│  GUARDRAILS LAYER (gate.py)                                          │
│  PII detection → prompt-injection filter → action-gate               │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│  ORCHESTRATION LAYER (orchestrator.py)                               │
│                                                                      │
│  ┌─────────────────┐    ┌──────────────────┐   ┌────────────────┐   │
│  │ BedrockBrain    │    │ Query Decomposer  │   │ Confidence     │   │
│  │ (LLM routing,  │    │ (fan-out decider) │   │ Gate + Retry   │   │
│  │ suggest-confirm)│    │                  │   │                │   │
│  └─────────────────┘    └──────────────────┘   └────────────────┘   │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│  CONTEXT & MEMORY LAYER (injector.py + session_store.py)             │
│                                                                      │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────┐ ┌─────────────┐  │
│  │ Global       │ │ Team Brief   │ │ Team       │ │ Long-Term   │  │
│  │ Context      │ │ (semantic    │ │ Dependency │ │ Memory      │  │
│  │ (always-on)  │ │ retrieval)   │ │ Graph      │ │ (DynamoDB)  │  │
│  └──────────────┘ └──────────────┘ └────────────┘ └─────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Session State (DynamoDB)                                     │   │
│  │ conversationId | active_team | history_summary | transcript  │   │
│  └──────────────────────────────────────────────────────────────┘   │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│  AGENT REASONING LAYER                                               │
│                                                                      │
│  ┌─────────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │  Security   │ │  FinOps  │ │  DevOps  │ │   Compliance      │   │
│  │  Agent      │ │  Agent   │ │  Agent   │ │   Agent           │   │
│  │  (Astra)    │ │          │ │  (NEW:   │ │   (NEW: Config    │   │
│  │             │ │          │ │  LLM     │ │   + SecHub        │   │
│  │ + FP detect │ │          │ │  loop)   │ │   + evidence gen) │   │
│  └──────┬──────┘ └────┬─────┘ └────┬─────┘ └─────────┬─────────┘   │
│         └─────────────┴────────────┴─────────────────┘             │
│                              │ Bedrock Converse API                 │
│                    (retry + circuit breaker on each call)           │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│  OUTPUT QUALITY LAYER (aggregator.py)                                │
│                                                                      │
│  ┌────────────────┐  ┌──────────────────┐  ┌──────────────────┐    │
│  │  Critic Gate   │  │ Synthesis Prompt  │  │ Format + Cite    │    │
│  │  (self-check   │  │ (fan-out merge)   │  │ (audience-aware  │    │
│  │  before return)│  │                   │  │  + source tags)  │    │
│  └────────────────┘  └──────────────────┘  └──────────────────┘    │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│  EVALUATION LAYER (async, non-blocking)                              │
│                                                                      │
│  LLM-Judge scoring → observability.jsonl → quality dashboard        │
│  Golden-query regression tests → CI pipeline                        │
│  Profile enrichment job → weekly Jira proposals                     │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 5. Build Sequence — Recommended Sprint Plan

| Sprint | Duration | Deliverables | Who |
|---|---|---|---|
| Sprint 1 | Week 1 | Critic gate (1.1) + history summarization (1.2) + active team persistence (1.3) | 1–2 engineers |
| Sprint 2 | Week 2 | BedrockBrain wired as suggest-confirm (1.4) + PII detection (4.4) + Bedrock retry (4.1) | 1 engineer |
| Sprint 3 | Weeks 3–4 | Long-term memory DynamoDB store + session enrichment (2.1) | 1–2 engineers |
| Sprint 4 | Week 4 | Global context layer (2.2) + team dependency graph (2.4) | 1 engineer |
| Sprint 5 | Week 5 | Bedrock Knowledge Base migration for semantic retrieval (2.3) | 1–2 engineers |
| Sprint 6 | Weeks 5–6 | DevOps agent → LLM Converse loop (3.1) + new DevOps tools | 1–2 engineers |
| Sprint 7 | Weeks 6–7 | Compliance agent — real implementation (3.2) | 1–2 engineers |
| Sprint 8 | Week 7 | Security agent false-positive detection (3.3) + circuit breaker (4.2) | 1 engineer |
| Sprint 9 | Week 8 | LLM-judge evaluation layer (4.3) + quality dashboard | 1 engineer |
| Sprint 10 | Weeks 8–10 | Multi-agent fan-out (3.4) — only after single-agent path is solid | 2 engineers |
| Sprint 11 | Week 9–10 | Profile enricher (5.1) + context regression harness (5.2) | 1 engineer |
| Sprint 12 | Week 10 | Hardcode elimination (4.5) + config.py consolidation | 0.5 engineer |

---

## 6. What NOT to Build (Yet)

These are real ideas that would hurt you if built now, before the above is stable:

**Fine-tuned model:** You do not have enough labelled high-quality conversations yet. Wait until the LLM-judge has scored 500+ turns and you have identified systematic failure patterns.

**Graph database for team dependencies:** The JSON dependency file (2.4) is sufficient for 10–20 teams. A graph DB adds operational overhead with no benefit at this scale.

**Real-time architecture doc sync:** Auto-ingesting Terraform state or Confluence pages into the KB is tempting but complex. Start with the manual S3 upload pipeline — teams will tell you what's missing.

**Custom embedding model:** Bedrock Knowledge Bases with Titan embeddings is accurate enough and operationally zero-overhead. Custom embeddings are a year-two problem.

---

## 7. Principles for Every Change Made

These govern every implementation decision throughout this improvement plan:

1. **Tool data is authoritative, model inference is not.** Never let the model make numerical claims without tool backing. The existing "numbers come from tools" rule is correct — never break it.

2. **Every new Bedrock call must have a clear cost and latency budget.** The critic call must be < 500ms and < $0.001 per turn. The judge must be async. Fan-out must be opt-in.

3. **Preserve the static system prompt pattern.** The decision to keep system prompts byte-stable for prompt cache efficiency is correct. All dynamic context goes into per-turn user blocks, never the system prompt.

4. **Graceful degrade over hard failure, always.** Every new component must have a defined fallback — if the critic fails, return the response without the check. If long-term memory is unavailable, start fresh. Never let an improvement make the system less available than it was before.

5. **Ship each phase independently and measure before continuing.** Do not start Phase 3 until Phase 1 improvements show measurable quality score improvement in the LLM-judge. Each phase should produce a measurable delta in response quality, not just more features.

6. **The interface contracts stay stable.** `TeamContext`, `AgentResult`, `ConversationState` — these are the seams that let four engineers work in parallel without stepping on each other. Extend them, never redefine them.

---

*Prepared by: AI Systems Principal Architect Review*  
*Based on: CloudGuard AI Codebase Audit — Branch CG-107*  
*Status: Ready for engineering review and sprint planning*
