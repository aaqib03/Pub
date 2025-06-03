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

CloudTrail	CloudWatch

Records API activity	Performance monitoring
Auditing & compliance	CPU, memory, logs
Tracks who did what	Real-time metrics


6. Placement Groups

Cluster: low latency, high throughput.

Spread: high availability.

Partition: large distributed systems.


7. S3 Storage Classes

Class	Use Case

Standard	Frequent access
Standard-IA	Infrequent access
One Zone-IA	Infrequent, non-critical
Glacier	Archive


8. AWS Auto Scaling

Target Tracking: maintain target metric.

Step Scaling: scale based on steps.


9. Route53 Failover vs Latency Routing

Failover: health check based.

Latency: routes to lowest latency region.


10. IAM Roles Cross-Account Access

AssumeRole + Trust policy.

Temporary creds via STS.

Controlled by IAM permissions.



---

AWS Security Services

1. AWS GuardDuty

Threat detection using VPC Flow Logs, DNS Logs, CloudTrail.


2. AWS Config

Monitors config changes, compliance enforcement.


3. AWS KMS

Encryption key management.

Envelope encryption.

Integrated across AWS services.


4. Secrets Manager vs Parameter Store

Secrets Manager	Parameter Store

Auto secret rotation	No auto-rotation
Higher cost	Cheaper
For credentials	General parameters



---

Terraform Fundamentals

1. Terraform State File

Tracks deployed infrastructure.

Use S3 + DynamoDB locking in prod.


2. terraform plan vs terraform apply

Plan: Preview changes.

Apply: Execute changes.


3. Providers vs Modules

Providers: Interface to clouds.

Modules: Reusable resource groups.


4. Terraform Taint

Forces resource recreation.


5. Terraform Drift

Infra state mismatch.

Detect via terraform refresh or terraform plan.


6. Dependency Graph

DAG based.

Ensures correct resource creation order.



---

DevOps / CI-CD / Monitoring

1. Infrastructure as Code (IaC)

Infra managed via code.

Benefits: automation, consistency, audit.


2. Blue-Green vs Rolling Deployment

Blue-Green	Rolling

New env first	Incremental updates
Easy rollback	Harder rollback
More infra temporarily	Less infra required


3. Prometheus

Pull-based metrics.

Exporters collect metrics.


4. Grafana

Visualization for metrics.

Supports multiple data sources.


5. CodePipeline Workflow

1. Source


2. Build


3. Test


4. Approval


5. Deploy


6. Post-deploy validation




---

Cloud Networking & Performance

1. Public IP vs Private IP vs Elastic IP

Type	Usage

Public IP	Temporary public
Private IP	Internal VPC
Elastic IP	Static public


2. VPC Peering

Private VPC connection.

Limitation: No transitive peering.


3. Provisioned IOPS vs GP3

Type	Use Case

GP3	General workloads
Provisioned IOPS	High-performance DBs


4. Bastion Host

Secure jump server for private instances.



---

Cloud Cost & Optimization

1. Savings Plan vs Reserved Instances vs Spot Instances

Option	Use Case

Savings Plan	Flexible commitment
Reserved Instance	Predictable workloads
Spot Instance	Short-lived tasks


2. Cost Optimization Techniques

Rightsizing.

Instance scheduler.

Intelligent-Tiering.

Delete unused resources.

Use Savings Plans.

Cost Explorer monitoring.



---

