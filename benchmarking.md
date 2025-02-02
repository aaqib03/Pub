
# Lambda Performance Testing Report

## 1. Introduction
The purpose of this report is to assess the performance, stability, and scalability of the Lambda function under different file sizes, memory configurations, and GuardDuty (GD) malware scanning conditions. The results will help improve product efficiency and provide insights for optimization.

---

## 2. Performance Metrics

### 2.1 Lambda V13 (GuardDuty Enabled)

| File Size (GB) | No. of Files | Max Memory (MB) | Memory Used (MB) | Time Taken per File (min) | Total Time (min) | Avg GD Scan Time (sec) | Files Transferred per Invocation | No. of Invocations | Comment                                   |
|----------------|--------------|------------------|------------------|----------------------------|------------------|-------------------------|----------------------------------|--------------------|-------------------------------------------|
| 1              | 5            | 2048             | 1200            | 0.82                       | 0.82             | 20                      | 1                                | 1                  | None                                      |
| 1              | 5            | 2048             | 1210            | 0.84                       | 4.2              | 20                      | 5                                | 1                  | None                                      |
| 2              | 1            | 2048             | 2048            | 1.61                       | 1.6              | 30                      | 1                                | 1                  | None                                      |
| 2              | 5            | 2048             | 2048            | 1.62                       | 8.1              | 30                      | 5                                | 1                  | None                                      |
| 3              | 1            | 2048             | 2048            | 2.96                       | 2.9              | 50                      | 1                                | 1                  | None                                      |
| 3              | 5            | 2048             | 2048            | 2.96                       | 10               | 50                      | 3                                | 2                  | Timeout while processing the 4th file      |
| 4              | 1            | 2048             | 2048            | 5.47                       | 5.4              | 60                      | 1                                | 1                  | None                                      |
| 5              | 1            | 2048             | 2048            | 6.72                       | 6.7              | 80                      | 1                                | 1                  | None                                      |
| 5              | 5            | 2048             | 2048            | 6.72                       | 10               | 80                      | 1                                | 5                  | Timeout after first file                   |

---

### 2.2 Lambda V12 (GuardDuty Disabled)

| File Size (GB) | Total Files | Max Memory (MB) | Memory Usage per Invocation (MB) | Time Taken per File (sec) | Total Time (sec) | Time Taken per File (min) | Files Transferred per Invocation | Invocations to Transfer All |
|----------------|-------------|------------------|----------------------------------|----------------------------|------------------|----------------------------|----------------------------------|-----------------------------|
| 1              | 1           | 2048             | 1197                            | 17.47                      | 17.47           | 0.29                       | 1                                | 1                           |
| 1              | 5           | 2048             | 1213                            | 16.287                     | 81.435          | 1.4                        | 5                                | 1                           |
| 2              | 1           | 2048             | 2048                            | 34.511                     | 34.511          | 0.6                        | 1                                | 1                           |
| 2              | 5           | 2048             | 2048                            | 34.3426                    | 171.713         | 2.9                        | 5                                | 1                           |
| 3              | 1           | 2048             | 2048                            | 73                         | 73              | 1.22                       | 1                                | 1                           |
| 3              | 5           | 2048             | 2048                            | 71.2792                    | 356.396         | 5.9                        | 5                                | 1                           |
| 4              | 1           | 2048             | 2048                            | 109.333                    | 108.998         | 1.82                       | 1                                | 1                           |
| 5              | 1           | 8192             | 3321                            | 51.91                      | 259.55          | 0.87                       | 5                                | 1                           |
| 5              | 5           | 8192             | 4385                            | 67.1466                    | 335.733         | 1.12                       | 5                                | 1                           |

---

## 3. Key Comparisons and Visuals

### 3.1 Processing Time Impact (GuardDuty Enabled vs. Disabled)

| File Size (GB) | Time Taken per File (GD Enabled) (min) | Time Taken per File (GD Disabled) (min) | % Increase in Time |
|----------------|-----------------------------------------|-------------------------------------------|--------------------|
| 1              | 0.82                                    | 0.29                                      | 182.8%             |
| 2              | 1.61                                    | 0.6                                       | 168.3%             |
| 3              | 2.96                                    | 1.22                                      | 142.6%             |
| 4              | 5.47                                    | 1.82                                      | 200.5%             |
| 5              | 6.72                                    | 1.55                                      | 333.5%             |

### 3.2 Visualization: Processing Time Comparison

Below is a bar chart illustrating the percentage increase in processing time due to GuardDuty scanning.

![Percentage Increase Chart](chart_placeholder)

---

## 4. Recommendations

1. **Optimize GuardDuty Scan Time**: Explore ways to reduce the scan time, possibly by optimizing I/O operations or using parallel scanning.
2. **Increase Timeout Limits**: For large files, consider increasing the Lambda timeout limit to avoid task failures.
3. **Adjust Memory Allocation**: Analyze the memory usage patterns to determine if higher memory allocation reduces processing time.
4. **Implement Asynchronous Processing**: For large workloads, consider breaking tasks into multiple asynchronous invocations.

---