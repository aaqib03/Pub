# 🔒 Responsible AI & Security Guide
_For the “AI Onboarding & Workplace Assistant” (Bedrock + Knowledge Base + Google Chat)_

**Goal:** Minimize risk, maximize benefit. Ship a chatbot-first MVP safely, then add “agent/action” abilities with hardened controls.

---

## 1) Core Principles
- **Lawful & Fair Use:** Process only what’s necessary for the stated purpose (onboarding/helpdesk). Honor user consent and org policies.
- **Privacy by Design:** Default to least data; mask, minimize, and expire.
- **Security by Default:** Strong auth, encryption, network isolation, immutable audit.
- **Transparency:** Users know what data is used, where answers come from, and how to appeal/correct.
- **Accountability & Governance:** Named owners, reviews, red-teaming, and continuous monitoring.
- **Human-in-the-Loop:** Easy escalation to humans; reversible actions.
- **Reliability:** Robustness against prompt injection, data exfiltration, and tooling misuse.

---

## 2) Threat Model (what can go wrong?)
- **Prompt Injection / Jailbreaks:** Inputs try to bypass policies or exfiltrate secrets.
- **Data Exfiltration:** Model responses leak PII/secrets from KB, logs, or tools.
- **Over-Permissioned Actions:** Bot performs actions beyond user’s role/intent.
- **Identity Spoofing:** Forged Google Chat events or confused identity mapping.
- **Hallucinations:** Confident but wrong guidance causing IT/HR errors.
- **Supply-Chain:** Compromised dependencies, IaC misconfig, leaked secrets.
- **Abuse / Toxic Content:** Harassment, bias, unsafe outputs.
- **Availability:** Flooding requests (DoS), stuck actions, rate-limit gaps.

---

## 3) Controls & Mechanisms

### 3.1 Identity, Access, & Isolation
- **AuthN:** Verify Google Chat webhook signatures; map `googleUserId → employeeId`.
- **AuthZ:** Enforce **RBAC/ABAC** server-side. No action without policy checks.
- **Tenant/Context Isolation:** Strict per-user/session context; never cross-pollinate chats.
- **Secrets Management:** AWS Secrets Manager + IAM least privilege; never embed keys in code.
- **Network:** Private subnets, VPC endpoints for Bedrock/S3/DDB, block egress where possible.

### 3.2 Data Privacy & Minimization
- **Minimize Inputs to LLM:** Send only the minimal fields (role, location tag, not raw PII).
- **Mask & Tokenize:** Email, employee IDs → stable pseudonyms unless strictly needed.
- **Storage Controls:** DynamoDB TTL for ephemeral states; S3 bucket policies, KMS encryption.
- **Retention Policy:** Define per object (messages 30–90d, audit 1–7y per compliance).
- **User Rights:** Discovery/correction/deletion pathways (GDPR/DPDP aligned).

### 3.3 Model Safety (Bedrock)
- **Guardrails:** Use Bedrock Guardrails (content filters, deny lists, sensitive topics).
- **System Prompts:** Explicit safety rules; refuse to reveal secrets/internal configs.
- **Retrieval Safe-listing:** KB sources are curated S3 prefixes only; no wild internet at inference.
- **Citations/Attribution:** Where possible, show source doc title/section so users can verify.
- **Anti-Injection Pattern:** Pre/post-prompt templates with “tools only via server” reminders; strip/neutralize tool-calling text in user input.

### 3.4 Action Safety (for Phase 2 “Agent Mode”)
- **Allow-list Tools:** Only approved actions (`submit_access_request`, `get_status`, etc.).
- **Parameter Validation:** JSON schema validation + regex constraints + length checks.
- **Policy Gate:** Server checks role & approvals (manager/HR) before any mutation.
- **Idempotency:** Keys on all write ops to prevent duplicates.
- **Transaction Logging:** Append-only audit (who/what/when/inputs/outputs/correlationId).
- **Human Approval:** High-risk actions require explicit confirmation or manager sign-off.
- **Kill-Switch:** Feature flags per tool; instant disable path.

### 3.5 Observability & Monitoring
- **Structured Logs:** Correlate Chat thread ↔ Bedrock request ↔ tool action.
- **Metrics:** Refusal rates, override rates, unsafe prompt triggers, PII redactions.
- **Detections:** Alert on abnormal volumes, repeated blocked prompts, high error codes.
- **SIEM Integration:** Stream CloudWatch → Security data lake/SIEM (GuardDuty insights).

### 3.6 Robustness, Quality & Bias
- **Eval Suites:** Safety (toxicity, jailbreaks), grounding (KB citation match), accuracy (gold Q&A).
- **A/B & Canary:** Gradual rollout; observe drift and false advice.
- **Bias Checks:** Role/location fairness in recommendations; review training/KB content.
- **Red-Teaming:** Internal adversarial prompts, tool abuse simulations, data exfil drills.

### 3.7 Transparency & Explainability
- **User Disclosure:** First-run notice: data sources, purpose, logging, escalation path.
- **Answers with Rationale:** Summaries + (where feasible) source references.
- **Action Receipts:** For each action, show: policy check passed, requestId, owner system.
- **Appeals/Corrections:** “Flag this answer” flows; quick KB fixes & re-ingestion.

### 3.8 Governance & Process
- **RACI:** Named owners for model config, KB curation, security, and incident response.
- **Change Control:** Versioned prompts/tools; approval for adding new data sources.
- **Content Hygiene:** KB linter (no secrets, outdated policies). Scheduled reviews.
- **Legal & Compliance:** Map to SOC2/ISO27001; DPIA/PIA; India **DPDP Act 2023** & GDPR readiness.
- **3rd-Party Risk:** Vendor review for any external SaaS; DPA in place.

### 3.9 Supply-Chain & Infra Security
- **IaC Security:** Scan Terraform/CDK; tag and lock down resources; least-privilege IAM.
- **Dependency Scanning:** SCA (e.g., Dependabot/CodeQL) for Lambdas.
- **Build Integrity:** OIDC to AWS, no long-lived creds; signed artifacts; environment pinning.
- **Backup & DR:** Versioned S3, PITR on DynamoDB, restore runbooks.

---

## 4) Phase Scope & Guardrails

### Phase 1 — **Chatbot (Q&A only)**
- **In Scope:** Google Chat DM bot; Bedrock + KB; identity mapping; logging/metrics; guardrails; privacy minimization; transparency UX; basic governance.
- **Out of Scope:** Any external action/mutations (no write APIs).
- **Key Controls:** Strong prompt guardrails, curated KB, no tools, strict PII masking.

### Phase 2 — **Agent Mode (Actions)**
- **Add:** Action Lambdas behind API Gateway; allow-listed tools; policy gate; idempotency; human approval for high risk; real-time and scheduled monitoring; kill-switch.
- **Extra Tests:** Tool misuse simulations, change-impact reviews, red-team exercises.

---

## 5) Checklists

### 5.1 Pre-Prod (Chatbot)
- [ ] Google Chat signature verification implemented
- [ ] KB sources restricted to vetted S3 prefixes
- [ ] Bedrock Guardrails configured (blocked topics/words & PII filter)
- [ ] PII minimization in prompts (no raw emails unless required)
- [ ] TLS everywhere; KMS on S3/Dynamo/Secrets
- [ ] Logs contain no secrets; sampling + retention set
- [ ] User disclosure & privacy notice approved by Legal
- [ ] Eval results meet thresholds (accuracy, grounding, refusal behavior)

### 5.2 Go-Live (Agent Mode)
- [ ] Tool allow-list with JSON schemas
- [ ] RBAC/ABAC checks server-side for every tool
- [ ] Idempotency keys & retries on write ops
- [ ] Immutable audit with correlation IDs
- [ ] Manager approval flow for privileged actions
- [ ] Runbooks: incident response, rollbacks, kill-switch
- [ ] Alarms on error spikes, blocked prompts, anomalous volumes
- [ ] Red-team sign-off + pen test findings remediated

---

## 6) Metrics & SLOs

**Safety & Privacy**
- % prompts blocked by guardrails (target: stable & low)
- PII redactions per 1k requests (monitor spikes)
- Data leakage incidents (target: 0)

**Quality**
- Grounded answer rate (with source match) ≥ X%
- Hallucination rate ≤ Y%
- User CSAT ≥ Z/5

**Operational**
- p95 latency (chat) ≤ 2s; (KB) ≤ 3s
- Tool success rate ≥ 99%
- MTTR for incidents ≤ 30m

---

## 7) User Experience Disclosures (UX Snippets)
- “I use your role and department to personalize answers. I won’t perform changes without your confirmation.”
- “Answers come from your company knowledge base last synced on <date>.”
- “For sensitive requests (access/HR), I’ll ask for confirmation and may seek manager approval.”

---

## 8) Incident Response (High Level)
1. **Detect** via alarms/SIEM → **Triage** (safety vs. availability vs. data breach).
2. **Contain** (disable tool/kill-switch; block KB prefix).
3. **Eradicate** (fix prompt/rules; rotate keys; patch deps).
4. **Recover** (gradual re-enable with extra logging).
5. **Review** (post-mortem; update tests/guardrails/governance).

---

### Appendix: Policy Mappings
- **Encryption:** S3/Dynamo/Bedrock traffic with KMS keys (CMK where needed).
- **Compliance Anchors:** ISO 27001 control families; SOC 2 (Security, Availability, Confidentiality); GDPR & India **DPDP Act 2023** readiness.
- **Records:** Keep DPIA, data flow diagrams, RACI, KB content owners, and evaluation logs current.