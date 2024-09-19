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

4. **Stop and Start the Instance to Migrate to New Hardware**:
   - If the issue is due to an underlying hardware failure, **stopping and starting** the instance (rather than rebooting) can force AWS to move the instance to a different physical server.
   - This effectively **migrates the instance** to a new hardware host within the same availability zone.
     - **Steps**:
       - In the **EC2 Console**, select the instance.
       - Go to **Actions** → **Instance State** → **Stop**.
       - Wait until the instance is completely stopped.
       - Then, go to **Actions** → **Instance State** → **Start** to start the instance on a different host.
   - After starting the instance, recheck the **system status** to verify if the issue is resolved.

5. **Check Network Connectivity**:
   - If network reachability is the issue, verify that the **subnet route tables**, **NACLs**, and **security groups** are configured correctly.
   - Ensure that **internet gateway** and **NAT gateway** configurations are correct for external traffic.

6. **Attempt to Restore Instance from Backup (Snapshot or AMI)**:
   - If the instance continues to fail after migration and network troubleshooting, it might indicate severe corruption or issues beyond hardware failure.
   - In this case, **restoring from an EBS snapshot** or **Amazon Machine Image (AMI)** might be necessary.
     - **Steps**:
       - **For EBS Snapshot**:
         - Go to the **Elastic Block Store (EBS)** section of the AWS Console.
         - Select the latest **snapshot** associated with the root volume of the instance.
         - Create a new **EBS volume** from the snapshot and attach it to the instance.
       - **For AMI Backup**:
         - If you have a complete AMI backup, you can launch a new instance using the AMI to restore the instance's original state.

---

#### When to Recover from Snapshot:

- You should consider **restoring from a snapshot** when:
  - The instance fails repeatedly after hardware migration (i.e., stopping and starting).
  - The root volume is corrupted or inaccessible.
  - You’ve exhausted other troubleshooting options, including network and system checks.
  
- **Important Notes**:
  - Restoring from a snapshot will replace the existing root volume with a previous state. This means that any data or changes made since the snapshot was taken will be lost unless additional backups are available.
  - Ensure that a **latest snapshot** is available before proceeding with recovery.