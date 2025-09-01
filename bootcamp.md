# AWS Networking Demo Notes

## VPC (Virtual Private Cloud)

- **Definition:** A private, isolated network in AWS where resources run.  
- **Problem it Solves:** Without isolation, resources in the cloud can be accidentally exposed. Need control over which servers are public vs private.  
- **CIDR (Classless Inter-Domain Routing):** Defines the IP address range of the VPC. Example: `10.0.0.0/16` → ~65,000 IPs. Must avoid overlaps.  
- **How VPC Helps:** Provides IP ranges, subnets, route tables, and gateways to structure the network.  
- **Example:**  
  - VPC: `10.0.0.0/16`  
  - Public Subnet: `10.0.1.0/24` for web servers  
  - Private Subnet: `10.0.2.0/24` for database  
  - IGW only attached to public subnet → secure architecture.

---

## Route 53 Resolver & VPC Router

### VPC Router
- Default, invisible router in every VPC.  
- Forwards traffic between subnets, IGW, NAT, VPN, etc.  
- Reads **Route Tables** to decide next hop.  

### Route 53 Resolver
- Built-in DNS resolver at **10.0.0.2**.  
- Resolves AWS services (`s3.amazonaws.com`), private hosted zones, and external domains.  
- Ensures workloads can resolve names to IPs without needing external DNS.

---

## Internet Gateway (IGW)

- A redundant gateway that connects VPC to internet.  
- Needed for public subnets to reach the internet.  
- Works with route tables (`0.0.0.0/0 → IGW`).  
- Example: Public EC2 web server with Elastic IP.

---

## Subnets

- Subdivisions of a VPC CIDR. Each subnet is tied to one **AZ**.  
- **Public Subnet:** Connected to IGW for internet-facing workloads.  
- **Private Subnet:** No IGW access, used for internal resources.  
- Example:  
  - VPC: `10.0.0.0/24`  
  - Public Subnet: `10.0.0.0/25`  
  - Private Subnet: `10.0.0.128/25`

---

## Route Tables

- A set of rules (Destination → Target) for directing traffic.  
- **Local routes** allow all subnets in a VPC to communicate.  
- Example Routes:  
  - Public Subnet: `0.0.0.0/0 → IGW`  
  - Private Subnet: `0.0.0.0/0 → NAT Gateway`  

---

## Route to Internet

- Public subnet needs a default route (`0.0.0.0/0 → IGW`) for internet access.  
- Without this, instances won’t reach the internet even if IGW is attached.  

---

## Internet Access – Compute in Public Subnet

- Requires:  
  1. Subnet route to IGW.  
  2. A public IP or Elastic IP.  
- IGW performs **1:1 NAT** between private and public IPs.  
- Example: EC2 `10.0.0.10` with Elastic IP `3.x.x.x`.

---

## Internet Access – Compute in Private Subnet

- Private subnets use **NAT Gateway** for outbound-only internet access.  
- NAT is deployed in a public subnet with an Elastic IP.  
- Route: `0.0.0.0/0 → NAT Gateway`.  
- Instances can pull updates, call APIs, but cannot be reached from internet.

---

## NAT Gateway – Key Concepts

- **Definition:** AWS-managed service enabling outbound internet from private subnets while blocking unsolicited inbound.  
- **How It Works:**  
  - Maintains stateful mappings of outbound connections.  
  - Only responses to existing connections are allowed back.  
  - Random inbound traffic is dropped.  
- **Highlights:**  
  - Fully managed, scalable, highly available.  
  - Deployed in public subnet with Elastic IP.

---

## Multiple Availability Zones (AZs)

- AZs = independent datacenters in a Region.  
- Deploy across multiple AZs for **High Availability, Fault Tolerance, and Disaster Recovery**.  
- Examples:  
  - RDS Multi-AZ → automatic failover.  
  - ALB + ASG → spread workloads across AZs.  
- Best Practice → Always deploy in at least 2 AZs.

---

## Access to AWS Services? (Problem)

- Private subnet workloads often need to access AWS services like **S3, Secrets Manager, KMS**.  
- AWS services expose **public APIs**.  
- Private subnets don’t have IGW or public IPs → cannot reach them directly.  
- Question: *How do private subnets talk to AWS services?*

---

## Access via VPC Endpoints (Solution)

- **VPC Endpoints** provide private connectivity between VPCs and AWS services.  
- **Traffic Flow:**  
  1. EC2 makes call → e.g., `s3.amazonaws.com`.  
  2. **Route 53 Resolver** (10.0.0.2) resolves DNS to endpoint IP.  
  3. **VPC Router** forwards traffic to endpoint.  
  4. **VPC Endpoint** securely connects to service within AWS backbone.  
- **Types:**  
  - **Gateway Endpoints** → S3, DynamoDB.  
  - **Interface Endpoints** → most other services (Secrets Manager, KMS, SSM).  
- **Benefit:** No NAT/IGW needed, traffic stays inside AWS, more secure and cheaper.

---

## Gateway Endpoints (S3/DynamoDB)

- Special endpoints for S3 and DynamoDB.  
- Added via **route table prefix lists**.  
- Even if DNS resolves to public IP, routing forces traffic through AWS private backbone.  
- Cheaper and efficient for high-volume traffic like S3.  

---

## Gateway Endpoints with DNS Resolution

- Query like `s3.eu-central-1.amazonaws.com` resolves to **public IPs**.  
- But route table prefix lists ensure traffic routes internally via Gateway Endpoint.  
- Key point → DNS resolves public IP, routing ensures traffic stays private.  

---

## Interface Endpoints (AWS PrivateLink)

- **What they are:** ENIs with private IPs in your subnets that proxy to AWS services.  
- **Why:** Allow private-subnet instances to call service APIs (Secrets Manager, KMS, etc.) without NAT/IGW.  
- **Traffic flow:**  
  1. App calls `secretsmanager.<region>.amazonaws.com`.  
  2. **Route 53 Resolver** → resolves to endpoint ENI IP (if Private DNS enabled).  
  3. **VPC Router** forwards traffic to local ENI.  
  4. ENI proxies traffic to AWS service via PrivateLink.  
- **Security:** Endpoint SGs, endpoint policies, per-AZ design for HA.  
- **Cost:** Pay per endpoint + data. Prefer Gateway Endpoint for S3/DynamoDB.

---

## Interface Endpoints – Deep Dive (Private DNS, IPs, ENIs)

- **Private DNS:**  
  - If enabled → standard AWS service hostnames (e.g., `secretsmanager.<region>.amazonaws.com`) resolve to the **private IPs of the endpoint ENIs** in your VPC.  
  - If disabled → hostnames resolve to **public IPs**; you must instead use the special endpoint-specific DNS name (`vpce-xxxx.vpce.amazonaws.com`) for private routing.  
  - *Enabling Private DNS makes the experience seamless – applications don’t need code/config changes.*  

- **Do endpoints have IPs?**  
  - **Gateway Endpoints (S3, DynamoDB):**  
    - Do not create IPs or ENIs.  
    - Use **prefix lists in route tables** to forward traffic to the service internally.  
  - **Interface Endpoints (all other services):**  
    - Do create **ENIs (Elastic Network Interfaces)** inside your subnets.  
    - Each ENI has a **private IP address**.  
    - Your traffic is routed to those ENIs → then forwarded to the AWS service via **PrivateLink**.  

- **What is an ENI (Elastic Network Interface)?**  
  - A virtual network card inside AWS.  
  - Belongs to a **subnet and AZ**.  
  - Has: private IP(s), optional public IP/EIP, one or more Security Groups, MAC address.  
  - Can be attached to an EC2 instance or owned by another AWS resource (like a VPC Endpoint).  

- **How traffic flows with Interface Endpoints:**  
  1. Instance calls AWS service API (e.g., Secrets Manager).  
  2. **Route 53 Resolver (10.0.0.2)** resolves the DNS → to the endpoint ENI’s private IP (if Private DNS enabled).  
  3. **VPC Router** routes packet locally to the ENI (no extra route needed).  
  4. ENI forwards traffic through **AWS PrivateLink** to the service.  
  5. Response returns via ENI → router → instance.  

- **Key Security & Design Points:**  
  - **Attach SGs** to endpoint ENIs to limit which clients can use the endpoint.  
  - **Endpoint Policy** to restrict service actions/resources.  
  - Place endpoints in **each AZ** to avoid cross-AZ traffic charges.  
  - Use **Gateway Endpoints** for S3/DynamoDB where possible (cost-effective).