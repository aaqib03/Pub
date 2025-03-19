Based on your requirement to extract file name, transfer status, and file size, and considering the issue in your query where fields were not extracted correctly, here are the refined queries:


---

1. Extract Fields Using JSON Parsing

fields @timestamp, @message
| parse_json(@message) as log_data
| display log_data["file-path"], log_data["status-code"], log_data["bytes"]
| sort @timestamp desc
| limit 20

✅ Why?

This extracts file-path (file name), status-code (transfer status), and bytes (file size) directly.



---

2. Explicitly Parse JSON Fields from Message

fields @timestamp, @message
| parse @message '"file-path":"*","status-code":"*","bytes":*' as file_path, status_code, file_size
| sort @timestamp desc
| limit 20

✅ Why?

Useful if JSON is embedded as a string inside @message.



---

3. Filter Logs to Show Only Successful Transfers

fields @timestamp, @message
| parse_json(@message) as log_data
| filter log_data["status-code"] = "COMPLETED"
| display log_data["file-path"], log_data["status-code"], log_data["bytes"]
| sort @timestamp desc
| limit 20

✅ Why?

Filters logs to show only successfully transferred files.



---

4. Handling Variations in Field Names

fields @timestamp, @message
| parse @message '"file-path":"*","status-code":"*","bytes":*' as file_path, transfer_status, file_size
| filter ispresent(file_path) and ispresent(transfer_status) and ispresent(file_size)
| sort @timestamp desc
| limit 20

✅ Why?

Ensures missing values don’t cause incomplete results.



---

5. Extract from Nested Logs (if applicable)

fields @timestamp, bytes
| parse_json(@message) as log_data
| display log_data.file-path, log_data.status-code, log_data.bytes
| sort @timestamp desc
| limit 20

✅ Why?

If file-path, status-code, and bytes are nested inside the JSON structure.



---

6. Display Data in a Table Format

fields @timestamp, file_path, status_code, bytes
| parse @message '"file-path":"*","status-code":"*","bytes":*' as file_path, status_code, bytes
| sort @timestamp desc
| limit 20

✅ Why?

Formats extracted fields for better readability.



---

📌 Next Steps

Try running each query and check which one correctly extracts your file transfer details. Let me know if you need modifications! 🚀

