# **Lambda Function Performance Testing**

## **1. Objective**
To evaluate the performance of the Lambda function when handling large file transfers (1 GB to 5 GB) under different conditions, capturing execution time, memory consumption, and error rates.

## **2. Scope**
- Measure **execution time, memory usage, CPU utilization**, and **error rates**.
- Evaluate **concurrency handling** and **latency variations**.
- Assess **stability under load**.

## **3. Test Scenarios & Metrics**

| **Test Case ID** | **Scenario** | **File Size(s)** | **Expected Transfer Time (sec)** | **Expected Memory Usage (MB)** | **Expected CPU Utilization (%)** | **Expected Error Rate (%)** |
|-------------|----------------|-------------|----------------|-------------------|--------------------|-------------------|
| TC-01 | Single file transfer | 1 GB - 5 GB | 5-30 sec | 512-1024 MB | < 50% | < 1% |
| TC-02 | Concurrent transfers (5 files simultaneously) | 1 GB each | 10-40 sec | 1024-2048 MB | 50-70% | < 3% |
| TC-03 | Mixed-size concurrent transfers | 1-5 GB files | 15-50 sec | 1024-3072 MB | 60-80% | < 5% |
| TC-04 | Stress test (multiple 5 GB files) | 5x 5 GB | 30-90 sec | 2048-4096 MB | 70-90% | 5-10% |
| TC-05 | File processing with decryption & unzipping | 3 GB (compressed) | 20-60 sec | 1536-3072 MB | 60-85% | < 5% |
| TC-06 | GuardDuty Malware Scan Integration | 4 GB | 10-40 sec | 1024-2048 MB | 50-75% | < 2% |

---

## **4. Test Environment**
- **AWS Lambda Configuration**:
  - Timeout: **900 sec**
  - Memory: **512 MB to 10 GB (adjustable)**
  - Concurrency: **10-50 requests**
- **S3 Buckets**:
  - **Source Bucket** → File Upload
  - **Scan Bucket** → GuardDuty Malware Scan
  - **Consumer Bucket** → Clean Files
  - **Malware Bucket** → Quarantined Files

---

# **Lambda Performance Test Report**

## **1. Summary**
- **Date:** [DD-MM-YYYY]  
- **Tested by:** [Your Name]  
- **Lambda Function Version:** [Version ID]  
- **AWS Region:** [Region]  
- **Overall Status:** [Pass/Fail]  
- **Total Files Tested:** [XX]  
- **Total Failed Transfers:** [XX]  
- **Average Transfer Time (per GB):** [XX sec]  
- **Maximum Memory Used:** [XX MB]  
- **Max CPU Utilization:** [XX%]  
- **Max Concurrent Requests Handled:** [XX]  
- **Error Rate:** [XX%]  

---

## **2. Detailed Test Results & Metrics**

| **Test Case ID** | **Scenario** | **File Size** | **Expected Time (sec)** | **Actual Time (sec)** | **Expected Memory (MB)** | **Actual Memory (MB)** | **CPU Utilization (%)** | **Error Rate (%)** | **Status** |
|-------------|----------------|-------------|----------------|----------------|-------------------|----------------|-----------------|--------------|--------|
| TC-01 | Single file transfer | 1 GB | 5-30 sec | 7.2 sec | 512-1024 MB | 900 MB | 42% | 0% | ✅ Pass |
| TC-02 | Concurrent transfers | 5x 1 GB | 10-40 sec | 15.5 sec | 1024-2048 MB | 1800 MB | 63% | 2% | ✅ Pass |
| TC-03 | Mixed-size concurrent transfers | 1-5 GB | 15-50 sec | 23.1 sec | 1024-3072 MB | 2500 MB | 72% | 4% | ⚠ Needs Optimization |
| TC-04 | Stress test | 5x 5 GB | 30-90 sec | 82.6 sec | 2048-4096 MB | 3700 MB | 89% | 9% | ❌ Fail |
| TC-05 | File processing with decryption | 3 GB | 20-60 sec | 35.4 sec | 1536-3072 MB | 2900 MB | 78% | 3% | ✅ Pass |
| TC-06 | GuardDuty Malware Scan | 4 GB | 10-40 sec | 18.7 sec | 1024-2048 MB | 1700 MB | 67% | 1% | ✅ Pass |

---

## **3. Observations & Recommendations**
- **Concurrency Issue:** Lambda struggles with **multiple 5 GB file transfers**.
  - 📌 **Recommendation:** Use **SQS or Step Functions** to **batch process** large files.
- **Memory Optimization:** High memory usage observed during decryption/unzipping.
  - 📌 **Recommendation:** **Increase Lambda memory** or **use multi-part uploads**.
- **Timeout Handling:** Some **large transfers exceed timeout limits**.
  - 📌 **Recommendation:** Optimize using **parallel chunk processing**.
- **GuardDuty Scan Performance:** Malware tagging performance is within acceptable limits.

---

## **4. Next Steps**
1. **Optimize memory allocation** based on the highest usage observed.
2. **Implement SQS queue handling** for large file batches.
3. **Re-test with different concurrency levels** to fine-tune performance.
4. **Monitor logs using AWS CloudWatch** for deeper insights into failure cases.

---

This test report will be updated after each performance run. 📊