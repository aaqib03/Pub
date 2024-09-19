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
- **Purpose**: Monitors the EC2 instance’s **operating system health**. This alert will notify the operations team when the OS is unresponsive or facing critical errors.
- **Trigger Condition**: The alarm triggers when the **instance-level health check** fails (returns `1`).
- **Threshold**: 1 (Trigger on first failure).
- [**Troubleshooting**](#troubleshooting-instance-status-check-failed)

### 2. **System Status Check Failed**
- **Metric**: `StatusCheckFailed_System`
- **Purpose**: Monitors the **AWS system-level health** of the instance. This alert captures issues with the underlying AWS infrastructure (hardware, network, etc.).
- **Trigger Condition**: The alarm triggers when the **system-level health check** fails (returns `1`), indicating AWS infrastructure issues.
- **Threshold**: 1 (Trigger on first failure).
- [**Troubleshooting**](#troubleshooting-system-status-check-failed)

### 3. **Attached EBS Volume Status Check**
- **Metric**: `StatusCheckFailed_AttachedEBS`
- **Purpose**: Monitors the health of **all EBS volumes attached** to the instance. The alert triggers when any attached volume fails its health check.
- **Trigger Condition**: The alarm triggers if **any EBS volume attached** to the instance fails its health check (returns `1`).
- **Threshold**: 1 (Trigger on first failure).
- [**Troubleshooting**](#troubleshooting-attached-ebs-volume-status-check)

### 4. **Secondary EBS Volume Status Check**
- **Metric**: `VolumeStatusCheckFailed`
- **Purpose**: Monitors the **secondary EBS volume** attached to the EC2 instance. This alert will notify when the secondary volume faces issues like corruption or connectivity failure.
- **Trigger Condition**: The alarm triggers if the **secondary EBS volume** fails its health check (returns `1`).
- **Threshold**: 1 (Trigger on first failure).
- [**Troubleshooting**](#troubleshooting-secondary-ebs-volume-status-check)

### 5. **Root EBS Volume Status Check**
- **Metric**: `VolumeStatusCheckFailed`
- **Purpose**: Monitors the **root EBS volume** (the boot volume) attached to the EC2 instance. This alert notifies the team if the boot volume fails or experiences issues that may impact instance functionality.
- **Trigger Condition**: The alarm triggers if the **root EBS volume** fails its health check (returns `1`).
- **Threshold**: 1 (Trigger on first failure).
- [**Troubleshooting**](#troubleshooting-root-ebs-volume-status-check)

---

## Troubleshooting

When an alarm is triggered, the operations team should follow the detailed troubleshooting steps below to investigate and resolve the issue.

---

### Troubleshooting: Instance Status Check Failed

#### Description:
This alert triggers when the EC2 instance’s **OS-level health check** fails. It typically indicates a problem with the operating system, such as failure to boot, kernel panic, or networking issues like misconfigured routes or blocked access.

#### Steps to Troubleshoot:

1. **Verify Instance Status in EC2 Dashboard**:
   - Go to the **AWS EC2 Dashboard** and locate the affected instance.
   - Check if the instance is in a **running**, **stopped**, or **pending** state.
   - If the instance is **stopped** or **pending**, there might be a provisioning issue. If it’s **running**, proceed to the next step.

2. **Check System Logs in EC2 Console**:
   - Select the instance and navigate to the **Monitoring** tab.
   - Review **CloudWatch Logs** to identify if the instance encountered a **kernel panic** or any **boot errors**.
   - If no logs are visible, go to **Actions** → **Instance Settings** → **Get System Logs** to retrieve boot logs directly.

3. **Verify Security Groups and Network Configuration**:
   - Confirm that the instance is attached to the correct **security group** and **VPC**.
   - Verify that the **security group rules** allow the necessary inbound and outbound traffic (e.g., SSH/RDP ports, HTTP/HTTPS, etc.).
   - Ensure that the **NACLs (Network Access Control Lists)** and **route tables** are configured properly to allow traffic.

4. **Test Connectivity via SSH/RDP**:
   - Try to connect to the instance using **SSH (Linux)** or **RDP (Windows)**.
   - If connection fails, confirm the **public IP/DNS** is correct and that inbound traffic to the instance is allowed.

5. **Reboot the Instance**:
   - If the instance is unresponsive or stuck in a problematic state, **reboot** it from the AWS Console.
   - Go to **Actions** → **Instance State** → **Reboot Instance**.
   - Monitor the instance after the reboot to see if it recovers.

6. **Check for Resource Exhaustion**:
   - Review the **CPU utilization** and **memory metrics** under the **Monitoring** tab to ensure the instance is not **out of resources**.
   - If the instance is resource-constrained, consider scaling up by changing the instance type.

7. **Restore from AMI Backup (if needed)**:
   - If the issue persists and troubleshooting doesn’t resolve the problem, consider restoring the instance from a known good **Amazon Machine Image (AMI)**.

---

### Troubleshooting: System Status Check Failed

#### Description:
This alert triggers when the **system-level health check** fails, indicating potential hardware, networking, or AWS infrastructure issues. This could include a failure of AWS's underlying hardware hosting the instance or a networking problem at AWS’s infrastructure level.

#### Steps to Troubleshoot:

1. **Check AWS Health Dashboard**:
   - First, check the **AWS Service Health Dashboard** to see if AWS is experiencing any known infrastructure outages or issues in the region where your instance resides.

2. **Review System Metrics in CloudWatch**:
   - In the **EC2 Dashboard**, go to **Monitoring** for the affected instance.
   - Review system-level metrics such as **InstanceReachability**, **Disk I/O**, **CPU utilization**, and **Network throughput**.
   - If you observe abnormal activity (e.g., high CPU or disk I/O), it may indicate underlying system issues.

3. **Check the Hypervisor (if applicable)**:
   - Instances hosted on **dedicated hosts** or **dedicated instances** can experience problems with the underlying hardware.
   - If applicable, check the hypervisor logs to see if hardware issues are impacting the instance.

4. **Stop and Start the Instance**:
   - If the issue is due to an underlying hardware failure, **stop** and **start** the instance (do not reboot). This action will move the instance to a different underlying host in AWS's data center.
   - After starting the instance, recheck the **system status** to verify if the issue is resolved.

5. **Check Network Connectivity**:
   - If network reachability is the issue, verify that the **subnet route tables**, **NACLs**, and **security groups** are configured correctly.
   - Ensure that **internet gateway** and **NAT gateway** configurations are correct for external traffic.

6. **Restore the Instance from Backup**:
   - If the system is completely unresponsive and stopping/starting does not resolve the issue, restore the instance from an **EBS snapshot** or **AMI backup**.

7. **Contact AWS Support**:
   - If AWS system issues persist and the above steps do not resolve the problem, open a support case with **AWS Support** and provide detailed logs and steps taken.

---

### Troubleshooting: Attached EBS Volume Status Check

#### Description:
This alert triggers when an **attached EBS volume** (either root or secondary) experiences issues such as failing I/O operations, becoming disconnected, or facing **health check failures**. This can indicate a problem with the storage device or connectivity issues between the instance and the EBS volume.

#### Steps to Troubleshoot:

1. **Identify the Affected EBS Volume**:
   - In the **EC2 Dashboard**, select the affected instance and navigate to the **Storage** tab.
   - Identify which attached EBS volume is showing errors or **unhealthy status**.

2. **Check EBS Volume Metrics in CloudWatch**:
   - In **CloudWatch**, review metrics for the EBS volume, such as:
     - `VolumeReadOps` and `VolumeWriteOps`: High values here indicate excessive I/O operations.
     - `VolumeIdleTime`: Zero idle time could mean the volume is overloaded.
     - `VolumeThroughputPercentage`: A high percentage may indicate the volume is hitting its throughput limit.
   
3. **Detach and Reattach the EBS Volume**:
   - If the volume shows **disconnected** or **unhealthy** status, try detaching and reattaching the volume.
   - Navigate to the **EC2 Dashboard**, choose the affected volume under **Elastic Block Store (EBS)**, and select **Detach Volume**.
   - Once detached, reattach it to the same or another instance.

4. **Verify EBS Volume Integrity**:
   - Run a **file system check** on the EBS volume (e.g., `fsck` for Linux or `chkdsk` for Windows) to verify that the volume is not corrupted.

5. **Resize the Volume (if needed)**:
   - If the volume is running out of space or hitting IOPS/throughput limits, consider **resizing the volume** or upgrading it to a higher-performing type, such as **Provisioned IOPS (io1/io2)**.

6. **Restore from Snapshot**:
   - If the EBS volume is severely corrupted, restore it from an earlier **EBS snapshot** to recover lost data.

7. **Check Volume Attachment to Instance**:
   - Ensure that the volume is correctly attached to the instance (with proper mount points or drive letters in case of Windows).
   - For Linux instances, check if the volume is properly mounted using `df -h` or `lsblk`.

8. **Replace the Volume (if needed)**:
   - If the volume is permanently damaged or corrupted, you may need to create a new EBS volume from a snapshot and attach it to the instance.

---