## Troubleshooting

When an alarm is triggered, the operations team should follow the detailed troubleshooting steps below to investigate and resolve the issue.

---

### Troubleshooting: Instance Status Check Failed

#### Description:
This alert triggers when the EC2 instance’s **OS-level health check** fails. It typically indicates a problem with the operating system, such as failure to boot, kernel panic, or networking issues like misconfigured routes or blocked access.

#### Logs to Check:
- **System Log**: Look for boot errors, kernel panics, service failures, or other system-level issues.
- **Security Log**: Check for unauthorized access attempts, permission changes, or failed logins that might affect the instance’s operations.

#### Steps to Troubleshoot:

1. **Verify Instance Status in EC2 Dashboard**:
   - Go to the **AWS EC2 Dashboard** and locate the affected instance.
   - Check if the instance is in a **running**, **stopped**, or **pending** state.
   - If the instance is **stopped** or **pending**, there might be a provisioning issue. If it’s **running**, proceed to the next step.

2. **Check System Logs in EC2 Console**:
   - Select the instance and navigate to the **Monitoring** tab.
   - Review the **System Log** in CloudWatch to identify if the instance encountered a **kernel panic** or any **boot errors**.
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

#### Logs to Check:
- **System Log**: Check for system-level events, hardware failures, or issues with services that are tied to the AWS infrastructure.
- **Amazon CloudWatch Agent Log**: If you’re not receiving any metrics/logs, this log can help identify issues with the agent.

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

#### Logs to Check:
- **System Log**: Look for issues related to EBS volume mounting, disconnections, or I/O bottlenecks.
- **Amazon CloudWatch Agent Log**: If you are not seeing any volume-specific metrics, this log will help diagnose agent-related issues.
- **Security Log**: If there’s a failure related to permissions or access control to the EBS volume, check for logs related to access control changes.

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