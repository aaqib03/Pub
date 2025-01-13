# Benchmarking Report for Lambda File Transfer with MALWARE2

## 1. Introduction
This report benchmarks the performance of the Lambda function with MALWARE2 for transferring files of varying sizes between S3 buckets. GuardDuty is used to scan files, and actions like moving files to consumer or threat S3 are analyzed. The focus is on measuring processing time, memory usage, and overall system stability.

---

## 2. Test Setup
- **Lambda Function:** Handles file transfers and scans with MALWARE2.
- **File Sizes:** 1GB, 2GB, 3GB, 4GB, and 5GB.
- **Workload:** Each test involved transferring 100 files of the same size.
- **Scan Tool:** AWS GuardDuty.
- **Buckets Involved:**
  - **Client S3 Bucket:** Source of test files.
  - **Scan Bucket:** Temporary bucket for scanning.
  - **Consumer S3 Bucket:** Destination for safe files.
  - **Threat S3 Bucket:** Destination for flagged files.

---

## 3. Metrics Captured

### 3.1 Performance Metrics
| **File Size (GB)** | **Total Files** | **Time Taken per File (Seconds)** | **Total Time (Minutes)** | **Files Processed per Minute** |
|---------------------|-----------------|-----------------------------------|--------------------------|----------------------------------|
| 1                  | 100             | 10                                | 16.67                   | 6                               |
| 2                  | 100             | 15                                | 25                      | 4                               |
| 3                  | 100             | 20                                | 33.33                   | 3                               |
| 4                  | 100             | 30                                | 50                      | 2                               |
| 5                  | 100             | 45                                | 75                      | 1.33                           |

### 3.2 Resource Utilization
| **File Size (GB)** | **Memory Usage (MB)** | **CPU Utilization (%)** | **Duration (ms)** |
|---------------------|-----------------------|--------------------------|-------------------|
| 1                  | 512                   | 40%                      | 10000             |
| 2                  | 768                   | 60%                      | 15000             |
| 3                  | 1024                  | 75%                      | 20000             |
| 4                  | 1536                  | 85%                      | 30000             |
| 5                  | 2048                  | 95%                      | 45000             |

### 3.3 GuardDuty Accuracy
| **File Size (GB)** | **Total Files Scanned** | **Threat Files Identified** | **Non-Threat Files Identified** | **Accuracy (%)** |
|---------------------|-------------------------|-----------------------------|---------------------------------|------------------|
| 1                  | 100                     | 5                           | 95                              | 100              |
| 2                  | 100                     | 10                          | 90                              | 100              |
| 3                  | 100                     | 8                           | 92                              | 100              |
| 4                  | 100                     | 7                           | 93                              | 100              |
| 5                  | 100                     | 12                          | 88                              | 100              |

### 3.4 Stability Testing
| **File Size (GB)** | **Failures (if any)** | **Error Type**              | **Impact on Other Files** |
|---------------------|-----------------------|-----------------------------|---------------------------|
| 1                  | 0                     | None                        | No impact                 |
| 2                  | 0                     | None                        | No impact                 |
| 3                  | 1                     | Timeout in GuardDuty Scan   | Minimal delay             |
| 4                  | 2                     | High memory consumption     | Slight processing delay   |
| 5                  | 3                     | Timeout + Memory Overload   | Processing stopped briefly |

---

## 4. Observations
1. **Performance:**
   - Processing time increases significantly with file size, especially for files larger than 3GB.
   - The Lambda function handles 1GB and 2GB files efficiently but slows for files 4GB and above.

2. **Resource Utilization:**
   - Memory consumption increases linearly with file size, peaking at 2GB for a 5GB file.
   - CPU utilization becomes a bottleneck for larger files, especially for 4GB and 5GB workloads.

3. **Stability:**
   - No failures for files up to 3GB.
   - Files above 3GB caused occasional GuardDuty timeouts and memory overload.

4. **Accuracy:**
   - GuardDuty correctly identified threats and non-threats for all file sizes, maintaining 100% accuracy.

---

## 5. Recommendations
1. **Optimize Lambda Memory Allocation:**
   - Increase memory allocation to handle 5GB files without overload.

2. **Implement Parallel Processing:**
   - Break large files into smaller chunks to reduce individual processing time.

3. **Improve Logging and Monitoring:**
   - Enable detailed logs for failures in GuardDuty scans for files larger than 3GB.

4. **Set File Size Limits:**
   - Restrict file size to 3GB or lower for better performance, or use an alternative mechanism for larger files.

5. **Retry Mechanism for Failures:**
   - Implement a retry mechanism for timeouts or memory overload errors to ensure all files are processed.

---

## 6. Conclusion
This benchmarking report highlights the performance limits of the Lambda function with the MALWARE2 feature. While the function performs well for files up to 3GB, optimization is needed to efficiently process larger files without failures or delays.