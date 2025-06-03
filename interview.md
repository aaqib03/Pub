DevOps Cloud Engineer Interview Prep (Q&A)


---

AWS Services — Core Understanding

1. Difference between EC2, ECS, EKS, and Lambda

Service	Description	When to Use

EC2	Virtual machine	Full control over server, legacy apps
ECS	Container orchestration (AWS proprietary)	Manage Docker containers easily
EKS	Kubernetes managed service	Use Kubernetes ecosystem
Lambda	Serverless compute	Event-driven, pay-per-use, no server mgmt


2. How VPC works in AWS

Isolated network in AWS.

Contains subnets (public/private), route tables, IGW, NAT Gateway.

Controls IP ranges, inbound/outbound traffic via NACLs and Security Groups.

Supports VPN and Direct Connect.


3. Security Group vs Network ACL

Security Group	NACL

Instance level	Subnet level
Stateful	Stateless
Allow rules only	Allow & deny rules
Auto return traffic	Manual return traffic


4. Load Balancer Types

ALB: HTTP/HTTPS, path-based & host-based routing.

NLB: TCP/UDP, high throughput.

CLB: Legacy, limited features.


5. CloudTrail vs CloudWatch

