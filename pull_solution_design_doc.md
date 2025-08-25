📥 SFTP Pull Workflow - Solution Design Document


---

📌 Introduction & Requirement

Many enterprises exchange data with partners over secure file transfer protocols such as SFTP. In this project, we need an automated, scalable, serverless solution that pulls files from a remote SFTP server (using AWS Transfer Family connector) to Amazon S3 every 15 minutes, per client. This workflow should:

Use one shared Step Function to serve all clients

Use DynamoDB to store client-specific connection metadata

Use EventBridge to schedule per-client file pulls

Use a Lambda function to filter file listings (e.g., by type, timestamp)

Avoid manual triggers or persistent infrastructure

Optionally move or delete remote files after successful pull



---

🧱 Services Used & Roles

1. Amazon EventBridge

Triggers Step Function execution every 15 minutes (or as configured)

One rule per client with custom parameters (e.g., bucket_name)


2. AWS Step Functions

Orchestrates the full file pull process

Uses AWS SDK integrations (not Lambda) to:

Fetch config from DynamoDB

List directory on SFTP server

Retrieve listing result

Pull files one by one



3. AWS DynamoDB (sftp_connection_detail table)

Stores client-specific SFTP connector configurations:

bucket_name (partition key)

sftp_connector_id

sftp_host_path

s3_target_prefix

move_on_success

enable_pull

(optional) archive_folder_name, sftp_filename_pattern



4. AWS Lambda

Optional, for filtering file listing before transfer

Example use cases:

Only .csv files

Files not already processed

Time-based filtering



5. AWS Transfer Family (SFTP Connector)

Acts as a bridge to the remote SFTP server

Supports listing directories and transferring files

Accepts AWS-managed connector credentials and paths


6. Amazon S3

Destination for successfully pulled files

Uses client-specific s3_target_prefix for folder path


7. (Optional) Second DynamoDB Table for Transfer Logs

Can be used to log transfer history per file:

Filename

Timestamp

Status (success/failure)

Error messages (if any)




---

🔁 High-Level Workflow Description

Step-by-Step:

1. EventBridge Rule Fires (per client)

Sends a scheduled input: { "bucket_name": "client-a-bucket" }



2. Step Function Starts

Queries DynamoDB using the bucket_name

Gets connector details and host path



3. Start Directory Listing

Calls StartDirectoryListing API using the connector ID and host path

Gets back a Job ID



4. Wait (10 seconds)

Gives the connector time to generate the listing



5. Get Directory Listing Result

Calls GetDirectoryListingResult with the Job ID

Retrieves a list of filenames on the SFTP server



6. Call Filtering Lambda (optional)

Passes full list of files to Lambda

Lambda returns a filtered list (e.g., only .csv files)



7. Iterate Over Files (Map State)

For each file:

Call StartInboundFileTransfer to pull it to S3

Target path = s3://bucket-name/s3_target_prefix/filename.ext




8. (Optional) Post-Transfer Actions

Use MoveFile or DeleteFile API to clean up source

Update a transfer history table





---

🗂️ DynamoDB Table Design (sftp_connection_detail)

Field	Type	Description

bucket_name	String (PK)	S3 bucket name per client
sftp_connector_id	String	AWS Transfer Family connector ID
sftp_host_path	String	Path on SFTP server to list files from
s3_target_prefix	String	S3 folder to store transferred files
move_on_success	Boolean	Whether to delete/move the source file after successful transfer
enable_pull	Boolean	Used to disable pull per client (e.g., during maintenance)
sftp_filename_pattern	String (optional)	Pattern like *.csv to filter files
archive_folder_name	String (optional)	Path to move files on SFTP post-pull



---

🧠 Logical Flow Diagram

EventBridge (15 min)
   │
   ▼
Step Function ──────────────┬─────────────┬─────────────┐
   │                        │             │             │
   ▼                        ▼             ▼             ▼
Get config           StartDirectoryListing   Wait     GetDirectoryListingResult
   │                                                         │
   ▼                                                         ▼
  [Optional] Lambda ────> Filter Files                    Map over file list
                               │                                │
                               ▼                                ▼
                      StartInboundFileTransfer ──────> Store in S3
                                                         │
                                                         ▼
                                            (Optional) Move/Delete file
                                                         │
                                                         ▼
                                           (Optional) Update Transfer Log


---

📌 Benefits of This Design

Feature	Benefit

One Step Function	Easy to manage, reusable for all clients
No Lambda unless needed	Cost-effective, faster setup
Uses only AWS SDK	Secure and serverless, fully managed
Per-client EventBridge	Granular control over frequency
Config via DynamoDB	No redeployments needed for new clients
Scalable design	Can onboard new clients just by updating the table + rule



---

✅ Next Steps for Engineering Team

Implement the sftp_connection_detail DynamoDB table (if not done)

Create the Transfer Family SFTP connectors per client

Create the Step Function using SDK service integrations

Add the optional filtering Lambda if needed

Setup EventBridge rules for each client

Test using a mock SFTP endpoint or sandbox connector

Add optional error handling, alerting, and history tracking if required



---

For full Terraform code and deployment instructions, refer to implementation.md and sftp_pull_step_function.tpl files.

