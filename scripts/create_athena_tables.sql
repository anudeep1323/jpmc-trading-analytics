-- Create external table pointing to Silver zone Parquet files
CREATE EXTERNAL TABLE IF NOT EXISTS jpmc_trading_dev.trades_silver (
    trade_id STRING,
    timestamp TIMESTAMP,
    symbol STRING,
    quantity BIGINT,
    price DOUBLE,
    trader_id STRING,
    side STRING,
    trade_type STRING,
    processed_at STRING,
    kinesis_sequence STRING
)
STORED AS PARQUET
LOCATION 's3://jpmc-trading-datalake-dev/silver/trades/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');