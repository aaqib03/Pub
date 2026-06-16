# CloudGuard AI — Unified Command Centre for AWS Frontier Agents
### Product Requirements Document (PRD) — v2.0

---

| Field | Detail |
|---|---|
| Document Type | Product Requirements Document (PRD) |
| Project Name | CloudGuard AI — Multi-Agent Intelligence Platform |
| Organization | Fintech — Cloud & Infrastructure Division |
| Team Size | 4 DevOps Engineers |
| Timeline | 15 Days |
| Cloud Provider | AWS (Primary) + On-Premises Infrastructure |
| LLM Platform | Amazon Bedrock (Claude Opus 4.6) + AgentCore |
| Version | 2.0 — Updated with AWS Frontier Agent Integration Strategy |
| Status | Draft — In Progress |

---

## 1. Executive Summary

CloudGuard AI is a unified command centre that orchestrates AWS's own frontier AI agents — AWS DevOps Agent, AWS Security Agent, and AWS FinOps Agent — alongside a custom RAG-powered context layer, all surfaced through a single intelligent platform built for fintech engineering teams.

The core insight driving this architecture: AWS has already built world-class frontier agents for troubleshooting (DevOps Agent), security (Security Agent), and cost (FinOps Agent). These agents are now generally available or in public preview, and AWS DevOps Agent exposes a full programmatic API, webhooks, MCP integration, and Agent Client Protocol (ACP). Rather than rebuilding what AWS has already solved, CloudGuard AI orchestrates these agents from a unified custom UI — adding the one thing AWS agents fundamentally cannot provide: **team-specific context**.

No AWS frontier agent knows your team's architectures, your historical incident SOPs, your Viz scan pipeline, or your specific operational runbooks. CloudGuard AI wraps AWS frontier agents with that institutional knowledge via a Bedrock-powered RAG layer, and presents everything through a single split-panel dashboard that looks nothing like a chatbot.

**This is the competitive pitch:** CloudGuard AI is the intelligent orchestration layer that makes AWS's own frontier agents context-aware and team-specific — all in one place, with a live dashboard experience that judges will not have seen before.

---

## 2. Research Findings — AWS Frontier Agent Landscape (June 2026)

### 2.1 What AWS Has Built

AWS launched three "frontier agents" — autonomous systems that work independently to achieve goals, scale to tackle concurrent tasks, and run persistently without constant human oversight.

| AWS Agent | Status | Key Capability |
|---|---|---|
| AWS DevOps Agent | GA (March 31, 2026) | Incident investigation, RCA, proactive prevention across AWS + on-prem |
| AWS Security Agent | GA (March 31, 2026) | Autonomous penetration testing, code scanning, architecture review |
| AWS FinOps Agent | Public Preview (June 9, 2026) | Cost anomaly investigation, optimization recommendations, Jira ticket creation |

In preview, customers report up to 75% lower MTTR, 80% faster investigations, and 94% root cause accuracy using AWS DevOps Agent. AWS Security Agent compresses penetration testing timelines from weeks to hours.

### 2.2 API and Programmability — What We Found

This is the critical research finding that shapes the entire architecture.

**AWS DevOps Agent — Full API available:**
- Direct API access to create and manage Agent Spaces, trigger investigations, and retrieve findings
- Agent Client Protocol (ACP) for programmatic invocation
- Webhooks — external systems can trigger investigations via HTTP. CloudWatch alarms, Grafana, PagerDuty, and custom monitoring tools can all send webhook payloads
- MCP server integration — extend beyond built-in tools with your own private MCP servers
- Built-in integrations with CloudWatch, Datadog, Dynatrace, Splunk, New Relic, GitHub, GitLab, Jenkins, Jira, ServiceNow, PagerDuty, Slack

**AWS Security Agent — API available for penetration testing:**
- Supports programmatic invocation for on-demand pen testing
- Full repository code review capability (previewed May 2026)
- Supports AWS, multicloud, and on-premises environments

**AWS FinOps Agent — API NOT available yet (preview limitation):**
- Currently outputs results only via its own web UI, Slack, or Jira
- No SNS, EventBridge, or programmatic response retrieval in current preview
- Expected to gain API access at GA, but not available for the competition timeline

### 2.3 The Gap AWS Agents Cannot Fill

Despite their power, none of the AWS frontier agents have:

- Knowledge of your specific team architectures (networking, file transfer, Jenkins)
- Your historical incident SOPs and resolution patterns
- Your existing Viz vulnerability scan pipeline and JSON outputs in S3
- Your organisation's tagging conventions and team-to-account mappings
- Context about your on-premises infrastructure and client integration patterns
- A unified interface where all three capabilities live side by side

That gap is exactly what CloudGuard AI fills.

---

## 3. Problem Statement

### 3.1 Organisational Context

The organisation is a fintech company that has migrated its primary application to AWS cloud, while maintaining an on-premises presence. Multiple specialised teams operate independently:

- **Networking Team** — manages ingress/egress, VPCs, load balancers, DNS
- **File Transfer Team** — manages secure file exchange pipelines between clients and internal systems
- **Jenkins / CI-CD Team** — manages build and deployment pipelines
- **Security Team** — manages vulnerability scanning using Viz (integrated with AWS resources via Lambda, outputs JSON to S3)
- **Cloud Platform / DevOps Team** — manages infrastructure, cost, and operational excellence

### 3.2 Current Pain Points

**Fragmentation:** Three powerful AWS frontier agents exist but live in three separate consoles. Engineers context-switch between them, losing time and coherence.

**No team context:** AWS DevOps Agent, Security Agent, and FinOps Agent are generic. They do not know the file transfer team's Lambda pipeline, the networking team's ingress architecture, or which Viz findings are false positives for a given team's design.

**Existing data is underutilised:** Viz scan results sit in S3 as JSON. Architecture documents sit in Confluence or SharePoint. Incident SOPs exist in runbooks nobody reads under pressure. None of this is available to the AWS frontier agents.

**No unified experience:** There is no single place where a DevOps engineer or team lead can go to get security posture, cost health, and incident investigation in one conversation with one interface.

---

## 4. Vision & Goals

### 4.1 Vision Statement

> Build the unified command centre that makes AWS's own frontier agents team-aware — so that every engineering team in the organisation can diagnose, resolve, and prevent infrastructure issues in minutes, from a single platform that knows who they are and how their systems work.

### 4.2 Strategic Goals

- **Orchestrate AWS frontier agents via API** — trigger DevOps Agent investigations and Security Agent scans programmatically from CloudGuard AI
- **Add team-specific RAG context** — wrap frontier agent responses with architecture knowledge, SOPs, and historical incident data via Bedrock Knowledge Bases
- **Surface your existing Viz pipeline** — read the S3 JSON outputs your Lambda already generates and make them conversational and actionable
- **Build a custom FinOps agent** using AgentCore + Cost Explorer APIs since FinOps Agent has no external API in preview
- **Deliver a live dashboard UI** that renders findings, charts, and actions alongside the conversation — not a chatbot
- **Stay entirely within AWS** — Bedrock, AgentCore, IAM, S3, Lambda, no external API dependencies

---

## 5. Architecture — Hybrid Orchestration Model

### 5.1 Architectural Principle

CloudGuard AI is an **orchestration and context layer**, not an agent-from-scratch build. It sits above AWS frontier agents and adds team intelligence.

```
┌─────────────────────────────────────────────────────┐
│              CloudGuard AI — Custom UI               │
│     Split-panel: Chat (left) + Dashboard (right)    │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│           Orchestration Layer (Lambda / ECS)         │
│   Intent Router → Agent Selector → Context Injector │
└────────┬─────────────┬──────────────┬───────────────┘
         │             │              │
┌────────▼──┐  ┌───────▼──┐  ┌───────▼────────────────┐
│ DevOps    │  │ Security  │  │ FinOps Agent           │
│ Agent API │  │ Agent API │  │ (Custom — AgentCore +  │
│ (AWS GA)  │  │ (AWS GA)  │  │  Cost Explorer APIs)   │
└────────┬──┘  └───────┬──┘  └───────┬────────────────┘
         │             │              │
┌────────▼─────────────▼──────────────▼───────────────┐
│              RAG Context Layer                        │
│   Bedrock Knowledge Bases + OpenSearch Serverless    │
│   Team architecture docs, SOPs, incident history     │
│   Viz scan JSON from S3, tagging conventions         │
└─────────────────────────────────────────────────────┘
```

### 5.2 Component Breakdown

| Component | Technology | Purpose |
|---|---|---|
| Frontend | React (split-panel) | Chat + live dashboard side by side |
| Backend / Orchestration | Lambda + API Gateway or FastAPI on ECS | Intent routing, context injection, response aggregation |
| Troubleshooting Agent | AWS DevOps Agent API + ACP + Webhooks | RCA, incident investigation, CloudWatch alarm response |
| Security Agent | AWS Security Agent API | Pen testing, code scanning + your Viz S3 data on top |
| FinOps Agent | Custom — AgentCore Runtime + Cost Explorer MCP | Cost queries, anomaly investigation, Jira ticket creation |
| RAG / Knowledge Base | Bedrock Knowledge Bases + S3 | Team architecture docs, SOPs, Viz findings, runbooks |
| LLM | Claude Opus 4.6 on Amazon Bedrock | Powers custom FinOps agent + context enrichment layer |
| Agent Infrastructure | Amazon Bedrock AgentCore | Runtime, Memory, Gateway, Policy, Observability |
| Document Ingestion | S3 → Bedrock Knowledge Base (auto-sync) | Teams upload docs, agent knowledge updates automatically |
| Auth | Amazon Cognito + IAM | Team-scoped access, engineers see only their data |
| Observability | AgentCore Observability + CloudWatch | Agent quality monitoring, trace visibility |

### 5.3 AgentCore Services Used

AgentCore is the backbone for the custom FinOps agent and the context enrichment layer:

- **AgentCore Runtime** — managed harness with no orchestration code required. Define model + system prompt + tools, run immediately. Up to 8-hour execution windows.
- **AgentCore Gateway** — converts your AWS Cost Explorer, Viz S3, and Jira APIs into MCP-compatible tools. Single secure endpoint for tool discovery.
- **AgentCore Memory** — persistent memory across sessions. Remembers team preferences, recurring issues, previous investigation context.
- **AgentCore Policy** — defines what each agent can and cannot do. Written in natural language, converts to Cedar policy. Enforced outside agent code — critical for fintech.
- **AgentCore Evaluations** — continuously monitors agent response quality in production. Catches degradation as team contexts evolve.

### 5.4 UI Design

The platform homepage presents three agent tiles — not a chatbot dropdown. Each tile shows a brief description of what that agent handles. Clicking opens a workspace with:

- **Left panel:** Conversational interface with the selected agent
- **Right panel:** Live dashboard updating in real-time — severity charts, cost trend graphs, investigation timelines, Jira ticket previews, resource maps

A smart intent router at the top accepts free-text problem descriptions and recommends the right agent. CloudWatch alarm webhooks can auto-open the Troubleshooting workspace with pre-loaded context.

---

## 6. Agent Specifications

### 6.1 Troubleshooting Agent — Powered by AWS DevOps Agent API

**Strategy:** Call AWS DevOps Agent programmatically. Add your RAG context (architecture docs, SOPs) as enrichment before displaying results.

**How it works:**
1. User describes an incident, or a CloudWatch alarm fires a webhook
2. CloudGuard AI injects team context from Bedrock Knowledge Bases into the investigation request
3. Calls AWS DevOps Agent API to trigger investigation
4. AWS DevOps Agent performs RCA using CloudWatch, logs, CI/CD data
5. CloudGuard AI receives findings and enriches them with team-specific SOP matches from RAG
6. Results render in the dashboard — timeline, root cause, suggested fix, matching historical incidents

**What AWS DevOps Agent brings:**
- 94% root cause accuracy reported in preview
- Native CloudWatch, Splunk, Datadog, GitHub integrations
- 75% lower MTTR in production customer deployments
- Runbook support — upload your SOPs directly to the Agent Space

**What CloudGuard AI adds on top:**
- Team architecture context (file transfer pipeline design, networking ingress patterns)
- Historical incident matching from your own RAG knowledge base
- Unified dashboard rendering alongside the chat
- Cross-agent context (e.g. a cost spike correlating with a security finding)

**Webhook integration:**
CloudWatch alarms → CloudGuard AI webhook handler → enriches with team context → triggers DevOps Agent investigation → results flow back to dashboard automatically. Engineers see an investigation already in progress when they open the platform.

### 6.2 Security Agent — AWS Security Agent API + Viz Pipeline

**Strategy:** Use AWS Security Agent for pen testing and code scanning. Layer your existing Viz S3 data on top via Bedrock Knowledge Base for infrastructure vulnerability intelligence.

**How it works:**
1. User queries security posture for their team
2. CloudGuard AI reads Viz scan JSON from S3 (your existing Lambda pipeline output)
3. RAG layer enriches findings with team architecture context — identifies likely false positives
4. AWS Security Agent API called for on-demand pen testing if deeper validation needed
5. Results combined and rendered — severity breakdown chart, finding explanations, false positive flags, Jira ticket creation

**What AWS Security Agent brings:**
- Autonomous penetration testing 24/7
- Full repository code review — context-aware vulnerability detection
- Compresses pen testing from weeks to hours

**What CloudGuard AI adds on top:**
- Your Viz scan data — infrastructure-level findings AWS Security Agent doesn't see
- False positive analysis using team architecture RAG context
- Cross-team executive view of security posture
- Direct Jira ticket creation from findings

### 6.3 FinOps Agent — Custom Build on AgentCore

**Strategy:** Build a lightweight custom agent using AgentCore Runtime + AgentCore Gateway wrapping Cost Explorer MCP tools. AWS FinOps Agent has no external API in preview — this is where you build.

**How it works:**
1. User asks a cost question or anomaly fires
2. AgentCore Runtime invokes Claude Opus 4.6 on Bedrock with team context injected
3. AgentCore Gateway routes tool calls to Cost Explorer, Cost Anomaly Detection, Compute Optimizer
4. Agent analyses spend by team tag, identifies drivers, surfaces recommendations
5. Creates Jira tickets for cost remediation tasks via AgentCore Gateway → Jira MCP
6. Cost trend charts render in the dashboard panel

**Why build this one custom:**
- AWS FinOps Agent has no external API in current preview — outputs only to its own UI, Slack, or Jira
- Your organisation has team-specific tagging conventions that need custom mapping logic
- AgentCore makes this the simplest of the three to build — define tools + system prompt + model, harness handles the rest
- You can upload team-to-account mapping context files, just like AWS FinOps Agent supports

---

## 7. Integrations

### 7.1 AWS DevOps Agent Integration Methods

| Method | Use Case in CloudGuard AI |
|---|---|
| Direct API | Trigger investigations, retrieve findings, manage Agent Spaces |
| ACP (Agent Client Protocol) | Programmatic agent invocation from orchestration layer |
| Webhooks | CloudWatch alarms auto-trigger investigations, results flow to dashboard |
| MCP Server | Connect your Viz pipeline and on-prem tools as custom tools for DevOps Agent |

### 7.2 AWS Services (via AgentCore Gateway MCP)

- **CloudWatch** — alarms, log groups, metrics
- **Cost Explorer** — spend data, forecasts, RI/SP analysis
- **Cost Anomaly Detection** — anomaly events and triggers
- **Compute Optimizer** — rightsizing recommendations
- **S3** — Viz scan JSON, team document uploads for RAG
- **Lambda** — invocation logs and error analysis
- **GuardDuty** — threat intelligence findings
- **CloudTrail** — API activity for anomaly correlation

### 7.3 Jira Integration

- Read sprint backlog and existing tickets per team
- Create tickets from security findings, cost recommendations, incident RCAs
- Pre-fill with agent-generated content — finding details, affected ARN, suggested fix, priority
- Available via AgentCore Gateway as an MCP tool for the FinOps agent
- AWS DevOps Agent and Security Agent have native Jira integration

### 7.4 On-Premises

- Architecture docs from on-prem systems ingested into Bedrock Knowledge Bases
- Custom MCP server connected to DevOps Agent for on-prem observability data
- Incident SOPs covering both cloud and on-prem components in RAG knowledge base

---

## 8. Key User Stories

| ID | As a... | I want to... | So that... |
|---|---|---|---|
| US-01 | File Transfer Engineer | Ask the troubleshooting agent why a client file failed, have it trigger a DevOps Agent investigation and show me the RCA | I resolve the issue in minutes with full context of our transfer architecture |
| US-02 | Networking Engineer | See my team's Viz vulnerability findings explained in the context of our ingress architecture | I can distinguish real risks from false positives without reading raw JSON |
| US-03 | DevOps Lead | Raise Jira tickets for all critical security findings in one command | Remediation enters the sprint without manual ticket creation |
| US-04 | Cloud Platform Engineer | Ask the FinOps agent for top cost-saving opportunities with estimated savings | I can prioritise rightsizing work with real data |
| US-05 | On-Call Engineer | Have a CloudWatch alarm automatically trigger a DevOps Agent investigation that's already in progress when I open the platform | I can brief stakeholders immediately rather than starting from scratch |
| US-06 | Security Lead | Upload a new architecture doc to S3 and have the agent use it immediately | Agent knowledge stays current without central re-training |
| US-07 | CTO / Executive | Get a cross-team security and cost summary in plain language with charts | I can understand organisational risk and spend without switching consoles |

---

## 9. Non-Functional Requirements

### 9.1 Security & Compliance
- All agent actions logged via CloudTrail — full audit trail required for fintech
- AgentCore Policy enforces what each agent can do — controlled outside agent code
- AgentCore Identity integrates with Cognito / Okta for team-scoped access
- No sensitive customer financial data passed through LLM — infrastructure metadata only
- AWS DevOps Agent runs in US East (N. Virginia) — ensure data residency compliance

### 9.2 Reliability
- AWS DevOps Agent and Security Agent are GA — production-grade SLAs
- Custom FinOps agent on AgentCore has 8-hour execution window support
- Mock data fallback for demo if live AWS API calls are rate-limited
- AgentCore Evaluations monitors custom agent quality continuously

### 9.3 Performance
- Dashboard renders within 3 seconds of agent response
- Webhook-triggered investigations begin within seconds of CloudWatch alarm
- RAG retrieval under 2 seconds

---

## 10. 15-Day Development Plan

Four DevOps engineers. AI-assisted development using Copilot + Claude Opus 4.8 for code generation. Bedrock-native stack throughout.

| Phase | Days | Deliverable | Owner |
|---|---|---|---|
| Phase 0 | Days 1–2 | Architecture doc, API contracts, AWS DevOps Agent Space setup, Bedrock Knowledge Base setup, shared data schemas, mock data | All — Integration Lead coordinates |
| Phase 1 | Days 3–6 | AWS DevOps Agent API integration — trigger investigations, retrieve findings, webhook handler for CloudWatch alarms | Engineer 1 |
| Phase 1 | Days 3–6 | Frontend — split-panel UI, agent selector tiles, dashboard component library, real-time update mechanism | Engineer 4 |
| Phase 2 | Days 7–9 | Security layer — Viz S3 reader, Bedrock Knowledge Base RAG for architecture context, Security Agent API integration, false positive analysis, Jira ticket creation | Engineer 2 |
| Phase 2 | Days 7–10 | Custom FinOps Agent — AgentCore Runtime + Gateway + Cost Explorer MCP tools, Jira ticket creation, cost trend queries | Engineer 3 |
| Phase 3 | Days 11–13 | Integration — orchestration layer connecting all three agents to frontend, intent router, cross-agent context, end-to-end testing | All |
| Phase 4 | Days 14–15 | Demo polish — mock data for visuals, 10-minute demo script, presentation rehearsal | All |

### 10.1 Development Approach

- Each engineer receives a detailed task spec (written in Phase 0) as primary context for Claude/Copilot code generation
- All four engineers use the same shared prompt template — ensures consistent naming, error handling, API patterns
- Shared validation checklist before every merge — API contract compliance, mock data test, integration smoke test
- One Integration Lead reviews all PRs and resolves architectural conflicts
- AWS DevOps Agent Space can be configured and tested from Day 1 — it requires no code to set up

---

## 11. Competition Differentiation — Why This Wins

| Other teams will build | CloudGuard AI builds |
|---|---|
| Chatbot wrapper around a single AWS service | Unified orchestration layer over three AWS frontier agents |
| Custom agent with no real execution power | Real actions via GA AWS agents + live Jira ticket creation |
| Generic cost or security dashboard | Team-context-aware intelligence that knows your architectures |
| Chat-only interface | Split-panel: live dashboard updates as the conversation unfolds |
| Point solution for one problem | Platform thinking — security + cost + troubleshooting in one place |

**The pitch in one sentence:** CloudGuard AI is what happens when you put a team-aware brain on top of AWS's own frontier agents — so your engineers stop switching between three consoles and start solving problems in one.

---

## 12. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| AWS DevOps Agent API access/permissions not approved in time | Medium | Set up Agent Space Day 1. Use webhook + mock API response as fallback for demo. |
| FinOps Agent gains external API during preview, changing strategy | Low | Custom AgentCore FinOps agent is still valuable — more team-context-aware than AWS FinOps Agent |
| RAG context returns irrelevant results | Medium | Implement relevance scoring. Agent flags low-confidence responses rather than hallucinating. |
| Integration conflicts between four parallel workstreams | High | Strict API contracts defined in Phase 0. Integration Lead reviews all PRs. Daily sync. |
| AWS DevOps Agent only available in US East (N. Virginia) | Medium | Verify region availability for your AWS account before Day 1. |
| Demo rate limits on AWS APIs | Medium | Pre-cache common responses. Use realistic mock data as fallback. |

---

## 13. Out of Scope — Competition Version

- Auto-remediation without human approval
- Replacing AWS frontier agent consoles entirely
- Building a custom troubleshooting or pen-testing agent from scratch (DevOps Agent and Security Agent handle this)
- Multi-tenancy / enterprise user management
- Mobile application
- Full production deployment — proof of concept for competition

---

## 14. Document Roadmap — Next Steps

1. **System Architecture Document** — detailed component diagram with DevOps Agent API flows, AgentCore setup, Bedrock Knowledge Base ingestion pipeline
2. **AWS DevOps Agent Integration Spec** — ACP invocation patterns, webhook payload formats, finding retrieval schemas, Agent Space configuration
3. **Security Agent + Viz Integration Spec** — S3 JSON schema, RAG enrichment logic, false positive detection approach, Jira ticket schema
4. **Custom FinOps Agent Spec** — AgentCore Runtime config, Cost Explorer MCP tool definitions, team tagging logic, savings estimation approach
5. **RAG Knowledge Base Spec** — document types, chunking strategy, embedding model choice, relevance scoring, S3 ingestion pipeline
6. **UI Specification** — split-panel wireframes, dashboard component definitions, agent tile designs, real-time update patterns
7. **Shared Development Guide** — prompt templates for Copilot/Claude, validation checklist, PR review standards, mock data library

---

*CloudGuard AI — PRD v2.0 | Updated June 2026 | Confidential — Internal Use Only*
