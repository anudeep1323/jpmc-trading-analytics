#!/usr/bin/env python3
"""
Generates fake trading data and sends to Kinesis stream.
Simulates real-time trade executions.
"""

import boto3
import json
import time
import random
from datetime import datetime

# Configuration
STREAM_NAME = 'jpmc-trading-trades-dev'
REGION = 'us-east-1'

# Initialize Kinesis client
kinesis = boto3.client('kinesis', region_name=REGION)

# Sample data
SYMBOLS = ['JPM', 'BAC', 'GS', 'MS', 'C', 'WFC', 'USB', 'PNC']
TRADERS = ['TRADER_001', 'TRADER_002', 'TRADER_003', 'TRADER_004', 'TRADER_005']

def generate_trade():
    """Generate a realistic fake trade"""
    return {
        'trade_id': f'T{int(time.time() * 1000)}',  # Unique ID based on timestamp
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'symbol': random.choice(SYMBOLS),
        'quantity': random.randint(100, 10000),
        'price': round(random.uniform(50.0, 200.0), 2),
        'trader_id': random.choice(TRADERS),
        'side': random.choice(['BUY', 'SELL']),
        'trade_type': random.choice(['MARKET', 'LIMIT'])
    }

def send_to_kinesis(trade):
    """Send trade to Kinesis stream"""
    try:
        response = kinesis.put_record(
            StreamName=STREAM_NAME,
            Data=json.dumps(trade),
            PartitionKey=trade['symbol']  # Partition by symbol for ordering
        )
        
        return response
    except Exception as e:
        print(f"❌ Error sending to Kinesis: {e}")
        return None

def main():
    print(f"🚀 Starting trade generator...")
    print(f"📊 Sending trades to Kinesis stream: {STREAM_NAME}")
    print(f"⏱️  Sending 1 trade every 2 seconds")
    print(f"\n{'='*70}\n")
    
    trade_count = 0
    
    try:
        for i in range(20):  # Send 20 trades
            # Generate trade
            trade = generate_trade()
            
            # Send to Kinesis
            response = send_to_kinesis(trade)
            
            if response:
                trade_count += 1
                shard_id = response.get('ShardId', 'unknown')
                
                # Color coding for large trades
                if trade['quantity'] > 5000:
                    print(f"🔴 LARGE TRADE #{trade_count}")
                else:
                    print(f"✅ Trade #{trade_count}")
                
                print(f"   ID: {trade['trade_id']}")
                print(f"   {trade['side']} {trade['quantity']} {trade['symbol']} @ ${trade['price']}")
                print(f"   Trader: {trade['trader_id']}")
                print(f"   Shard: {shard_id}")
                print(f"   Time: {datetime.now().strftime('%H:%M:%S.%f')[:-3]}")
                print()
            
            # Wait 2 seconds between trades
            time.sleep(2)
        
        print(f"\n{'='*70}")
        print(f"✅ Successfully sent {trade_count} trades to Kinesis!")
        print(f"\n💡 Check Lambda logs and S3 to see processed trades:")
        print(f"   - CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region={REGION}#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fjpmc-trading-kinesis-processor-dev")
        print(f"   - S3: https://s3.console.aws.amazon.com/s3/buckets/jpmc-trading-datalake-dev?region={REGION}&prefix=bronze/trades/")
        
    except KeyboardInterrupt:
        print(f"\n\n⚠️  Interrupted! Sent {trade_count} trades before stopping.")

if __name__ == '__main__':
    main()