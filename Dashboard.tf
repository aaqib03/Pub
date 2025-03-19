resource "aws_cloudwatch_dashboard" "sftp_transfer_dashboard" {
  dashboard_name = "SFTP-Transfer-Dashboard"

  dashboard_body = <<DASHBOARD
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Transfer", "SuccessfulFileTransfers", "ConnectorId", "c-b223f7ee313e426db"],
                    ["AWS/Transfer", "FailedFileTransfers", "ConnectorId", "c-b223f7ee313e426db"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "eu-central-1",
                "title": "📊 Successful vs Failed File Transfers",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Transfer", "FileTransferTime", "ConnectorId", "c-b223f7ee313e426db"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "eu-central-1",
                "title": "⏱ Average File Transfer Time per Connector",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Transfer", "BytesTransferred", "ConnectorId", "c-b223f7ee313e426db"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "eu-central-1",
                "title": "📦 Total Bytes Transferred Per Connector",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Transfer", "OngoingFileTransfers", "ConnectorId", "c-b223f7ee313e426db"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "eu-central-1",
                "title": "📡 Live File Transfer Tracking",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Transfer", "TransferErrors", "ConnectorId", "c-b223f7ee313e426db"]
                ],
                "view": "singleValue",
                "region": "eu-central-1",
                "title": "🚨 Active Transfer Errors",
                "period": 300,
                "stat": "Sum"
            }
        }
    ]
}
DASHBOARD
}