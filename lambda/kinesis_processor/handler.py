import json
import boto3
import base64
from datetime import datetime

s3 = boto3.client('s3')
BUCKET_NAME = 'jpmc-trading-datalake-dev'

def lambda_handler(event, context):
    """
    Processes trade events from Kinesis stream.
    Validates, enriches, and saves to S3 bronze zone.
    """
    
    print(f"Received {len(event['Records'])} records from Kinesis")
    
    for record in event['Records']:
        # Decode Kinesis data
        payload = base64.b64decode(record['kinesis']['data'])
        trade = json.loads(payload)
        
        print(f"Processing trade: {trade.get('trade_id', 'UNKNOWN')}")
        
        # Validation
        if not validate_trade(trade):
            print(f"Invalid trade: {trade}")
            continue
        
        # Enrich with processing metadata
        trade['processed_at'] = datetime.utcnow().isoformat()
        trade['kinesis_sequence'] = record['kinesis']['sequenceNumber']
        
        # Check for large trades (risk alert)
        if trade.get('quantity', 0) > 5000:
            print(f"⚠️  LARGE TRADE ALERT: {trade['symbol']} - {trade['quantity']} shares")
        
        # Save to S3 bronze zone
        save_to_s3(trade)
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully processed {len(event["Records"])} trades')
    }

def validate_trade(trade):
    """Basic trade validation"""
    required_fields = ['trade_id', 'symbol', 'quantity', 'price']
    
    for field in required_fields:
        if field not in trade:
            print(f"Missing required field: {field}")
            return False
    
    if trade['quantity'] <= 0:
        print(f"Invalid quantity: {trade['quantity']}")
        return False
    
    if trade['price'] <= 0:
        print(f"Invalid price: {trade['price']}")
        return False
    
    return True

def save_to_s3(trade):
    """Save trade to S3 with date partitioning"""
    now = datetime.utcnow()
    
    # Partition by date
    s3_key = (
        f"bronze/trades/"
        f"year={now.year}/"
        f"month={now.month:02d}/"
        f"day={now.day:02d}/"
        f"trade_{trade['trade_id']}.json"
    )
    
    try:
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=s3_key,
            Body=json.dumps(trade, indent=2),
            ContentType='application/json'
        )
        print(f"✓ Saved to s3://{BUCKET_NAME}/{s3_key}")
    except Exception as e:
        print(f"Error saving to S3: {e}")
        raise