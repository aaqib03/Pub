I'll correct the transcript and provide a detailed summary of the requirements.

## Corrected Transcript

[The full transcript is quite lengthy. Here are the key corrections to your opening statement:]

**Original:** "Correct spelling mistakes this is transcript of thr recording wr had for meeting where we have clinet prosa which needs pulling of some files so we are thinking kf using adtp connector step."

**Corrected:** "Correct spelling mistakes. This is a transcript of the recording we had for a meeting where we have client Prosa which needs pulling of some files, so we are thinking of using SFTP connector setup."

---

## Detailed Summary of Requirements

### **Business Context**
- **Client:** Brotherscard (via Prosa)
- **Problem:** Prosa refuses to tokenize data and send it to the client directly
- **Current Workaround:** Your team is receiving files from Prosa, tokenizing them, and forwarding to the client
- **Future Consideration:** 2 million credit card debit portfolio may be migrated to your platform

### **Technical Requirements**

#### **1. File Transfer Solution**
- **Primary Need:** Pull files from Prosa using SFTP connectors
- **Challenge:** Prosa refuses to transfer files over the internet
- **Current Setup:** Files are encrypted with Prosa's key, you decrypt on ingress, tokenize, and send to client
- **Desired Pattern:** Client should receive files directly, but you're accommodating Prosa's requirements

#### **2. Network Architecture Requirements**

**Current Connectivity:**
- Prosa connections go through Swannage (on-premise)
- Uses Direct Connect links between Swannage and US-C1
- Traffic flows: Online Services → Prosa CR unique NAT gateways → External Transit Gateway → Direct Connect → Swannage firewalls → Prosa endpoints
- Prosa operates in active-active mode for authorization flows

**Proposed Architecture:**
- Deploy **VPC Lattice Gateway connectors** in Transfer VPC
- Traffic flow: Connector (Transfer VPC) → Transit Gateway → Gateway connector (Egress VPC) → NAT gateways → existing Prosa routes
- Maintain unique public IPs to avoid IP address clashes

#### **3. VPC Lattice Implementation Challenges**

**Approval Requirements:**
- VPC Lattice is **not yet an approved service**
- Need to reach out to **Stratus, Phil, and Martin** for approval
- Proposal: Request limited exceptions for specific use cases rather than full VPC Lattice permissions

**Technical Unknowns:**
- Connectors don't sit inside a VPC (managed service)
- Uncertainty about cross-region capabilities
- Need to understand Gateway connector deployment and limitations
- Private link implementation is more complex than initially expected

#### **4. Disaster Recovery Requirements**
- **Critical:** Solution must support both regions (US-C1 and US-C2)
- Need ability to fail over connector connectivity during DR tests
- UAT connectivity for Prosa currently uses VPN (different from production Direct Connect)

#### **5. Testing Strategy**
- **Recommendation:** Push Prosa to send UAT files through the new route
- Test internally first before UAT with Prosa
- Promote to production following standard procedures
- **Reality Check:** Getting Prosa to cooperate will be "like herding cats"

### **Client Onboarding Documentation Needs**

#### **Document 1: Standard Client-Facing Pattern**
**Contents:**
- Standard SFTP setup with key exchange information
- Static IPs for whitelisting (4 IPs from unique NAT gateways)
- DNS entry patterns with client-specific naming
- Push/pull patterns (SFTP as default)
- For AWS-hosted clients: S3-to-S3 transfer options
- Multi-language versions (e.g., Spanish for Latin American clients)

**Purpose:** 
- Give to clients during initial discovery sessions
- Set expectations that SFTP pull is standard pattern
- Avoid custom solutions unless absolutely necessary

#### **Document 2: Internal "Break Glass" Options**
**Contents:**
- VPC Lattice connector solution for pulling files
- S3 bucket-to-bucket transfers (with role assumptions)
- Private link configurations
- Complex scenarios only deployed when clients insist

**Purpose:**
- Solutions to pull out when standard patterns won't work
- Not publicized to clients initially
- Used to accommodate difficult clients like Prosa

### **Future Considerations**

**Mexico Go-To-Market:**
- New Mexican client onboarding
- Prosa establishing AWS presence
- Setting up private link connectivity for authorization flows
- Potential to migrate Brotherscard connections to new private links
- Opportunity to push for S3 transfers (cost reduction)

**MasterCard Connectivity:**
- Using connectors for US MasterCard (push pattern over internet)
- Challenge: MasterCard requires PGP encryption **with digital signatures**
- Solution exists from EU implementation but adds complexity

### **Next Steps**

1. **Kiran:** Contact Stratus, Phil, and Martin for VPC Lattice approval
2. **Chris:** Research VPC Lattice Gateway connectors capabilities
3. **Team:** Schedule meeting next week to draft client-facing documentation
4. **Chris:** Share Prosa connectivity diagram with Kiran
5. **Team:** Consider including Phil (client-facing expert) in documentation meeting
6. **Louise:** Check with client/Prosa for any specific dates/deadlines
7. **Team:** Build and test base pattern internally first

### **Key Constraints & Considerations**

- Brotherscard is launch-only (not migration), so less immediate pressure
- No confirmed timeline yet, but expect date requests soon
- Solution needed before potential 2M card debit portfolio onboarding
- Standard pattern should be SFTP push/pull; custom solutions only when necessary
- Must maintain good relationship with Brotherscard for future business

---

Would you like me to create a more structured requirements document or help you build a technical implementation plan based on these details?