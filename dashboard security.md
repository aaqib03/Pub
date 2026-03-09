I can see your architecture diagram clearly. Let me read the SKILL.md file first to create the best possible document, then build it based exactly on what you've drawn.

Let me create a rich, detailed HTML document based on your exact architecture diagram:

I'll create this as a polished HTML artifact with your exact flow and SVG architecture diagram:

```html
<!DOCTYPE html>
<html>
```

Here is the full document as a rendered artifact:

---

# Security Vulnerability Dashboard — AWS Architecture Document

*Based on your architecture diagram*

---

## Architecture Overview

Your diagram shows the following components inside an **AWS Account** with a **VPC**:

**Data Collection Layer (inside VPC):**
- **Snyk** → API call → **Snyk Reporter Lambda** (with IAM role) → stores vulnerability data → **AWS S3**
- **Wiz** → API call → **Wiz Reporter Lambda** (with IAM role) → stores vulnerability data → **AWS S3**
- **Amazon EventBridge** → scheduler that triggers both reporter lambdas on a schedule
- **Amazon SES** → sends email alerts to the **Team** when vulnerabilities are found

**Storage Layer:**
- **AWS S3** stores versioned HTML + JSON files (the `enhanced-dashboard.html` and vulnerability data)

**Serving Layer (inside VPC):**
- **Dashboard Viewer Lambda** (with IAM role) → reads from S3 → serves the dashboard HTML

**Access & Security Layer (outside VPC, public-facing):**
- **Amazon API Gateway** → receives requests from CloudFront
- **Amazon CloudFront** → CDN + security layer, uses SSL certificate
- **Amazon Route 53** → DNS, routes `vulnerability.tech` to CloudFront
- **AWS WAF** → attached to CloudFront, blocks malicious traffic
- **AWS Certificate Manager (ACM)** → provides SSL/TLS certificate for HTTPS
- **AWS Secrets Manager** → securely stores API keys (Snyk token, Wiz token, etc.)

**End User:**
- User makes a `GET /` request → hits Route 53 → CloudFront → API Gateway → Dashboard Viewer Lambda → S3

---

## Detailed Request Flow

### Flow 1 — Data Collection (Scheduled)

```
EventBridge Scheduler (cron)
        |
        ├──► Snyk Reporter Lambda
        │         |
        │    1. Fetches Snyk API data (using token from Secrets Manager)
        │    2. Generates HTML + JSON report
        │    3. Saves to S3 (versioned)
        │    4. Calls SES to email team
        │
        └──► Wiz Reporter Lambda
                  |
             1. Fetches Wiz API data (using token from Secrets Manager)
             2. Stores vulnerability data to S3
```

### Flow 2 — Dashboard Access (User Request)

```
User Browser
     |
     ▼
Route 53 (vulnerability.tech)
     |
     ▼
Amazon CloudFront  ◄── WAF filters here (blocks bad traffic)
     |              ◄── ACM SSL certificate (HTTPS enforced)
     ▼
Amazon API Gateway (private)
     |
     ▼
Dashboard Viewer Lambda (inside VPC)
     |
     ▼
AWS S3 (reads latest enhanced-dashboard.html + JSON data)
     |
     ▼
Response returned to user browser
```

---

## Security Benefits

### 1. AWS WAF (Web Application Firewall)
Attached directly to CloudFront. Protects against SQL injection, cross-site scripting (XSS), bad bots, and allows you to set rate limiting rules so no single IP can flood your dashboard with requests.

### 2. Amazon CloudFront
Acts as the secure front door. All traffic passes through CloudFront before reaching your backend, meaning your API Gateway and Lambda are never directly exposed. CloudFront also enforces HTTPS and can be configured to block HTTP entirely.

### 3. AWS Certificate Manager (ACM)
Provides a free, auto-renewing SSL/TLS certificate for your custom domain. This ensures all data in transit between the user and CloudFront is encrypted — no manual certificate management needed.

### 4. AWS Secrets Manager
Your Snyk and Wiz API tokens are never hardcoded in Lambda environment variables. They are fetched securely at runtime from Secrets Manager, and access is controlled via IAM policies. If a token is rotated, you update it in one place.

### 5. IAM Roles (Least Privilege)
Each Lambda has its own IAM role with only the permissions it needs. The Snyk Reporter Lambda can only write to S3. The Dashboard Viewer Lambda can only read from S3. This limits the blast radius if any Lambda is ever compromised.

### 6. VPC Isolation
All Lambdas run inside a private VPC. They are not reachable from the internet directly. Only traffic that flows through CloudFront → API Gateway can reach the Dashboard Viewer Lambda.

### 7. Amazon Route 53
Provides DNS management for your custom domain with health checks. If your CloudFront distribution becomes unhealthy, Route 53 can failover automatically.

### 8. S3 Versioning
Your S3 bucket stores versioned HTML and JSON files. This means you can roll back to a previous version of the dashboard data if something goes wrong, and you have a full history of vulnerability reports over time.

### 9. Amazon SES (Email Alerts)
When the reporter Lambdas detect vulnerabilities, they send automated email alerts to your security team via SES, ensuring the right people are notified without delay.

### 10. AWS Shield Standard (Built-in with CloudFront)
Automatically applied to all CloudFront distributions at no extra cost. Provides always-on DDoS protection at the network and transport layers.

---

## Recommended Additional Security Controls

These are not in your current diagram but would further harden the architecture:

- **Amazon Cognito** — Add authentication so only team members with valid credentials can access the dashboard. Integrates with CloudFront via Lambda@Edge.
- **CloudTrail** — Enable AWS CloudTrail to log every API call made across your account, giving you a full audit trail.
- **GuardDuty** — Enable Amazon GuardDuty for intelligent threat detection across your VPC, Lambda, and S3 activity.
- **S3 Block Public Access** — Ensure the S3 bucket has "Block all public access" enabled so it can only be read by the Dashboard Viewer Lambda's IAM role.
- **VPC Flow Logs** — Enable VPC Flow Logs to monitor all network traffic in and out of your VPC for anomaly detection.

---

## Summary Table

| Component | Purpose | Security Benefit |
|---|---|---|
| Route 53 | DNS routing | Health checks, failover |
| CloudFront | CDN + front door | Origin protection, HTTPS, caching |
| AWS WAF | Traffic filtering | Blocks attacks, rate limiting |
| ACM | SSL certificates | Encrypted traffic, auto-renewal |
| API Gateway | Request routing | Private endpoint, not internet-exposed |
| Dashboard Viewer Lambda | Serve dashboard | Inside VPC, no public access |
| Snyk/Wiz Reporter Lambdas | Data collection | Private, IAM-scoped |
| AWS S3 | Storage | Versioned, private, IAM-controlled |
| Secrets Manager | API key storage | No hardcoded credentials |
| EventBridge | Scheduling | Automated, no manual triggers needed |
| SES | Email alerts | Proactive team notification |

---

This is a well-thought-out architecture. The main thing I'd recommend adding is **Cognito** for user authentication so the dashboard isn't accessible to just anyone who has the URL. Would you like me to expand on how to add that, or shall I produce this as a downloadable Word or PDF document?


Great question. CloudFront gives you several key benefits for your use case:

**Security** is the biggest one. CloudFront acts as a shield between the internet and your backend. All traffic hits CloudFront first, and you can attach AWS WAF to it to block SQL injection, XSS attacks, bad bots, and set rate limiting to prevent abuse. Your actual backend (ALB or API Gateway) never gets directly exposed.

**Custom domain + HTTPS** is seamless. You attach your ACM certificate to CloudFront and point your domain at it — that's how you get `vulnerability.tech` working with proper SSL/TLS without managing certificates yourself.

**DDoS protection** comes built-in for free via AWS Shield Standard, which is automatically applied to all CloudFront distributions.

**Origin protection** is another big one. You configure CloudFront so that your ALB or VPC endpoint only accepts requests that come through CloudFront — meaning even if someone discovers your backend URL directly, they can't bypass CloudFront and hit it raw.

**Caching** can speed up your dashboard significantly. Static assets like your HTML, JS, and CSS from S3 can be cached at CloudFront edge locations globally, so users get fast load times without hitting your backend every time.

**Access control** integrates nicely — you can add Cognito authentication at the CloudFront layer so unauthenticated users get blocked before they even reach your Lambda or ALB.

In short, for your architecture, CloudFront is essentially the secure front door to your entire application — everything sits safely behind it.