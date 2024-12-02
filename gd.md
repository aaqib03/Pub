# GuardDuty Malware Protection - Transfer Service Offering

## Introduction
This document provides a comprehensive guide to implement GuardDuty (GD) malware protection in the **Standard Transfer Service Offering**. The system uses **Lambda v13** (part of **Module v3**) to enable scanning capabilities for uploaded files. The process leverages two regional S3 buckets:
- **`gd_scanning` bucket**: For GuardDuty to scan files.
- **`malware_s3` bucket**: To store files flagged as containing malware (`THREATS_FOUND`).

These buckets are shared across multiple clients within the same region. The scanning process relies on tags applied by GuardDuty after scanning, and only files with a specific action (`malware2`) in the **DynamoDB Transmission Matrix** are processed.

---

## Tags Applied by GuardDuty
After scanning, GuardDuty applies the following tags to files:

- **NO_THREATS_FOUND**: File is clean and routed to the consumer bucket.
- **THREATS_FOUND**: File contains malware and is routed to the `malware_s3` bucket.
- **UNSUPPORTED**: File type is not supported for scanning; quarantined in the source bucket.
- **ACCESS_DENIED**: GuardDuty could not access the file; quarantined in the source bucket.
- **FAILED**: Scanning encountered an error; quarantined in the source bucket.

---

## Process Flow

1. **File Reception**:
   - Files are uploaded to the external files bucket in encrypted form.

2. **Lambda Processing**:
   - Lambda v13 decrypts the file and temporarily stores it in `/tmp`.
   - The decrypted file is uploaded to the `gd_scanning` bucket.

3. **GuardDuty Scanning**:
   - GuardDuty scans the file and applies a tag.
   - Tags include `NO_THREATS_FOUND`, `THREATS_FOUND`, `UNSUPPORTED`, `ACCESS_DENIED`, or `FAILED`.

4. **File Routing**:
   - **NO_THREATS_FOUND**: File is routed to the consumer bucket.
   - **THREATS_FOUND**: File is moved to the `malware_s3` bucket.
   - **Other Tags**: File is quarantined in the source bucket.

5. **Post-Processing**:
   - Temporary files in Lambda are deleted to optimize runtime space.

---

## Implementation Steps

### Prerequisites
1. **Lambda v13**:
   - Ensure the Lambda function is updated to version 13 from Module v3.
2. **Environment Variables**:
   - `GD_SCANNING_BUCKET`: S3 bucket for scanning.
   - `MALWARE_S3_BUCKET`: S3 bucket for storing threat files.
   - `ENABLE_SCANNING`: Boolean (`true`/`false`) to enable/disable scanning.
   - `POLLING_INTERVAL`: Time (seconds) for Lambda to wait for GuardDuty tags.
3. **DynamoDB Transmission Matrix**:
   - The `malware2` action must be present for files to be processed.

### Steps to Set Up
1. **Create S3 Buckets**:
   - `gd_scanning`: For GuardDuty scanning.
   - `malware_s3`: For storing flagged files.

2. **Configure Lambda**:
   - Deploy Lambda v13.
   - Set the environment variables.

3. **Update DynamoDB Transmission Matrix**:
   - Add `malware2` as the set action for applicable file patterns.

4. **Testing**:
   - Upload test files and verify processing and routing.

5. **Monitoring**:
   - Enable CloudWatch Logs to monitor processing.
   - Export GuardDuty findings for centralized threat management.

---

## Technical Architecture Diagram

Below is the technical architecture diagram illustrating the process flow for GuardDuty malware protection.

![Technical Architecture Diagram](./path/to/your/image.png)

> Replace `./path/to/your/image.png` with the actual path or URL of your image file.

---

## Troubleshooting
1. **Files not processed**:
   - Ensure `ENABLE_SCANNING` is set to `true`.
   - Check the `POLLING_INTERVAL` value.

2. **Tags not applied**:
   - Ensure file types are supported by GuardDuty.
   - Verify GuardDuty is enabled in the region.

3. **Incorrect Routing**:
   - Check DynamoDB matrix configuration.
   - Verify S3 bucket policies and permissions.

---

This document provides all necessary details for setting up, managing, and troubleshooting GuardDuty malware protection in the Standard Transfer Service.