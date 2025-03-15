# 📌 Function Testing Document for AWS SFTP Transfer Solution

## **3️⃣ Functionality Testing Strategy**
### **🔹 Testing Scope**
The goal of function testing is to validate:
- ✅ **End-to-End workflow execution** of the AWS SFTP Transfer Step Function.
- ✅ **Component-level behavior** (Step-by-step validation of Step Function states).
- ✅ **Failure handling and retries** (Ensuring system resilience and recovery).
- ✅ **Access control and security policies** (Ensuring proper IAM permissions).

**Key aspects being tested:**
- 🟢 **Successful file transfers** under normal conditions.
- 🔴 **Failures and error scenarios** (invalid credentials, network issues, permission errors).
- 🔄 **Retry logic** to recover from temporary failures.
- 📡 **Monitoring & alerting** using **CloudWatch and SNS notifications**.

---

## **4️⃣ Test Cases**
Below are the **detailed test cases** for the **SFTP Transfer Step Function**:

### **🔹 General Execution Scenarios**
| **Test Case ID** | **Scenario** | **Expected Outcome** | **Status** |
|----------------|------------|--------------------|------------|
| **TC-001** | ✅ File Transfer is successful | File is transferred, metadata updated, and logs recorded | 🔄 Pending |
| **TC-002** | ❌ Invalid SFTP Connector ID | Step fails with an error message and SNS notification is triggered | 🔄 Pending |
| **TC-003** | ❌ File does not exist in S3 | Transfer fails, logs error, and triggers SNS alert | 🔄 Pending |
| **TC-004** | ❌ File already exists at destination | Step function retries or logs failure | 🔄 Pending |
| **TC-005** | ✅ Multiple files transferred in parallel | Step function handles multiple files concurrently | 🔄 Pending |
| **TC-006** | ✅ Large file transfer ( > 5 GB ) | Step function processes file without timeout issues | 🔄 Pending |

---

### **🔹 Error Handling & Failure Recovery**
| **Test Case ID** | **Error Scenario** | **Handling Strategy** | **Expected Outcome** |
|----------------|--------------|------------------|--------------------|
| **TC-007** | ❌ SFTP Server is down | Step Function retries 3 times, then fails | SNS alert + CloudWatch log |
| **TC-008** | ❌ Network failure during transfer | Retry mechanism triggers | Transfer resumes on retry |
| **TC-009** | ❌ S3 bucket permissions missing | Step fails with `AccessDenied` error | Logs error + SNS notification |
| **TC-010** | ❌ IAM Role permissions incorrect | Step fails due to `Policy Denied` | Logs error + SNS notification |
| **TC-011** | ❌ Step Function times out | Step Function aborts transfer | Logs timeout error |
| **TC-012** | ❌ SNS notification failure | Logs error but does not stop execution | Alternative logging |
| **TC-013** | ❌ S3 delete operation fails | Logs error and does not delete file | Logs failure and retries if needed |

---

### **🔹 Security & Access Control Testing**
| **Test Case ID** | **Access Scenario** | **Expected Outcome** |
|----------------|----------------|----------------------|
| **TC-014** | ✅ Valid IAM Role permissions | All steps execute successfully |
| **TC-015** | ❌ IAM Role lacks `s3:GetObject` | Step fails with `AccessDenied` |
| **TC-016** | ❌ IAM Role lacks `s3:DeleteObject` | S3 cleanup step fails |
| **TC-017** | ❌ IAM Role lacks `transfer:StartFileTransfer` | SFTP transfer fails |
| **TC-018** | ❌ SNS Publish permission missing | Notification step fails |
| **TC-019** | ✅ Encryption key permissions are valid | Files decrypt successfully |

---

## **5️⃣ Test Execution Process**
### **🔹 Steps for Manual Testing**
1. **Upload a test file** to the **OUTBOUND** folder in **S3**.
2. **Monitor Step Function execution** via AWS Console.
3. **Validate**:
   - 🔄 Step transitions (**Success/Failure**).
   - 📜 Logs in **CloudWatch**.
   - 🗄️ **DynamoDB update** for metadata.
   - 🚨 **SNS alert** in case of failure.
4. **Verify retry logic**:
   - Introduce **failures intentionally** (remove IAM permissions, shutdown SFTP server).
   - Check if **retries are happening**.
   - Confirm that **failure notifications are sent**.

### **🔹 Steps for Automated Testing**
- Use **AWS SDK** to programmatically **trigger test events**.
- Implement **Lambda-based test scripts** for verifying:
  - **DynamoDB writes**.
  - **S3 object movements**.
  - **SFTP connection success/failures**.
- Create **CloudWatch Log Insights queries** to track:
  - Step Function execution logs.
  - File transfer success/failure rates.

---

## **6️⃣ Error Handling & Failure Recovery**
### **🔹 Error Handling Scenarios**
| **Error Type** | **Handling Strategy** |
|--------------|----------------------|
| **Invalid SFTP Connector ID** | Step fails, logs error, triggers SNS notification. |
| **File Not Found in S3** | Logs error, Step Function gracefully terminates. |
| **Transfer Timeout** | Step Function retries up to 3 times before marking failure. |
| **Network Failure** | Retries using **Exponential Backoff strategy**. |
| **Permission Denied (S3 Delete Fail)** | Logs error & alerts team via SNS. |

### **🔹 SNS Notification Format**
Each failure will trigger an **SNS email alert** with: