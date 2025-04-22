Perfect! Since you only need the first workflow for pulling files from SFTP to S3 and want to reuse your existing DynamoDB sftp_connection_detail table, let’s build on that.


---

✅ 1. DynamoDB Table Design (Updated)

You already store:

bucket_name (PK)

sftp_connector_id


Now add:


---

🧠 2. EventBridge Rule Per Client

Each rule can:

Run every 15 minutes

Pass bucket_name or sftp_connector_id in event input


{
  "bucket_name": "client-x-bucket"
}


---

🔁 3. Step Function: Pull Files from SFTP

Here’s a logical flow:


---

Step 1: Fetch Partner Config from DynamoDB

Input: { "bucket_name": "client-x-bucket" }

→ DynamoDB `GetItem` using `bucket_name`
→ Get all connection and config fields


---

Step 2: Start Directory Listing via Connector

Use StartDirectoryListing API from Transfer Family:

Pass sftp_connector_id from DynamoDB

Include sftp_host_path if defined


This queues the request to list files on the SFTP server.


---

Step 3: Wait for Listing Completion (via EventBridge or Wait with retry loop)

Wait for event like:

SFTP Connector Directory Listing Completed


Or use retry + GetDirectoryListingResult polling pattern with exponential backoff.


---

Step 4: Parse File List & Iterate

Get files from listing result (S3 JSON file path or direct payload) → Loop over each file:

If matches sftp_filename_pattern, continue

Else skip



---

Step 5: Download File via StartInboundFileTransfer

Use StartInboundFileTransfer:

From connector_id + remote file path

To S3 bucket_name + s3_target_prefix



---

Step 6: Verify Success & Post-Transfer Action

For each file:

✅ If success and move_on_success is true → delete from SFTP

❌ If failed → move to archive_folder_name or processed/


(Use MoveFile API if supported, or re-upload + delete)


---

🗂️ 4. Optional: Log Transfer Metadata to DynamoDB (Secondary Table)


---

✅ Final Summary

Components you need:

📘 Updated sftp_connection_detail DynamoDB table

📅 EventBridge rules per client with custom input

🔁 Single reusable Step Function

🔐 Transfer Family connector already per client

🧠 Optional: secondary table for history/logs


Would you like me to generate a sample Step Function definition (Amazon States Language) based on this logic next?

