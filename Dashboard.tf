Here are multiple AWS CloudWatch Logs Insights queries to extract file name, transfer status, start time, end time, and file size separately into distinct columns.


---

1️⃣ Basic Query (Direct Parsing from Message)

fields @timestamp, @message
| parse @message '"file-path":"*","status-code":"*","start-time":"*","end-time":"*","bytes":*' as file_path, status_code, start_time, end_time, file_size
| sort @timestamp desc
| limit 20

✅ Best when fields are structured directly in @message.


---

2️⃣ JSON Parsing (If Message is Well-Formatted JSON)

fields @timestamp, @message
| parse_json(@message) as log_data
| display log_data["file-path"], log_data["status-code"], log_data["start-time"], log_data["end-time"], log_data["bytes"]
| sort @timestamp desc
| limit 20

✅ Best when @message is a structured JSON object.


---

3️⃣ Multiple Parse for Nested JSON Variations

fields @timestamp, @message
| parse @message '"file-path":"*"' as file_path
| parse @message '"status-code":"*"' as status_code
| parse @message '"start-time":"*"' as start_time
| parse @message '"end-time":"*"' as end_time
| parse @message '"bytes":*' as file_size
| sort @timestamp desc
| limit 20

✅ Best when fields are inconsistently formatted inside @message.


---

4️⃣ Filtering Only Completed Transfers

fields @timestamp, @message
| parse @message '"file-path":"*","status-code":"*","start-time":"*","end-time":"*","bytes":*' as file_path, status_code, start_time, end_time, file_size
| filter status_code = "COMPLETED"
| sort @timestamp desc
| limit 20

✅ Filters out failed transfers and shows only completed ones.


---

5️⃣ Handling Unexpected Spaces & Case Sensitivity

fields @timestamp, @message
| parse @message '"file-path" : "*"' as file_path
| parse @message '"status-code" : "*"' as status_code
| parse @message '"start-time" : "*"' as start_time
| parse @message '"end-time" : "*"' as end_time
| parse @message '"bytes" : *' as file_size
| sort @timestamp desc
| limit 20

✅ Best when spaces or variations exist in field names.


---

6️⃣ Extracting Additional Metadata (Connector ID, Transfer ID)

fields @timestamp, @message
| parse @message '"file-path":"*","status-code":"*","start-time":"*","end-time":"*","bytes":*,"connector-id":"*","transfer-id":"*"' as file_path, status_code, start_time, end_time, file_size, connector_id, transfer_id
| sort @timestamp desc
| limit 20

✅ Useful if you also need connector-id and transfer-id.


---

7️⃣ Ensuring Only Logs That Contain All Fields Are Displayed

fields @timestamp, @message
| parse @message '"file-path":"*","status-code":"*","start-time":"*","end-time":"*","bytes":*' as file_path, status_code, start_time, end_time, file_size
| filter ispresent(file_path) and ispresent(status_code) and ispresent(start_time) and ispresent(end_time) and ispresent(file_size)
| sort @timestamp desc
| limit 20

✅ Prevents missing values in extracted fields.


---

**8️⃣ Table Format for

