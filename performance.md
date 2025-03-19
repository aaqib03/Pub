# 📌 AWS SFTP Transfer Workflow - Performance Testing Report

## **1️⃣ Overview**
### **🔹 Objective**
The goal of this performance test is to:
- ✅ Evaluate the scalability and efficiency of the **AWS SFTP Transfer Step Function**.
- ✅ Measure the system’s response to **various file sizes, transfer volumes, and concurrency**.
- ✅ Identify performance bottlenecks, latency issues, and failure rates.
- ✅ Validate system stability under **high-load conditions**.

### **🔹 Scope**
- 🚀 **Test different file sizes** (1MB, 10MB, 100MB, 1GB, 5GB, 10GB, 150GB).
- 🔄 **Simulate concurrent file transfers** (1 file, 10 files, 50 files, 100 files).
- 📊 **Capture CloudWatch metrics** to monitor **execution time, throughput, and failure rates**.

---

## **2️⃣ AWS Transfer Family Quotas and Expectations**
Understanding AWS Transfer Family quotas is essential for setting realistic performance expectations.

### **🔹 Key Quotas for SFTP Connectors**
| **Quota** | **Description** | **Limit** | **Adjustable** |
|-----------|-----------------|-----------|----------------|
| **Maximum File Size** | Largest individual file that can be transferred. | 150 GiB | No |
| **Maximum Throughput per Connector** | Combined bandwidth for all transfers per connector. | 50 MBps | No |
| **Concurrent Sessions per Connection** | Number of simultaneous SFTP sessions per connection. | 10 | No |
| **Concurrent Sessions per Server** | Total simultaneous sessions a server can handle. | 10,000 | No |
| **Pending File Transfer Queue Size** | Maximum number of pending file transfers per connector. | 1,000 | No |
| **StartFileTransfer Rate per Connector** | Maximum number of files that can be initiated for transfer per second per connector. | 100 files/sec | Yes |
| **Idle Connection Timeout** | Duration after which an inactive connection is terminated. | 1,800 seconds | No |
| **Maximum Transfer Time per File** | Maximum allowed time for a single file transfer. | 12 hours | No |
| **Maximum Request Wait Time per File** | Maximum time a transfer request can wait before processing. | 6 hours | No |

*Note: For detailed information, refer to the [AWS Transfer Family Endpoints and Quotas](https://docs.aws.amazon.com/general/latest/gr/transfer-service.html) and [AWS Transfer Family SFTP Connectors](https://docs.aws.amazon.com/transfer/latest/userguide/creating-connectors.html) documentation.*

---

## **3️⃣ Performance Testing Approach**
### **🔹 Test Strategy**
- **Run multiple test iterations** to capture realistic performance patterns.
- **Gradually increase file sizes and number of concurrent transfers**.
- **Introduce network failures, access issues, and large payloads** to test system resilience.
- **Monitor CloudWatch dashboards** for performance impact.

### **🔹 Test Environment**
| **Component** | **Details** |
|--------------|-------------|
| **AWS Region** | `eu-central-1` |
| **S3 Bucket** | `client-bucket-outbound` |
| **SFTP Connector** | `AWS Transfer Family` |
| **IAM Roles** | Configured with least privilege access |
| **Monitoring Tools** | AWS CloudWatch, AWS X-Ray, CloudWatch Logs Insights |

---

## **4️⃣ Performance Test Scenarios**
Below are the test cases covering different performance aspects.

### **🔸 Scenario 1: Single File Transfer (Baseline Test)**
📌 **Objective:** Measure baseline execution time for different file sizes.
| **Test ID** | **File Size** | **Expected Transfer Time** | **Result** |
|------------|---------------|----------------------------|------------|
| PT-001 | 1 MB | < 1 sec | 🔄 Pending |
| PT-002 | 10 MB | < 5 sec | 🔄 Pending |
| PT-003 | 100 MB | < 15 sec | 🔄 Pending |
| PT-004 | 1 GB | < 1 min | 🔄 Pending |
| PT-005 | 5 GB | < 3 min | 🔄 Pending |
| PT-006 | 10 GB | < 5 min | 🔄 Pending |
| PT-007 | 150 GB | < 2 hours | 🔄 Pending |

*Note: The expected transfer times are estimates and may vary based on network conditions and server performance.*

---

### **🔸 Scenario 2: High Volume File Transfers**
📌 **Objective:** Test **concurrent processing efficiency** by uploading multiple files simultaneously.
| **Test ID** | **Number of Files** | **Total Data Transferred** | **Expected Time** | **Result** |
|------------|----------------------|---------------------------|-------------------|------------|
| PT-008 | 10 | 1 GB | < 2 min | 🔄 Pending |
| PT-009 | 50 | 5 GB | < 10 min | 🔄 Pending |
| PT-010 | 100 | 10 GB | < 20 min | 🔄 Pending |

*Note: Ensure that the total number of pending requests does not exceed the maximum queue size of 1,000 per connector.*

---

### **🔸 Scenario 3: Failure & Retry Performance**
📌 **Objective:** **Simulate failures** and observe **retry behavior & latency impact**.
| **Test ID** | **Failure Type** | **Expected Behavior** | **Result** |
|------------|-------------------|-----------------------|------------|
| PT-011 | Network Timeout | Retries 3 times, then fails | 🔄 Pending |
| PT-012 | S3 Read Failure | Step fails, logs error | 🔄 Pending |
| PT-013 | Insufficient IAM Permissions | Step fails, logs AccessDenied | 🔄 Pending |
| PT-014 | SFTP Server Down | Step Function retries, then alerts | 🔄 Pending |

*Note: The system should handle failures gracefully and provide appropriate notifications.*

---

## **5️⃣ Execution & Monitoring**
### **🔹 How Tests Will Be Conducted**
1. **Setup:** Upload test files of different sizes into the **OUTBOUND S3 bucket**.
2. **Trigger Execution:** Start the **Step Function manually or via EventBridge**.
3. **Monitor Metrics:**
   - 📡 **Execution logs** in **CloudWatch Logs**.
   - 📊 **Performance dashboards** in **CloudWatch Metrics**.
   - 🚨 **Failure alerts** via **SNS Notifications**.
4. **Analyze Results:** Extract **CloudWatch reports, execution times, and failure logs**.

*Note: Ensure that the number of concurrent sessions does not exceed the limits set by AWS Transfer Family.*

---

## **6️⃣ Results & Analysis**
After executing the tests, we will **analyze the following**:
- ✅ **Maximum file size** the system can handle efficiently.
- ✅ **Threshold limits** before execution **times out or bottlenecks occur**.
- ✅ **Success vs failure rate** under different conditions.
- ✅ **System behavior under high loads** (scalability insights).

### **🔹0