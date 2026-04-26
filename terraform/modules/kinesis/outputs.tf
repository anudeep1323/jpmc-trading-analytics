output "stream_name" {
  value = aws_kinesis_stream.trades.name
}

output "stream_arn" {
  value = aws_kinesis_stream.trades.arn
}