# GuardDuty Malware Protection - Transfer Service Offering

## Introduction
This document provides a comprehensive guide to enable and implement GuardDuty (GD) malware protection in the **Standard Transfer Service Offering**. With the introduction of **Lambda v13** as part of **Module v3**, clients can enable scanning capabilities for uploaded files. This process uses two dedicated S3 buckets, `gd_scanning` and `malware_s3`, which are unique to each AWS region. Multiple clients in the same region share these buckets for scanning and storing threat files.

---

## Tag Definitions and Process Flow

### Tags Applied by GuardDuty
- **NO_THREATS_FOUND**: The file is clean and safe to process.
- **THREATS_FOUND**: The file contains malware and is flagged for further actions.
- **UNSUPPORTED**: The file type is not supported for scanning.
- **ACCESS_DENIED**: GuardDuty could not access the file for scanning.
- **FAILED**: The scanning process encountered an error.

### Process Flow
1. **Inbound File Handling**:
   - Files are uploaded via protocols such as SFTP, C:D, or S3-to-S3.
   - Encrypted files are placed in the external files bucket.

2. **File Processing**:
   - **Step 1**: The Lambda runtime is started.
   - **Step 2**: The encrypted file is copied from S3 to the local ephemeral storage (`/tmp`).
   - **Step 3**: The file is decrypted and temporarily stored in the Lambda runtime.

3. **Malware Scanning**:
   - **Step 4.1**: The decrypted file is uploaded to the `gd_scanning` bucket for GuardDuty scanning.
   - **Step 4.2**: The Lambda function waits (based on the `polling_interval` environment variable) for GuardDuty to apply a tag.
   - **Step 4.3**: The tag is evaluated, and the file is routed accordingly:
     - **NO_THREATS_FOUND**: Sent to the consumer bucket.
     - **THREATS_FOUND**: Moved to the `malware_s3` bucket.
     - **Other Tags**: Quarantined in the source bucket or flagged for further review.

4. **Post-Processing**:
   - Scanned files are deleted from `/tmp` after processing to free up runtime space.

---

## Implementation Steps

### Prerequisites
1. **Lambda v13**: Ensure the Lambda function is updated to version 13 from Module v3 of the Standard Transfer Service setup.
2. **Environment Variables**:
   - `GD_SCANNING_BUCKET`: Name of the S3 bucket used for GuardDuty scanning.
   - `MALWARE_S3_BUCKET`: Name of the S3 bucket used for storing threat files.
   - `ENABLE_SCANNING`: Boolean value (`true` or `false`) to enable or disable scanning.
   - `POLLING_INTERVAL`: Time (in seconds) for the Lambda function to wait for GuardDuty to apply tags.
3. **DynamoDB Transmission Matrix**:
   - The `malware2` action must be set for file patterns to enable GuardDuty scanning.

### Steps to Set Up
1. **Create S3 Buckets**:
   - `gd_scanning`: This bucket is used to upload decrypted files for GuardDuty scanning.
   - `malware_s3`: This bucket stores files flagged with `THREATS_FOUND`.

2. **Update Lambda Configuration**:
   - Deploy **Lambda v13**.
   - Set the required environment variables (`GD_SCANNING_BUCKET`, `MALWARE_S3_BUCKET`, `ENABLE_SCANNING`, `POLLING_INTERVAL`).

3. **Configure DynamoDB**:
   - Verify that the transmission matrix table includes `malware2` as the set action for applicable file patterns.

4. **Testing**:
   - Upload test files to ensure they are processed, scanned, and routed based on the GuardDuty tags.

5. **Monitoring**:
   - Enable CloudWatch Logs for the Lambda function to track processing and scanning activities.
   - Set up GuardDuty findings export for centralized threat visibility.

---

## Notes
- Scanning will not work if the **DynamoDB transmission matrix table** does not include `malware2` as an action for the file.
- The scanning process is region-specific, so ensure that the `gd_scanning` and `malware_s3` buckets are created in the correct region.
- Cost considerations should be evaluated as multiple clients may share the same S3 buckets for scanning and threat storage in a region.

---

## Technical Architecture Diagram

Refer to the attached diagram for a visual representation of the process flow.

---

## Troubleshooting
1. **Files not scanned**:
   - Verify that `ENABLE_SCANNING` is set to `true` in the Lambda environment variables.
   - Check the `POLLING_INTERVAL` value and adjust if necessary.
2. **Tags not applied**:
   - Ensure the file format is supported by GuardDuty.
   - Confirm that GuardDuty is enabled for the specific AWS region.

3. **Incorrect Routing**:
   - Verify the configuration of the transmission matrix in DynamoDB.
   - Check S3 bucket policies to ensure proper access permissions.

---

This document serves as a complete guide to understanding, setting up, and troubleshooting GuardDuty malware protection in the Standard Transfer Service Offering.