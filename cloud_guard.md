# CloudGuard AI — Intelligent Multi-Agent Platform for AWS & On-Prem Infrastructure
### Product Requirements Document (PRD) — v1.0

---

| Field | Detail |
|---|---|
| Document Type | Product Requirements Document (PRD) |
| Project Name | CloudGuard AI — Multi-Agent Intelligence Platform |
| Organization | Fintech — Cloud & Infrastructure Division |
| Team Size | 4 DevOps Engineers |
| Timeline | 15 Days |
| Cloud Provider | AWS (Primary) + On-Premises Infrastructure |
| Status | Draft — In Progress |

---

## 1. Executive Summary

CloudGuard AI is an intelligent, context-aware multi-agent platform designed to empower engineering teams across a large fintech organisation to diagnose, resolve, and proactively address issues across AWS cloud infrastructure and on-premises systems. The platform acts as a single unified command centre — replacing the need to manually switch between AWS consoles, security dashboards, Jira boards, and runbooks.

The core innovation is not a chatbot. CloudGuard AI is an agentic system where each agent understands the architecture, incident history, and operational context of the team it serves. Agents can take real actions — raising Jira tickets, reading CloudWatch logs, analysing security findings, and suggesting remediations — while simultaneously rendering live visual dashboards that update as the conversation unfolds.

Built for a fintech organisation operating a hybrid cloud model, this platform addresses three critical pain points:

- Security vulnerabilities scattered across multiple team-owned AWS resources without a unified intelligent interface
- Cloud cost inefficiencies with no proactive guidance or automated ticket creation for remediation
- Slow incident troubleshooting caused by lack of contextual knowledge about team architectures, SOPs, and historical resolutions

---

## 2. Problem Statement

### 2.1 Organisational Context

The organisation is a fintech company that has migrated its primary application to AWS cloud, while maintaining an on-premises presence. Multiple specialised teams operate independently:

- **Networking Team** — manages ingress/egress, VPCs, load balancers, DNS
- **File Transfer Team** — manages secure file exchange pipelines between clients and internal systems
- **Jenkins / CI-CD Team** — manages build and deployment pipelines
- **Security Team** — manages vulnerability scanning using Viz (integrated with AWS resources via Lambda)
- **Cloud Platform / DevOps Team** — manages infrastructure, cost, and operational excellence

### 2.2 Current Pain Points

#### Security
- Vulnerability scans are generated and stored as JSON in S3, with a separate dashboard for visualisation
- Teams cannot easily query their own vulnerability posture in plain language
- No intelligent system exists to distinguish false positives from genuine findings based on team-specific architecture context
- Escalation to Jira for remediation is manual and inconsistent

#### Cost Optimisation
- No proactive alerting or intelligent analysis of cost anomalies at the team level
- Engineers lack a conversational interface to understand cost drivers and receive actionable recommendations
- Remediation tasks are not automatically translated into sprint-trackable Jira tickets

#### Troubleshooting
- When incidents occur (e.g. file transfer failures, Lambda errors, CloudWatch alarms), engineers must manually correlate logs, SOPs, and architecture diagrams
- No system captures institutional knowledge about recurring issues and their resolutions
- Root cause analysis is slow, especially for on-call engineers unfamiliar with the affected team's architecture

---

## 3. Vision & Goals

### 3.1 Vision Statement

> Empower every engineering team in the organisation with a context-aware AI agent that knows their architecture, understands their operations, and can take real action — so that diagnosing, resolving, and preventing infrastructure issues takes minutes, not hours.

### 3.2 Strategic Goals

- **Build a multi-agent AI platform that is agentic** — capable of reading data, writing to systems, and suggesting actions — not just answering questions
- **Achieve visual differentiation** through live dashboards rendered alongside the conversational interface
- **Make the platform team-context-aware** by vectorising team architecture docs, SOPs, and incident history into a RAG pipeline
- **Integrate with AWS services** (CloudWatch, Cost Explorer, GuardDuty, S3, Lambda) and Jira via MCP servers
- **Support both AWS cloud and on-premises** infrastructure queries
- **Demonstrate executive-level value** by surfacing portfolio-wide security and cost intelligence

---

## 4. Platform Architecture Overview

### 4.1 High-Level Architecture

| Layer | Components |
|---|---|
| **Frontend** | Agent Command Centre UI — chat panel + live dashboard panel. Agent selector tiles. Real-time data visualisation (charts, severity tables, cost graphs). |
| **Agent Orchestration** | Router / intent classifier that maps user queries to the correct agent. Multi-turn conversation state management. Agent context injection (team, architecture, history). |
| **Specialised Agents** | Security Agent, Cost Optimisation Agent, Troubleshooting Agent. Each has its own tool set, knowledge base, and RAG context. |
| **RAG / Knowledge Layer** | Vector database of team architecture documents, SOPs, incident runbooks, and resolution history. S3 upload pipeline for self-service doc ingestion by teams. |
| **Integration Layer** | MCP Servers for AWS (CloudWatch, Cost Explorer, S3, Lambda, GuardDuty, AWS DevOps Guru) and Jira. On-premises connectivity via secure API gateway. |

### 4.2 UI Design Philosophy

The platform deliberately avoids the pure chatbot look. The UI is split into two panels:

- **Left panel:** Conversational chat with the selected agent
- **Right panel:** Live dashboard that updates in real-time as the agent processes queries — showing charts, severity tables, cost breakdowns, resource lists, and Jira ticket previews

The homepage presents agents as selectable tiles (not dropdown tabs), each with a short description of what it can do. A smart router at the top allows free-text problem description, which the system uses to recommend the best agent.

---

## 5. Agent Specifications

### 5.1 Security Agent

**Purpose:** Empower teams to understand, prioritise, and act on their security vulnerability posture across AWS resources. Built on top of the existing Viz scanning pipeline that generates findings as JSON in S3.

#### Key Capabilities
- Query vulnerability data by team, account, resource type, or severity (Critical / High / Medium / Low)
- Explain findings in plain language with context from the team's architecture (e.g. "This finding in your ingress ALB is likely a false positive because your WAF rules intentionally allow this traffic pattern")
- Identify false positives vs genuine findings using RAG context from team architecture docs
- Suggest remediation steps tailored to the team's specific resource configuration
- Create Jira tickets automatically for confirmed vulnerabilities, pre-filled with finding details, affected resource ARN, suggested fix, and sprint assignment
- Read and summarise existing Jira security tickets for a given team's sprint backlog
- Provide a link to the existing security dashboard for executive-level portfolio views
- Generate visual severity breakdowns (bar charts, pie charts) on the live dashboard panel

#### Data Sources
- Viz scan results — JSON stored in S3, scanned per team per AWS account
- Team architecture documents — vectorised in the RAG knowledge base
- Jira — read sprint backlog, create tickets via MCP server
- AWS resource metadata — via AWS MCP server

#### Example User Interactions
- *"How many critical vulnerabilities does the file transfer team have this week?"*
- *"Show me the top 5 high-severity findings for the networking team and explain each one"*
- *"Is the IAM finding on the Lambda function a false positive given our architecture?"*
- *"Raise a Jira ticket for all critical findings in the networking team and add them to the current sprint"*

---

### 5.2 Cost Optimisation Agent

**Purpose:** Help engineering teams identify AWS cost inefficiencies, understand cost drivers, and generate actionable remediation tasks tracked in Jira sprints.

#### Key Capabilities
- Query AWS Cost Explorer data by team, service, time range, or resource tag
- Identify top cost drivers and anomalies (e.g. unexpected Lambda invocation spikes, oversized EC2 instances, idle resources)
- Provide specific optimisation recommendations (rightsizing, Reserved Instance opportunities, S3 lifecycle policies, NAT Gateway alternatives)
- Estimate monthly savings potential for each recommendation
- Create Jira tickets for cost remediation tasks, assigned to the relevant team, with estimated effort and saving
- Render live cost trend charts and service-level breakdown tables on the dashboard panel
- Compare month-over-month or quarter-over-quarter cost trends

#### Data Sources
- AWS Cost Explorer — via AWS MCP server
- AWS resource inventory — EC2, RDS, Lambda, S3, NAT Gateway usage data
- Tagging metadata — to attribute costs to specific teams
- Jira — ticket creation via MCP server

#### Example User Interactions
- *"What are the top 3 cost drivers for the file transfer team this month?"*
- *"Which Lambda functions are over-provisioned and how much can we save by rightsizing?"*
- *"Create Jira tickets for all cost recommendations above $500/month saving potential"*
- *"Show me cost trends for the networking team over the last 3 months"*

---

### 5.3 Troubleshooting Agent

**Purpose:** Accelerate incident resolution by combining live AWS log and alarm data with team-specific architecture knowledge and historical incident SOPs. This agent is context-aware at the team level — it knows how each team's system is architected and what has worked before.

#### Key Capabilities
- Ingest and analyse CloudWatch alarms and log groups in real-time
- Cross-reference alarm details with team architecture documents (vectorised via RAG) to identify the most likely root cause
- Retrieve and apply relevant incident SOPs from the knowledge base
- Perform root cause analysis (RCA) and present findings in a structured, human-readable format
- Suggest resolution steps based on historical incident resolution data
- Leverage AWS DevOps Guru for AI-powered anomaly detection and operational recommendations
- For auto-remediable issues, present the proposed fix and request human approval before execution
- Notify relevant teams of issue summary and resolution via Jira ticket creation
- Support both AWS-hosted and on-premises component troubleshooting

#### RAG Knowledge Base — What Gets Vectorised
- Team architecture design documents (uploaded to S3 by teams)
- Incident SOPs and runbooks
- Historical incident resolution records
- Client integration documentation (e.g. file naming conventions, expected transfer patterns)

#### Self-Service Document Ingestion
Teams can upload new architecture documents or SOPs directly to a designated S3 bucket. An automated pipeline vectorises and indexes the document, making it immediately available to the agent. This allows teams to keep the agent's knowledge current without central intervention.

#### Example User Interactions
- *"A CloudWatch alarm just fired for the file transfer Lambda — what happened and how do we fix it?"*
- *"The client sent a file 2 hours ago but it never arrived at the destination bucket — troubleshoot this"*
- *"Show me the last 3 incidents for the networking team and their resolutions"*
- *"Is this a known issue? What was the fix last time we saw this alarm?"*

#### Scope Boundary — Competition Version
For the competition demo, the Troubleshooting Agent will focus on RCA and recommendation. Auto-remediation (direct execution of fixes) will require explicit human approval and will be scoped to low-risk, well-defined actions only (e.g. S3 event notification resets, Lambda retry triggers). This ensures safe demonstration in a fintech context.

---

## 6. Integrations & MCP Servers

### 6.1 AWS MCP Server

The platform integrates with AWS via MCP server, providing agents with access to:

- **CloudWatch** — alarms, log groups, metrics, log insights queries
- **Cost Explorer** — cost and usage data, forecasts, rightsizing recommendations
- **S3** — reading Viz scan JSON outputs, team document uploads for RAG ingestion
- **Lambda** — function invocation logs, error analysis
- **GuardDuty** — threat intelligence findings
- **AWS DevOps Guru** — operational anomaly detection and recommendations
- **IAM** — resource policy metadata for security context
- **EC2 / VPC** — resource inventory, networking topology

### 6.2 Jira MCP Server

Jira integration enables the platform to:

- Read sprint backlog and existing tickets for a given team
- Create new tickets pre-filled with agent-generated content (finding details, remediation steps, priority, team assignment)
- Update existing ticket statuses
- Link related tickets (e.g. a cost finding linked to the remediation ticket)

### 6.3 On-Premises Connectivity

- Secure API gateway / VPN tunnel for on-prem log and metric ingestion
- On-prem architecture documents included in the RAG knowledge base
- Unified incident view across cloud and on-prem components

### 6.4 Existing Security Dashboard

The platform does not replace the existing Viz security dashboard. Instead, the Security Agent provides:

- Intelligent conversational queries on top of the same underlying data
- Deep links to the existing dashboard for executives and stakeholders who prefer visual-first navigation
- Contextual intelligence (false positive analysis, architecture-aware explanations) that the raw dashboard cannot provide

---

## 7. Key User Stories

| ID | As a... | I want to... | So that... |
|---|---|---|---|
| US-01 | File Transfer Engineer | Ask the troubleshooting agent why a client file failed to reach the destination bucket | I can resolve the issue in minutes without reading raw Lambda logs manually |
| US-02 | Networking Engineer | Query my team's critical vulnerabilities and get architecture-aware explanations | I can distinguish genuine risks from false positives without reading raw Viz JSON |
| US-03 | DevOps Lead | Raise Jira tickets for all critical security findings in one command | Remediation tasks enter the sprint immediately without manual ticket creation |
| US-04 | Cloud Platform Engineer | Ask the cost agent for the top 5 cost-saving opportunities this month | I can prioritise rightsizing and reservation work with estimated savings data |
| US-05 | On-Call Engineer | Get an RCA within minutes of a CloudWatch alarm firing | I can brief stakeholders and begin remediation without deep architecture expertise |
| US-06 | Security Lead | Upload a new architecture doc to S3 and have the agent immediately use it | The agent stays current with our evolving infrastructure without manual re-training |
| US-07 | CTO / Executive | Ask for a portfolio-wide summary of security posture across all teams | I can understand organisational risk exposure in plain language with visual charts |

---

## 8. Non-Functional Requirements

### 8.1 Security & Compliance
- All agent actions are logged with full audit trail (who queried, what action was taken, timestamp)
- Role-based access — engineers see only their team's data; leads and executives see cross-team views
- No sensitive financial or customer data is passed through the AI model — only infrastructure metadata
- MCP server credentials managed via AWS Secrets Manager

### 8.2 Reliability
- Agent responses must gracefully handle AWS API rate limits and partial failures
- RAG knowledge base must handle stale documents — flag documents older than 90 days for team review
- Auto-remediation actions require human confirmation before execution

### 8.3 Performance
- Initial agent response within 5 seconds for standard queries
- Dashboard visualisations render within 3 seconds of agent response
- RAG retrieval latency under 2 seconds for document lookup

### 8.4 Scalability
- Platform designed to support additional agents beyond the initial three
- Vector database supports incremental document ingestion without full re-indexing

---

## 9. 15-Day Development Plan

Four DevOps engineers, AI-assisted development using Claude (Opus 4.8). Each engineer owns one vertical end-to-end.

| Phase | Days | Deliverable | Owner |
|---|---|---|---|
| Phase 0 | Days 1–2 | Architecture docs, API contracts, data schemas, shared tech stack decisions, mock data creation | All (Integration Lead coordinates) |
| Phase 1 | Days 3–6 | Security Agent — Viz S3 reader, RAG context injection, severity query, false positive analysis, Jira ticket creation, dashboard charts | Engineer 1 |
| Phase 1 | Days 3–6 | Frontend — Agent Command Centre UI, split-panel layout, agent selector tiles, real-time dashboard panel | Engineer 4 |
| Phase 2 | Days 7–10 | Cost Optimisation Agent — Cost Explorer integration, recommendations engine, savings estimator, Jira ticket creation, trend charts | Engineer 2 |
| Phase 2 | Days 7–10 | Troubleshooting Agent — RAG pipeline, CloudWatch integration, DevOps Guru, RCA engine, SOP retrieval, S3 doc ingestion pipeline | Engineer 3 |
| Phase 3 | Days 11–13 | Integration — all agents connected to frontend, router/intent classifier, cross-agent context sharing, end-to-end testing | All |
| Phase 4 | Days 14–15 | Demo polish — mock data for impressive visuals, presentation script, 10-minute demo flow, pitch deck | All |

### 9.1 AI-Assisted Development Guidelines
- All four engineers use the same shared prompt template when asking Claude to generate code — ensures consistent patterns, naming, error handling
- Each engineer's task spec (written in Phase 0) is the primary input to Claude — the more detailed the spec, the better the output
- Before merging, each engineer runs the shared validation checklist: unit tests, API contract compliance, mock data verification
- One engineer acts as Integration Lead — reviews all PRs and resolves architectural conflicts
- Document all Claude-generated code decisions in comments — aids debugging and future enhancement

---

## 10. Success Metrics & Demo Criteria

### 10.1 Competition Demo — 10 Minute Flow

1. **Homepage** — Agent Command Centre with three agent tiles. Explain the platform concept in 60 seconds.
2. **Security Agent demo** — Query critical vulnerabilities for the file transfer team. Dashboard renders severity breakdown chart. Agent explains a finding in context of their architecture. One command raises a Jira ticket.
3. **Cost Agent demo** — Ask for top cost-saving opportunities. Dashboard renders cost trend graph. Agent generates a Jira ticket with estimated savings.
4. **Troubleshooting Agent demo** — Simulate a CloudWatch alarm for a file transfer failure. Agent cross-references architecture doc, identifies root cause, retrieves relevant SOP, presents RCA summary on dashboard.
5. **Close** — Emphasise the empowerment angle: any engineer in any team can now diagnose, resolve, and track issues in minutes with zero context-switching.

### 10.2 Winning Criteria
- **Visual differentiation** — the split-panel chat + live dashboard must look significantly different from a standard chatbot
- **Real action demonstrated** — Jira ticket creation and AWS data retrieval must be live, not mocked
- **Context awareness demonstrated** — agent must visibly use architecture knowledge to explain a finding or diagnosis
- **Breadth of problem-solving** — three distinct agents covering security, cost, and troubleshooting shows platform thinking, not point solution thinking

---

## 11. Risks & Mitigations

| Risk | Likelihood | Mitigation | Owner |
|---|---|---|---|
| Inconsistent AI-generated code across four parallel workstreams | High | Define strict API contracts and shared prompt templates in Phase 0. Integration Lead reviews all PRs. | Integration Lead |
| RAG pipeline returns irrelevant context, causing incorrect agent responses | Medium | Implement relevance scoring and confidence thresholds. Agent must indicate when it cannot find relevant context. | Engineer 3 |
| AWS API rate limits disrupting demo | Medium | Use mock data fallback for demo. Cache frequently queried data. | Engineer 1 / 2 |
| Integration failures between modules at merge time | High | Define shared data schemas upfront. Run integration tests from Day 10 onwards. | All |
| Troubleshooting Agent scope too large for timeline | High | Strictly limit to RCA + recommendation for competition. No auto-remediation without approval flow. | Engineer 3 |
| Demo environment AWS credentials / Jira access not available | Low | Confirm access in Day 1. Prepare mock API responses as fallback. | Integration Lead |

---

## 12. Out of Scope — Competition Version

- Auto-remediation without human approval
- Multi-tenancy / enterprise user management
- Custom model fine-tuning
- Mobile or native application
- Integration with services beyond AWS and Jira
- Full production deployment — this is a proof of concept for the competition

---

## 13. Document Roadmap — What to Create Next

1. **System Architecture Document** — detailed component diagram, data flow, tech stack decisions (model, vector DB, frontend framework, API design)
2. **API Contract Specification** — request/response schemas for all agent endpoints, error handling standards, authentication
3. **Security Agent Technical Document** — detailed data flow from Viz S3 JSON to agent response, RAG integration spec, Jira ticket schema
4. **Cost Optimisation Agent Technical Document** — AWS Cost Explorer query patterns, recommendation logic, savings calculation method
5. **Troubleshooting Agent Technical Document** — RAG pipeline design, vectorisation approach, SOP retrieval logic, CloudWatch integration patterns, DevOps Guru integration
6. **UI Specification** — wireframes of command centre layout, dashboard component definitions, agent selector design, real-time update patterns
7. **Shared Development Guide** — prompt templates for Claude, validation checklist, code standards, PR review criteria

---

*CloudGuard AI — PRD v1.0 | Confidential — Internal Use Only*
