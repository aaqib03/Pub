Perfect. Here’s your clean steps-only version that you can directly put into the document or hand over:


---

AWS CLI Upgrade — Step-by-Step Procedure (Windows EC2 Private Instance)


---

Preparation and Backup

1️⃣ Take Full EC2 Snapshots

Log in to AWS Console.

Go to EC2 → Volumes → Select all attached volumes.

For each volume, click Actions → Create Snapshot.

Name snapshot:
Pre-AWSCLI-Upgrade-<InstanceName>-<DateTime>


2️⃣ Backup AWS CLI Configuration Files

Inside EC2:

Go to C:\Users\<username>\.aws\

Copy both config and credentials files.

Backup to a separate location:
D:\Backup\AWSCLI_Config_Backup_<Date>




---

Upgrade Execution

3️⃣ Verify Current AWS CLI Version

In command prompt (run as Administrator):

aws --version


4️⃣ Download Latest AWS CLI Installer

On a system with internet access, download: https://awscli.amazonaws.com/AWSCLIV2.msi

Copy installer to EC2 (via shared internal network or bastion jump server).


5️⃣ Uninstall Existing AWS CLI

Go to: Control Panel → Programs → Programs and Features

Select AWS CLI → Uninstall.


(Alternatively use msiexec /x if GUI not accessible)

6️⃣ Install New AWS CLI

Run downloaded AWSCLIV2.msi as Administrator.

Use default installation options.

After install completes, verify:

aws --version
where aws



---

Post-Installation Validation

7️⃣ Run CLI Health Check Commands

Test CLI access with:

aws s3 ls
aws ec2 describe-instances --region <region>
aws sts get-caller-identity

Verify that AWS credentials and config are being correctly picked up.


8️⃣ Verify OpenSSL Version

Navigate to AWS CLI install directory:

cd "C:\Program Files\Amazon\AWSCLIV2"
openssl version



---

Rollback Plan (If Issues Occur)

9️⃣ Installer Failure or CLI Breakage

Uninstall AWS CLI v2.

Reinstall previous AWS CLI version from backup installer.

Retest.


10️⃣ Severe System Issue

Restore EC2 instance volumes from snapshots:

Stop instance.

Detach existing volumes.

Attach volumes created from snapshots.

Start instance and validate system.




---

Closure

11️⃣ Post-Upgrade Cleanup

Update internal documentation with:

New AWS CLI version.

Date of upgrade.

Snapshot IDs.


Retain both new and old installers in backup storage.



---

✅ End of Step-by-Step Document


---

> If you want, I can also generate a “copy-paste ready Word document version” that you can directly circulate to your operations team.
Shall I?



