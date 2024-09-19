# Instance Monitoring

Welcome to the **Instance Monitoring** project. This project is dedicated to setting up and maintaining the monitoring alerts for EC2 instances and their attached resources, such as EBS volumes. Any future monitoring alerts related to EC2 instances will be maintained and managed here.

The following CloudWatch alarms have been configured in this project:

- **Instance Status Check Failed**
- **System Status Check Failed**
- **Attached EBS Volume Status Check**
- **Secondary EBS Volume Status Check**
- **Root EBS Volume Status Check**

## Table of Contents

- [Alerts Overview](#alerts-overview)
  - [Instance Status Check Failed](#instance-status-check-failed)
  - [System Status Check Failed](#system-status-check-failed)
  - [Attached EBS Volume Status Check](#attached-ebs-volume-status-check)
  - [Secondary EBS Volume Status Check](#secondary-ebs-volume-status-check)
  - [Root EBS Volume Status Check](#root-ebs-volume-status-check)
- [Troubleshooting](#troubleshooting)
  - [Instance Status Check Failed](#troubleshooting-instance-status-check-failed)
  - [System Status Check Failed](#troubleshooting-system-status-check-failed)
  - [Attached EBS Volume Status Check](#troubleshooting-attached-ebs-volume-status-check)
  - [Secondary EBS Volume Status Check](#troubleshooting-secondary-ebs-volume-status-check)
  - [Root EBS Volume Status Check](#troubleshooting-root-ebs-volume-status-check)
- [Future Alerts](#future-alerts)
- [Contributing](#contributing)

---

## Alerts Overview

Below is the overview of the CloudWatch alarms configured for monitoring EC2 instances and EBS volumes:

| **Alert Name**                  | **Metric**                   | **Description**                                                                 | **Threshold** | **Period** | **Evaluation** |
| ------------------------------- | ---------------------------- | ------------------------------------------------------------------------------- | ------------- | ---------- | -------------- |
| **Instance Status Check Failed** | `StatusCheckFailed_Instance`  | Triggers if the EC2 instance fails the instance-level status check.              | 1             | 60 seconds | 1              |
| **System Status Check Failed**   | `StatusCheckFailed_System`    | Triggers if the system-level (AWS hardware/network) check fails for the instance.| 1             | 60 seconds | 1              |
| **Attached EBS Volume Status Check** | `StatusCheckFailed_AttachedEBS` | Monitors the health of all attached EBS volumes. Triggers on volume failure. | 1             | 300 seconds | 1              |
| **Secondary EBS Volume Status Check** | `VolumeStatusCheckFailed` | Monitors the health of the secondary EBS volume specifically. Triggers on failure.| 1             | 300 seconds | 1              |
| **Root EBS Volume Status Check**  | `VolumeStatusCheckFailed`    | Monitors the health of the root EBS volume specifically. Triggers on failure.    | 1             | 300 seconds | 1              |

### 1. **Instance Status Check Failed**
- **Metric**: `StatusCheckFailed_Instance`
- **Purpose**: This alarm monitors the EC2 instance’s health at the **instance level**. It triggers if there’s a failure with the operating system or software issues that prevent the instance from responding.
- **Threshold**: 1
- **Evaluation Period**: 1
- **Trigger Condition**: The alarm will trigger if the instance fails its health check even once.

### 2. **System Status Check Failed**
- **Metric**: `StatusCheckFailed_System`
- **Purpose**: This alarm monitors the EC2 instance’s **system-level health**. It triggers when AWS detects underlying hardware or networking issues that prevent the instance from working properly.
- **Threshold**: 1
- **Evaluation Period**: 1
- **Trigger Condition**: The alarm will trigger if there’s an AWS infrastructure issue affecting the instance.

### 3. **Attached EBS Volume Status Check**
- **Metric**: `StatusCheckFailed_AttachedEBS`
- **Purpose**: This alarm monitors the health of **all attached EBS volumes**. If any attached EBS volume fails a status check, this alarm will trigger.
- **Threshold**: 1
- **Evaluation Period**: 1
- **Trigger Condition**: The alarm will trigger if any EBS volume attached to the instance fails the status check.

### 4. **Secondary EBS Volume Status Check**
- **Metric**: `VolumeStatusCheckFailed`
- **Purpose**: This alarm specifically monitors the **secondary EBS volume** attached to the EC2 instance. It will trigger if the secondary EBS volume fails its health check.
- **Threshold**: 1
- **Evaluation Period**: 1
- **Trigger Condition**: The alarm will trigger if the secondary EBS volume fails a status check.

### 5. **Root EBS Volume Status Check**
- **Metric**: `VolumeStatusCheckFailed`
- **Purpose**: This alarm monitors the **root EBS volume** attached to the EC2 instance. It will trigger if the root EBS volume fails its health check.
- **Threshold**: 1
- **Evaluation Period**: 1
- **Trigger Condition**: The alarm will trigger if the root EBS volume fails a status check.

---

## Troubleshooting

When an alarm is triggered, the operations team should follow the troubleshooting steps below to investigate and resolve the issue.

### Troubleshooting: Instance Status Check Failed

1. **Verify the Instance's State**:
   - Go to the **EC2 dashboard** in the AWS Console.
   - Check if the instance is running or in a failed state.
   
2. **Check CloudWatch Logs**:
   - Review the **instance logs** in CloudWatch to identify any OS-level or software issues.
   - Investigate application-level logs if the instance is still running but unresponsive.

3. **Reboot the Instance**:
   - If the issue persists and it appears to be OS-related, attempt to **reboot** the instance from the AWS Console.

4. **Review Instance Performance**:
   - Check the **CPU and memory utilization** to determine if resource exhaustion is causing the issue.

### Troubleshooting: System Status Check Failed

1. **Check for AWS Outages**:
   - Review the **AWS Health Dashboard** to see if there are any ongoing infrastructure issues in the region.
   
2. **Restart the Instance**:
   - Try to **stop** and **start** the instance. This will move the instance to new underlying hardware if there’s a hardware failure.

3. **Inspect Networking Issues**:
   - Check if there are **networking issues** (e.g., VPC, security groups, or routing tables) affecting the instance's connectivity.

4. **Contact AWS Support**:
   - If AWS infrastructure issues persist, **open a support case** with AWS for further assistance.

### Troubleshooting: Attached EBS Volume Status Check

1. **Identify the Problematic EBS Volume**:
   - Go to the **EC2 dashboard** and select the affected instance.
   - Navigate to the **Storage** tab and identify which EBS volume is failing.

2. **Check EBS Metrics**:
   - Use **CloudWatch** to check the following metrics for the EBS volume:
     - `VolumeReadOps`, `VolumeWriteOps`, `VolumeIdleTime`, `VolumeThroughputPercentage`.
   - Look for any anomalies in read/write operations or throughput.

3. **Detach and Re-Attach the EBS Volume**:
   - If there are connectivity issues with the EBS volume, try **detaching** and **re-attaching** the volume to the instance.

4. **Restore from Snapshot**:
   - If the volume is failing due to corruption, restore the data from the latest EBS **snapshot** and create a new volume.

5. **Check for IOPS Limitations**:
   - Verify if the volume is hitting its IOPS limit. If so, consider upgrading to **provisioned IOPS**.

### Troubleshooting: Secondary EBS Volume Status Check

1. **Check Secondary Volume Logs**:
   - In the AWS Console, verify the **secondary EBS volume** logs for errors or anomalies.

2. **Validate Volume Connection**:
   - Ensure that the secondary EBS volume is properly attached and recognized by the EC2 instance.

3. **Check Volume Utilization**:
   - Review the volume's IOPS and throughput metrics to determine if it's hitting performance limits.

4. **Restore from Snapshot**:
   - If the secondary volume is corrupted, restore from a previous snapshot.

### Troubleshooting: Root EBS Volume Status Check

1. **Verify Root Volume Health**:
   - In the AWS Console, check the **root EBS volume** for any health-related issues.

2. **Review IOPS and Latency**:
   - Use CloudWatch metrics to check if the root volume is hitting its IOPS limit or experiencing high latency.

3. **Reboot or Restore**:
   - If the root volume is failing, you can attempt to reboot the instance or restore the root volume from a snapshot.

---

## Future Alerts

This project is designed to handle the ongoing monitoring needs of EC2 instances. Any future alerts that are related to **instance monitoring** will be created and managed within this repository