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
       - Then, go to **Actions** → **Instance State** → **Start** to start⬤