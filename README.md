# **Solution Design Document: SFTP File Transfer Workflow using AWS Step Functions**

---

## **1. Introduction**
This document provides a detailed solution design for the **SFTP File Transfer Workflow** implemented using **AWS Step Functions**, **Lambda**, **DynamoDB**, **SNS**, and **S3**. It outlines the architecture, functionality, security model, failure handling, and future improvements.

---

## **2. Overview**
The SFTP File Transfer Workflow is designed to automate file transfers from an **Amazon S3 bucket** to an **SFTP destination** using AWS Transfer Family. The workflow ensures:
- Secure **event-driven execution** triggered by file uploads.
- **Automated retrieval of SFTP details** from **DynamoDB**.
- **File transfer monitoring** and **failure handling** via AWS Step Functions.
- **Robust error notifications** using **Amazon SNS**.

---

## **3. Architecture Diagram**
*(You can create a diagram using tools like Draw.io, Lucidchart, or Mermaid.js.)*

### **3.1 Components & Purpose**

| **Component**  | **Purpose** |
|--------------|------------|
| **Amazon S3** | Source bucket for file uploads (OUTBOUND folder monitored via EventBridge) |
| **EventBridge** | Detects new file uploads and triggers Step Functions |
| **AWS Step Functions** | Orchestrates the workflow for fetching details, initiating transfer, monitoring status, and handling failures |
| **AWS Lambda Functions** | Performs business logic at each step (retrieving details, initiating transfer, monitoring status, deleting files) |
| **AWS Transfer Family (SFTP Connector)** | Transfers files from S3 to the configured SFTP destination |
| **Amazon DynamoDB** | Stores metadata (SFTP credentials, connection IDs, destinations) |
| **Amazon SNS** | Sends failure notifications to teams via email |
| **IAM Roles & Policies** | Ensures secure access between services |

---

## **4. Detailed Workflow**
### **Step 1: File Upload & Trigger**
- **Trigger:** A file is uploaded to the `OUTBOUND` folder in S3.
- **EventBridge Rule:** Detects the new file and invokes **AWS Step Functions**.

### **Step 2: Retrieve SFTP Connection Details**
- **Lambda:** Fetches SFTP connection details from **DynamoDB**.
- **Output:** Returns `connector_id`, `destination_path`, `SFTP user`, and `Bucket ID`.

### **Step 3: Initiate SFTP File Transfer**
- **Lambda:** Calls AWS Transfer Family API using `connector_id` to move the file to SFTP.
- **Parameters Passed:** `bucket_name`, `file_key`, `connector_id`, `destination_path`.
- **Output:** Generates a `transfer_id`.

### **Step 4: Store Transfer Details & Wait for Completion**
- **Lambda:** Stores `transfer_id` in **DynamoDB**.
- **Wait for Transfer Completion:** The state machine waits for a signal on completion.

### **Step 5: Evaluate Transfer Status**
- **Lambda:** Queries transfer completion status.
- **If Success:** Proceed to file deletion.
- **If Failed:** Trigger failure notification.

### **Step 6: Delete Original File from S3**
- **Lambda:** Deletes the transferred file from S3.
- **If Error:** Capture failure and trigger **SNS Notification**.

### **Step 7: Send Failure Notification**
- **SNS Topic:** Notifies the team via email with details of the failed step.

---

## **5. Security Model**
### **5.1 IAM Roles & Policies**
- **Least Privilege Principle:** Each Lambda has minimal permissions.
- **IAM Policies:**
  - **Lambda**: Access to **S3**, **DynamoDB**, **SNS**, **Transfer API**.
  - **Step Functions**: Invoke Lambda, write logs.
  - **SNS**: Allow publish permissions to Step Functions.

### **5.2 Data Protection**
- **S3 KMS Encryption**: Protects files at rest.
- **IAM Role Assumption**: Ensures only authorized services access SFTP credentials.
- **DynamoDB Encryption**: Protects stored SFTP metadata.

### **5.3 Audit & Monitoring**
- **CloudTrail Logs:** Monitors access to AWS services.
- **CloudWatch Logs:** Captures execution details, errors, and performance logs.

---

## **6. Stability Considerations**
- **Scalability:** Handles multiple files using parallel Step Function executions.
- **Concurrency:** AWS Step Functions ensures parallel execution without conflicts.
- **Execution Timeout:** Defined at the step level to prevent stuck executions.
- **Error Logging:** All failures are captured in **CloudWatch Logs** for debugging.

---

## **7. Failure Handling & Retries**

| **Step**  | **Failure Scenario** | **Current Handling** | **Future Improvements** |
|-----------|---------------------|----------------------|-------------------------|
| **Retrieve SFTP Details** | DynamoDB timeout/error | Retry mechanism using Step Functions built-in retry | Add a fallback to default credentials |
| **Initiate SFTP Transfer** | Invalid SFTP credentials | Log failure and trigger SNS alert | Implement a second SFTP retry |
| **Monitor Transfer Status** | API timeout | Retry for a defined period | Implement a dead-letter queue (DLQ) |
| **Delete Original File** | IAM permission denied | Log failure and trigger SNS alert | Implement IAM validation before deletion |

---

## **8. Assumptions & Constraints**
### **8.1 Assumptions**
1. The **SFTP connector** is pre-configured with correct host key and credentials.
2. The **DynamoDB table** stores valid `connector_id` and `destination_path`.
3. Files **always originate from S3** before transfer.
4. **EventBridge correctly triggers Step Functions** for each file.

### **8.2 Constraints**
1. **File Size Limitations**:
   - AWS Lambda has a 6MB synchronous response limit.
   - AWS Transfer API supports up to **5GB** for direct transfers.
   
2. **Execution Time Limits**:
   - Step Functions **Standard Workflow** is used to support long-running jobs.
   
3. **Error Handling Dependencies**:
   - If AWS Transfer API fails, the system currently **does not retry automatically**.

---

## **9. Future Enhancements**
### **9.1 Implementing Automated