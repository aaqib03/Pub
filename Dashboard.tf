Here is the AWS CloudWatch Logs Insights queries in markdown format:

# AWS CloudWatch Logs Insights Queries

## 1. Basic Query to Extract All Fields from the Log Message
```sql
fields @timestamp, @message
| sort @timestamp desc
| limit 20

2. Extracting Specific Fields Directly from JSON Formatted Logs

fields @timestamp, @message, bytes
| parse_json(@message) as log_data
| display log_data.status-code, log_data.file-path, log_data.bytes
| sort @timestamp desc
| limit 20

3. Parsing Structured JSON Fields Explicitly

fields @timestamp, @message, bytes
| parse @message '"status-code":"*","file-path":"*","bytes":*' as status_code, file_path, bytes
| sort @timestamp desc
| limit 20

4. Extracting Relevant Fields Using Multiple Parsing Methods

fields @timestamp, @message, bytes
| parse @message '"status-code": *' as status_code
| parse @message '"file-path": "*"' as file_path
| parse @message '"bytes": *' as bytes
| sort @timestamp desc
| limit 20

5. Filtering Out Logs That Do Not Contain Relevant Data

fields @timestamp, @message, status_code, file_path, bytes
| filter ispresent(status_code) and ispresent(file_path)
| sort @timestamp desc
| limit 20

6. Extracting Nested Attributes from JSON Logs

fields @timestamp, bytes
| parse_json(@message) as log_data
| display log_data["status-code"], log_data["file-path"], log_data["bytes"]
| sort @timestamp desc
| limit 20

7. Extracting Additional Metadata from Log Attributes

fields @timestamp, account-id, connector-id, transfer-id, status-code, file-path, bytes
| sort @timestamp desc
| limit 20

8. Extracting All Possible Structured Data Including ARN and File Details

fields @timestamp, account-id, connector-arn, connector-id, transfer-id, file-transfer-id, status-code, file-path, bytes
| sort @timestamp desc
| limit 20

You can copy this markdown file directly and use it in your documentation or notes. Let me know if you need any modifications! 🚀

