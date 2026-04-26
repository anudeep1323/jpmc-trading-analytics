resource "aws_kinesis_stream" "trades" {
  name             = "${var.project_name}-trades-${var.environment}"
  shard_count      = 1
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
  ]

  tags = {
    Name = "trades-stream"
  }
}