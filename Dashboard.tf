resource "aws_cloudwatch_dashboard" "sftp_dashboard" {
  dashboard_name = "SFTP-Transfer-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type": "log",
        "x": 0,
        "y": 18,
        "width": 24,
        "height": 6,
        "properties": {
          "query": "SOURCE '/aws/transfer/your-log-group-name' | fields @timestamp, file-path as FileName, bytes as FileSize, status-code as TransferStatus, (end-time - start-time)/60000 as TimeTakenMinutes | sort @timestamp desc | limit 100",
          "region": "eu-central-1",
          "title": "📋 File Transfer Logs - Last 100 Transfers",
          "view": "table"
        }
      }
    ]
  })
}


fields @timestamp, 
       file-path as FileName, 
       bytes as FileSize, 
       status-code as TransferStatus, 
       start-time, 
       end-time, 
       (date_diff(end-time, start-time, 'millisecond') / 60000) as TimeTakenMinutes
| sort @timestamp desc
| limit 100



{
  "widgets": [
    {
      "type": "log",
      "properties": {
        "query": "fields @timestamp, file-path as FileName, bytes as FileSize, status-code as TransferStatus, start-time, end-time, (date_diff(end-time, start-time, 'millisecond') / 60000) as TimeTakenMinutes | sort @timestamp desc | limit 100",
        "region": "eu-central-1",
        "title": "File Transfer Logs - Last 100 Transfers",
        "logGroupNames": ["/aws/lambda/sftp-transfer-logs"]
      }
    }
  ]
}