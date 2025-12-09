# Golden Paths User Feedback Workshop

**Date:** [Date not specified in transcript]  
**Time:** 17:07 - 17:35  
**Duration:** ~28 minutes

## Meeting Overview
Workshop session to gather feedback from stakeholders on AWS Golden Paths and Infrastructure as Code (IaC) initiatives. Discussion focused on user feedback, pain points, and future direction for Golden Paths program.

---

## Attendees
- **DevOps Representatives:** Christos
- **SRE Representatives:** Joseph (volunteers/planning to join)
- **Team Members:** Martin, Stewart, Abdul, Aaron, Brian, Travis
- **Note:** Missing representation from Nimbus and some merchant-side teams

---

## Key Discussion Topics

### 1. EKS Service Catalogue & Golden Paths Strategy

**Context:**
- Request received for EKS in Stress Channel
- Question raised about whether to create unified Golden Paths vs. separate Issuer/Merchant-based paths

**Key Points:**
- EKS is heavily integrated with observability stack, Issuer camps, identity systems
- Historical approach: Creating single Golden Path for every product
- Challenge: Some products (like EFS) contain sub-modules that already have Golden Paths
- Risk of creating competing paths

**Decision Discussion:**
- **Option A:** Create generic, well-defined Golden Path that all teams could use
  - Risk: Issuer won't adopt it because they have their own solutions
- **Option B:** Create Issuer and Merchant-based Golden Paths where appropriate
- **Proposed Solution:** Use composites approach
  - Create atomic paths as building blocks
  - Build composites (like EFS composite) that use atomic components
  - Allows consumption similar to service catalogue products

**Action Items:**
- Need to finalize decision on Golden Paths approach
- Consider split between Issuer and Merchant teams

---

### 2. Positive Feedback Received

**What's Working Well:**
- ✅ Collateral and documentation structure
- ✅ Governance around closing controls and releases
- ✅ Overall approach and time invested in building the framework
- ✅ Validation of the team's methodology

---

### 3. Pain Points & Areas for Improvement

#### A. Version Management & Tracking

**Issues Reported:**
- Difficulty tracking versions across installations
- Understanding upgrade paths
- Knowing which versions of atomics are supported in composites
- Lack of clear versioning documentation

**Root Causes:**
- Some Golden Paths didn't work due to specific circumstances (e.g., required features enabled in specific shared accounts, missing IAM roles)
- Testing gaps before standardization work began

**Solutions Implemented:**
- Added Terraform native tests to almost every Golden Path
- Using agentic creator for tests
- Cannot catch all issues without deploying to shared accounts with specific feature flags

**Planned Improvements:**
- Release pipeline will run tests and examples - won't release if tests fail
- PR pipeline will provide immediate feedback when raising PRs
- **Note:** Most infrastructure runs Terraform 1.3, but upgrade work planned for new year to close testing gap

#### B. Avoidable Release Issues

**Problems:**
- Some broken releases were avoidable
- Missing dependencies in documentation
- Examples not properly tested before release

**Solution:**
- Implement discipline to ensure all examples plan properly before release
- Automated testing in release pipeline
- Pre-release validation through PR pipelines

---

### 4. Service Catalogue vs. Golden Paths

**Key Question:** How do Service Catalogue and Golden Paths play together? Will they converge?

**Discussion Points:**
- Need to determine relationship between the two approaches
- Question about continuing to develop both in parallel
- Requires broader discussion (noted as ongoing conversation)

---

### 5. Golden Paths Register

**Current State:**
- Register was adequate for initial needs but now outdated
- Not currently running
- Needs development for next phase

**Improvements Needed:**
- Better publishing and advertising of Golden Paths
- Update outdated information
- **Action:** Create user stories/tasks to update register

**Technical Details:**
- Current register shows contributors but information is incomplete
- Groups/individuals shown but context unclear
- Example shown: NSA/Averse Travel Blockchain with Golden Paths contributors
- Issue: Principal names don't provide clear ownership information

---

### 6. Module Ownership & Contribution Model

**Question Raised:** "If I want to change this module, do I just do it myself or do I need to ask someone?"

**Answer/Clarification:**
- **Code Owners model:** Everybody can propose changes to modules
- Changes must go through release pipelines with testing and code review
- Better to surface intent early when updating module rather than waiting for potential rejection

**Process:**
- Register and Code Owners work together
- Contributing.md document should guide contributors
- **Action:** Update Contributing.md if outdated
- Any team can be set as code owner for Golden Path (advantage of GitLab Cloud)

---

### 7. Observability & Monitoring

**Context:** How does monitoring fit with Golden Paths?

**ADR Decision (Architectural Decision Record):**
- Monitoring definitions should be alongside resources in paths
- Creating monitoring under resources (e.g., SLI-type metrics alongside WAF, ALB, Lambda resources)
- This was not the initial approach - team started with atomics first, now adding monitoring retrospectively

**Action Items:**
- Register this as an ADR if not already done
- Publicize the decision more widely
- Ensure new paths and updates to existing paths include monitoring definitions
- Check for monitoring when developing new paths or touching existing ones

---

### 8. Documentation Quality

**Feedback:** "README files could be more human-readable"

**Issues Identified:**
- READMEs are very technical (Terraform versions, AWS resources, parameters)
- Don't explain **what** the Golden Path is **for** or **how** to use it
- Lack human-readable context in headers
- New developers look at Golden Path, get confused, and give up

**Current Process:**
- Write Terraform code
- Run terraform-docs to generate technical documentation (inputs, outputs, dependencies)
- Don't spend time writing human-readable explanations

**Proposed Solution:**
- Use AI/agentic prompts to update headers with human-readable passages
- Add explanation of what the Golden Path does
- Include couple of sentences in requirements section
- Make this part of review process - verify headers are updated and valid
- Budget ~10 minutes per review to check documentation

**Action:** Make README improvements part of Golden Path module standards

---

### 9. GitHub Issues for Feature Requests & Bug Reports

**Proposal:** Enable GitHub Issues across Golden Path repositories

**Benefits:**
- Central place to report features and bugs
- Developers can upvote features (30+ upvotes indicates priority)
- Don't need to know owner or which Jira board to use
- Standardized issue templates (GitHub supports issue templates)
- Better visibility than current scattered approach (57 repositories to watch)

**Concerns:**
- Need guidelines on how to submit issues
- How to track and manage them
- Currently use Jira for work management and feature refinement
- Don't want to create work without proper structure

**Current Challenge:**
- Residential process: Need to know owner, then find correct Jira board
- Developer friction in reporting issues

**Decision:**
- Follow-up call needed to discuss implementation
- Need to define process before enabling
- Could feed into agentic automation for issue processing

**Timing:**
- Timely discussion as project comes to end of year
- Need to figure out new BAU (Business As Usual) approach
- Consider as part of 2026 planning

---

### 10. Version Reporting for Projects

**Request:** Ability to report on Golden Path versions used in projects

**Use Case:**
- Project delivers business outcomes
- Need to know: Where am I on current version of atomics?
- What do I need to upgrade?
- Which versions of Golden Paths am I using?
- Where are they out of date?

**Solution Already Developed:**
- Abdul has automation in place (needs to be committed and publicized)
- Goes through all current versions of modules and their state
- Can filter by specific team tags
- Shows where Golden Paths are out of date
- Currently outputs CSV
- Located in automation repo

**Action:**
- Commit and publicize the solution
- Expose function to other teams who may have similar needs

---

### 11. Testing Improvements

**Two-Part Action:**

#### Part 1: Code Testing
- Continue investment in Terraform tests
- Tests validate infrastructure code

#### Part 2: Functional Testing
- Need to add functional tests for code running inside Lambda functions
- Not just Terraform tests, but testing actual application code

**Implementation Considerations:**
- Could use same prompt or nested prompts
- Share same context window
- Avoid single 5,000-line prompt
- Make it easy for developers to run all tests with one command

---

### 12. Internal Developer Platform (IDP)

**Context:** How to better advertise Golden Paths to developers

**Current Challenge:**
- Documentation used to be on front page of Golden Paths repo
- Now it's more hidden, making it harder for new developers
- Developer who started last week would struggle to know what's available

**Potential Solution:**
- Investigate modular UI3 or similar solutions
- Private Terraform module registry approach
- Could replicate current functionality in more accessible way
- Would need some migration work but worth investigating

**Broader Vision:**
- Internal Developer Platform (IDP) would be the next phase
- Single source for:
  - Documentation
  - Consumption
  - Hosting
  - Sourcing Golden Paths
- This was always planned as follow-on to initial Golden Path content creation

**2026 Planning:**
- Need discussion about what happens next with Golden Paths
- Wave initiatives come to an end
- Will require discussion between Issuer and Merchant teams globally
- Not just one discussion - will need separate conversations for different contexts

**Short-term Action:**
- Need to sort out entry point to current Golden Paths
- Make it simpler for developers to get started

---

### 13. Enforcement & Migration to Golden Paths

**Question Raised:** How do we enforce usage of Golden Paths? Move teams from old ways to new ways?

**Examples:**
- Network firewall still being done "the old way"
- Teams writing CAT rules directly instead of using Golden Path modules
- Some teams (like Nimbus) have already migrated to new Golden Path approach

**Considerations:**
- Easier to adopt for new flows vs. migrating existing implementations
- Blocking PRs to enforce Golden Path usage?
- Technical debt accumulates if migration delayed
- ADR (Architectural Decision Record) exists on migration process

**Approaches:**
- Run Cloud demo days on new ways of working
- Raise awareness of migration processes
- Build critical mass of teams using new approach
- Some forced migration: Old modules deleted from modules repo

**Current Status:**
- Golden Paths feel ready for prime time operationally
- Need to push adoption and get critical mass
- Some people already don't have choice (old modules deleted)
- Need to "sell" the new way of working to teams

**Action:**
- Consider PR automation to check Golden Path usage
- Provide feedback on pull requests about Golden Path adoption
- Potentially tie into Abdul's version reporting work

---

### 14. Missing Stakeholder Feedback

**Observation:**
- Workshop intended to find out what stakeholders want next
- Got lots of continuous improvement items (good outcomes)
- **But:** Didn't get much feedback on:
  - "I actually need an X solution for Y"
  - "You don't have a Golden Path for Z and I need it"
- Only concrete request: MSK Kafka and service catalogue migration items

**Context:**
- Missing representation from some teams (Nimbus, SRE, merchant-side)
- Need broader participation in next workshop

**Action for Next Time:**
- Push to get more participation from different parts of business
- Depending on organizational structure post-split, invite more merchant-side teams

---

## Action Items Summary

| # | Action | Owner | Priority | Status |
|---|--------|-------|----------|--------|
| 1 | Create user stories for register updates | [To be assigned] | High | Pending |
| 2 | Commit and publicize Abdul's version reporting automation | Abdul | High | In Progress |
| 3 | Schedule follow-up call on GitHub Issues implementation | [To be assigned] | Medium | Pending |
| 4 | Update Contributing.md documentation | [To be assigned] | Medium | Pending |
| 5 | Add human-readable headers to all Golden Path READMEs | Team | Medium | Pending |
| 6 | Register monitoring-in-paths as ADR if not already done | [To be assigned] | Medium | Pending |
| 7 | Develop functional tests for Lambda code (in addition to Terraform tests) | [To be assigned] | Medium | Pending |
| 8 | Investigate modular UI3 or similar IDP solutions | [To be assigned] | Low | Future |
| 9 | Consider PR automation to check Golden Path usage | [To be assigned] | Low | Future |
| 10 | Plan broader 2026 Golden Paths strategy discussion | Leadership | High | Q1 2026 |
| 11 | Schedule next user feedback workshop with broader stakeholder representation | [To be assigned] | Medium | Future |

---

## Key Decisions Made

1. **Composites over Competing Paths:** Use atomic Golden Paths as building blocks to create composites, rather than creating multiple competing implementations
2. **Monitoring Alongside Resources:** Monitoring definitions should live with the resources in Golden Paths (ADR to be formalized)
3. **Code Owners Model Confirmed:** Anyone can propose changes; changes go through testing and review pipelines
4. **Issues Discussion Deferred:** GitHub Issues enablement needs separate discussion with proper process design

---

## Key Metrics & Numbers

- **57** repositories to watch currently
- **~28 minutes** meeting duration
- **Terraform 1.3** - version most infrastructure currently runs on
- **Target:** Upgrade to newer Terraform version in new year
- **Current:** Almost every Golden Path now has Terraform native tests

---

## Future Considerations

### Short-term (Q4 2024 / Q1 2025)
- Complete version reporting tool
- Update register and documentation
- Improve README quality
- Implement automated testing in PR/release pipelines

### Medium-term (H1 2025)
- Resolve GitHub Issues process
- Complete Terraform upgrades across infrastructure
- Expand functional testing coverage
- Broaden stakeholder engagement

### Long-term (2026+)
- Internal Developer Platform (IDP) implementation
- Post-split Golden Paths strategy (Issuer vs. Merchant)
- Enforce/encourage Golden Path adoption across all teams
- Migrate legacy implementations to Golden Paths

---

## Open Questions

1. What is the final decision on Issuer vs. Merchant-based Golden Paths vs. unified approach?
2. How will Golden Paths program continue after Wave initiatives end?
3. What is the process for GitHub Issues implementation?
4. How do we handle enforcement vs. encouragement for Golden Path adoption?
5. What specific new Golden Paths are needed (beyond MSK/Kafka)?

---

## Related Documentation

- Golden Paths register (currently outdated, needs update)
- Contributing.md (needs review and update)
- ADR on monitoring approach (to be confirmed/published)
- ADR on network firewall migration (exists)
- Service Catalogue documentation

---

## Meeting Feedback

**What Went Well:**
- Good representation from DevOps and SRE volunteers
- Validated current approach
- Identified concrete improvement areas

**What Could Be Better:**
- Missing some key stakeholder groups (Nimbus, broader merchant representation)
- Didn't get as many "new Golden Path" requests as expected
- Could use more concrete feature requests vs. continuous improvement items

**Next Workshop Improvements:**
- Broader invitation list
- More focused questions on missing capabilities
- Earlier engagement with underrepresented teams

---

## Notes

- Meeting ran slightly over time (~5 minutes)
- Technical issues with screen sharing during meeting
- High engagement and collaborative discussion
- Team is "already working on the big things" - validation of current priorities
- Golden Paths feel "ready for prime time" from operational perspective

---

## Glossary

- **ADR:** Architectural Decision Record
- **BAU:** Business As Usual
- **EKS:** Elastic Kubernetes Service (AWS)
- **EFS:** Elastic File System (AWS)
- **Golden Path:** Standardized, opinionated infrastructure-as-code module
- **IaC:** Infrastructure as Code
- **IDP:** Internal Developer Platform
- **MSK:** Managed Streaming for Kafka (AWS)
- **SRE:** Site Reliability Engineering
- **WAF:** Web Application Firewall
- **ALB:** Application Load Balancer
- **SLI:** Service Level Indicator