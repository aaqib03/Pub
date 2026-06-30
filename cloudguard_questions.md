# CloudGuard AI — Multi-Agent System Optimization Audit
## Complete Questionnaire for Codebase Review

**Instructions:** Share this file with Copilot with your full codebase open. Ask it to answer every question by examining the actual code. For each answer, ask it to show the relevant code snippet. Once answered, share the responses back for a prioritized improvement plan.

---

## SECTION 1: INTENT ROUTING & ORCHESTRATOR

**Q1.** How is intent routing currently implemented? Is it purely keyword-matching, or does the orchestrator invoke Bedrock to classify intent? Show the exact code responsible for routing decisions.

**Q2.** When a user query comes in, what is the exact end-to-end flow in the orchestrator? Walk through: user message → keyword match → agent selection → what gets passed to that agent. Show the code for each step.

**Q3.** Show me the complete system prompt used by the master orchestrator agent. What context does it have about the different specialized agents it can route to?

**Q4.** How does the orchestrator decide which specialized agent to route to if a query could match multiple agents? For example: "Our Lambda costs went up AND it's failing" — is this Cost Agent or Troubleshooting Agent? Show the decision logic.

**Q5.** When a user query is ambiguous or spans multiple domains, does the orchestrator:
- a) Pick one agent and hope for the best
- b) Break the query into sub-questions and route each to the relevant agent in parallel
- c) Ask the user a clarifying question before routing
- d) Route to a primary agent but pass secondary context from other agents
- e) Something else — show the code

**Q6.** Can the orchestrator run multiple specialized agents sequentially or in parallel for a single user query? For example: "Why did our file transfer fail and how much is it costing us?" — does it invoke both Troubleshooting Agent AND Cost Agent and aggregate their responses, or does it pick one?

**Q7.** When the orchestrator aggregates responses from multiple agents, how does it combine them into one coherent, human-readable response? Show the aggregation prompt and logic.

**Q8.** Does the orchestrator have a confidence score or quality gate before returning a response to the user? If the agent gives a very short or "I don't know" response, does the orchestrator retry with more context, escalate to a different agent, or flag low confidence to the user?

**Q9.** Does the orchestrator detect when the same or similar question has been asked before in the session, and reuse or reference the previous answer? Show how this is handled.

**Q10.** When the orchestrator fetches context from the markdown index, does it use semantic search (embeddings) or exact keyword/team-name lookup? If keyword, what happens when the user doesn't mention the team name explicitly? (e.g., "Why is my Lambda failing?" with no team mentioned)

**Q11.** Does the orchestrator understand implicit team context? For example, if a user earlier said "I'm from the Networking Team" — does every subsequent message automatically carry that team context, or does the user have to re-state it every time? Show the code.

---

## SECTION 2: CONTEXT RETRIEVAL & TEAM KNOWLEDGE

**Q12.** Show me the structure of the markdown files used for team context. What information does each file contain? How many files are there, one per team?

**Q13.** Show me the playbook/index structure. How does the orchestrator know which file to retrieve for which team or query?

**Q14.** When a user asks about the "File Transfer Team", show me exactly how the orchestrator fetches team context — the retrieval logic step by step, including what code reads the markdown file and how much of it is passed forward.

**Q15.** Are you passing the entire markdown file for a team to the specialized agent, or extracting/summarizing specific sections relevant to the query? Show the code.

**Q16.** How much text (approximate token count) is typically passed as team context to a specialized agent per invocation?

**Q17.** The team context markdown files — how current are they? Are they auto-updated when infrastructure changes, or manually maintained? Is there any mechanism to flag stale context?

**Q18.** Do you vectorize the team markdown files for semantic retrieval, or is it purely file-based retrieval by team name? If not vectorized, is this planned?

**Q19.** Is there a "global context" layer that applies to ALL teams — for example, company-wide security policies, shared infrastructure, common Terraform modules, global compliance requirements — that every agent always has access to regardless of which team is being discussed?

**Q20.** When the user doesn't specify a team, how does the system determine which team's context to load? Does it ask the user, infer from query content, load all teams, or default to something?

---

## SECTION 3: SPECIALIZED AGENT ARCHITECTURE

**Q21.** Show me the complete system prompt for EACH specialized agent:
- Troubleshooting Agent
- Security Agent
- Cost Optimization Agent
- Compliance Agent (if built)

For each, answer: Does it define the agent's role? Does it define response format? Does it define tone (technical vs executive)? Does it handle uncertainty?

**Q22.** Is each agent's system prompt static or dynamically constructed per invocation? If dynamic, what variables are injected and from where? Show the prompt construction code for each agent.

**Q23.** When a specialized agent generates a response, does it:
- a) Return the first Bedrock response as-is
- b) Run the response through a validation/quality check before returning
- c) Use chain-of-thought to reason before answering ("Before answering, think through: what is the user asking, what context do I have, what tools do I need...")
- d) Compare the response against team context to ensure accuracy
- e) Something else — show the code

**Q24.** Does each specialized agent have explicit instructions for handling:
- a) Questions outside its domain (e.g., Cost Agent asked a security question)
- b) Incomplete or ambiguous queries
- c) When a tool returns no data or an error
- d) Sensitive data accidentally included in a query (credentials, PII)
- e) Conflicting information between RAG context and live tool result

**Q25.** For the Troubleshooting Agent specifically — when it performs RCA, does it:
- a) Just read logs and report what it found
- b) Cross-reference logs against team architecture docs for contextual explanation
- c) Check if this is a recurring issue (look at past incidents) and mention patterns
- d) All of the above
- Show the reasoning loop code.

**Q26.** For the Security Agent — when it reads Viz scan JSON from S3, does it:
- a) List all findings
- b) Filter findings based on team infrastructure context (false positive detection)
- c) Cross-reference findings against compliance requirements (PCI, etc.)
- Show the code.

**Q27.** For the Cost Optimization Agent — when providing recommendations, does it:
- a) Show raw Cost Explorer data
- b) Filter recommendations based on team architecture (avoid suggesting removal of intentional resources)
- c) Estimate savings with confidence levels
- Show the code.

**Q28.** Can agents call other agents as tools mid-reasoning? For example, can the Troubleshooting Agent invoke the Security Agent if it discovers a potential security cause for a performance issue? If not, is this planned?

---

## SECTION 4: MEMORY ARCHITECTURE

**Q29.** For SHORT-TERM MEMORY (current session in DynamoDB):
- What is the exact DynamoDB table schema? Show the structure.
- What exactly is stored per message? (full message objects, summaries, embeddings, metadata?)
- How many previous messages are retrieved and passed to the agent per invocation?
- Do you pass ALL previous messages or just the last N? What is N?
- Is there any summarization of older messages before they're passed as context?
- What is the maximum session length before context window overflow becomes a risk?
- Show the code that reads from DynamoDB and constructs the conversation history for the agent.

**Q30.** For LONG-TERM MEMORY (cross-session):
- Do you currently store anything across sessions? (e.g., recurring issues for a team, past resolutions, team preferences)
- If yes — where, in what format, and how is it retrieved for new sessions?
- If no — this is a critical gap. Is it planned?

**Q31.** When a user starts a NEW session, does the system:
- a) Start completely fresh with no prior knowledge of that user or team
- b) Load a team profile from a persistent store with known issues and architecture patterns
- c) Retrieve summaries of last N sessions for that user/team
- d) Both b and c
- Show the session initialization code.

**Q32.** Is there a "working memory" concept during an agent's reasoning loop? Does the agent maintain intermediate findings as it works through a multi-step problem, or does each tool call start fresh? Show the agent loop logic.

**Q33.** When an agent makes a tool call (reads CloudWatch logs, queries Cost Explorer), does the result get:
- a) Passed directly into the next Bedrock call verbatim (can be very noisy)
- b) Summarized/filtered before being passed back into the reasoning loop
- c) Stored in working memory and selectively referenced
- Show the tool result handling code.

---

## SECTION 5: TOOL USE & AGENTIC CAPABILITY

**Q34.** List EVERY tool currently available to each specialized agent. For each tool show:
- What it does
- What inputs it accepts
- What it returns
- How errors are handled if the tool fails or returns empty results

**Q35.** When an agent decides to call a tool, how many tool calls can it make in a single reasoning loop? Is there a limit? What happens if it needs many tool calls to answer a complex query?

**Q36.** When a tool call FAILS (API timeout, permission denied, empty result, rate limit), does the agent:
- a) Crash or return an error to the user
- b) Retry with different parameters
- c) Fall back to a different tool or data source
- d) Acknowledge to the user it couldn't retrieve that data and work with what it has
- Show the error handling code.

**Q37.** Does the system handle AWS API rate limiting gracefully? Show how throttling is handled for Cost Explorer, CloudWatch, Security Hub, and other AWS APIs being called.

**Q38.** Is there a fallback when Bedrock is slow or unavailable? What is the user experience if a Bedrock call takes 30+ seconds? Is there a timeout?

**Q39.** Does the system have any awareness of tool call costs or efficiency? For example, does it avoid redundant API calls within the same session?

---

## SECTION 6: MULTI-TEAM & CROSS-ARCHITECTURE INTELLIGENCE

**Q40.** When a user asks about an issue spanning two teams (e.g., "The Networking Team's VPC is blocking the File Transfer Team's Lambda") — how does the system handle cross-team context? Does it pull context for both teams? Show the code.

**Q41.** Does the system know the relationships and dependencies between teams? For example: "File Transfer Team's Lambda depends on Networking Team's VPC config, which depends on Jenkins Team's deployment pipeline." Can it reason about downstream impact? Show where these relationships are defined.

**Q42.** When the user doesn't specify a team, how does the system determine which team's context to load? Does it ask, infer from content, load all teams, or default? Show the logic.

---

## SECTION 7: RESPONSE QUALITY & NATURALNESS

**Q43.** Does any response go through a post-processing layer before reaching the user that:
- a) Checks for hallucinations or unsupported claims against retrieved context
- b) Formats the response consistently (markdown, bullet points, code blocks)
- c) Adapts technical depth based on who is asking (engineer vs executive)
- d) Adds citations/references to data sources (e.g., "Based on your CloudWatch logs from 14:02 today...")
- e) None of the above
- Show the code.

**Q44.** Is there any output validation — a lightweight "critic" prompt that checks: "Does this response actually answer the question? Is it consistent with the context? Does it contain claims not supported by retrieved data?"

**Q45.** What happens when the user asks something the system genuinely doesn't know? Does the agent:
- a) Hallucinate a plausible-sounding answer
- b) Say "I don't have that information" and stop
- c) Say "I don't have that information, but here's what I do know that might help"
- d) Suggest where to find the answer or escalate to a human
- Show the code that handles this.

**Q46.** Does the system maintain conversation persona consistency? If the user talks to the Troubleshooting Agent then switches to the Cost Agent mid-conversation, does it feel like the same platform with shared context, or like starting fresh?

**Q47.** Can the user correct the agent mid-conversation? For example: "No, I didn't mean that Lambda, I meant the SFTP ingestion one" — does the agent correctly update its understanding and re-answer, or does it get confused? Show how corrections are handled.

**Q48.** Does the agent proactively ask clarifying questions when a query is ambiguous, or does it always attempt an answer regardless? Which behavior is currently configured?

**Q49.** Does the agent remember user preferences within a session? For example: "Give me answers in bullet points only" — does it maintain that preference for the rest of the conversation?

**Q50.** Is streaming response implemented? Do users see tokens appearing progressively as the agent responds, or do they wait for the full response before anything appears? This has the biggest single impact on perceived intelligence and responsiveness.

---

## SECTION 8: RELIABILITY & ROBUSTNESS

**Q51.** Does the system log every agent decision, tool call, and response for debugging and quality improvement? If yes, where and in what format? If no, this needs to be added urgently.

**Q52.** Is there any retry logic at the Bedrock API level? If a Bedrock call fails or times out, does it retry automatically?

**Q53.** What is the current error handling strategy at the top level? If something crashes deep in an agent loop, what does the user see? Show the top-level error handler.

**Q54.** Is there any circuit breaker pattern implemented? For example, if CloudWatch API fails 3 times in a row, does the system stop trying and serve a cached/degraded response?

---

## SECTION 9: EVALUATION & CONTINUOUS IMPROVEMENT

**Q55.** How do you currently measure whether agent responses are good or bad? Is there any:
- a) User feedback mechanism (thumbs up/down, rating)
- b) Automated evaluation using a separate LLM to score responses
- c) AgentCore Evaluations (since you're on Bedrock)
- d) Nothing yet

**Q56.** Do you have a test suite of representative queries for each agent? For example, 20 questions the Troubleshooting Agent should correctly answer — so you can regression-test improvements without manually testing everything?

**Q57.** When you update a team's markdown context file, is there a process to verify agents still answer correctly? Or could a context update silently break existing functionality?

**Q58.** Is there any A/B testing or prompt versioning in place? If you change a system prompt, can you compare the new version against the old one systematically?

---

## SECTION 10: ARCHITECTURE & SCALABILITY

**Q59.** Show me the complete architecture diagram or describe the full system architecture:
- Frontend → Backend API → Orchestrator → Specialized Agents → Tools
- Where does each component run? (Lambda, ECS, API Gateway, etc.)
- How is each component invoked?
- What are the latency characteristics of each hop?

**Q60.** What is the current average end-to-end response time from user message to agent response? Break it down by: orchestrator routing time, context retrieval time, Bedrock call time, tool call time, response formatting time.

**Q61.** What happens if two users from different teams ask questions simultaneously? Is there any session isolation, or could context from one session leak into another?

**Q62.** Is the system currently deployed and running, or still in local/development testing? What is the deployment target?

**Q63.** Are there any hardcoded values (team names, ARNs, bucket names, API endpoints) in the agent prompts or code that would break if the infrastructure changes? Show examples if yes.

---

## SUMMARY: PRIORITY AREAS TO FOCUS ON

Once Copilot has answered all questions above, specifically ask it to confirm which of these critical gaps exist in the current codebase:

1. **Is intent routing using LLM-based classification or only keyword matching?**
2. **Is conversation history summarized before being passed to agents, or passed raw in full?**
3. **Is team context dynamically filtered per query, or is the entire markdown file passed?**
4. **Is there any cross-session (long-term) memory implemented?**
5. **Is there any response validation or hallucination checking before responses reach the user?**
6. **Is streaming response implemented?**
7. **Are agent system prompts dynamically constructed with team context injected, or static?**
8. **Is there any output formatting layer that makes responses consistent and human-readable?**
9. **Can the orchestrator route to multiple agents in parallel for complex queries?**
10. **Is there any cross-team relationship/dependency awareness?**

---

*Share all answers back once Copilot has reviewed the codebase. The answers will drive a prioritized improvement plan with specific code, prompt templates, and architectural changes.*
