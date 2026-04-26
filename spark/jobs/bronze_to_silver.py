import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'BUCKET_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

bucket_name = args['BUCKET_NAME']

print(f"Reading from s3://{bucket_name}/bronze/trades/")

# Job bookmarks automatically track what's been processed
datasource = glueContext.create_dynamic_frame.from_options(
    format_options={"multiline": False},
    connection_type="s3",
    format="json",
    connection_options={
        "paths": [f"s3://{bucket_name}/bronze/trades/"],
        "recurse": True
    },
    transformation_ctx="datasource"  # Required for job bookmarks
)

print(f"Count: {datasource.count()}")

# Convert to DataFrame
df = datasource.toDF()

print("Sample data:")
df.show(5, truncate=False)

# Write to silver
print(f"Writing to s3://{bucket_name}/silver/trades/")

# Convert back to DynamicFrame for write with bookmarks
output_dyf = DynamicFrame.fromDF(df, glueContext, "output_dyf")

glueContext.write_dynamic_frame.from_options(
    frame=output_dyf,
    connection_type="s3",
    connection_options={
        "path": f"s3://{bucket_name}/silver/trades/",
    },
    format="parquet",
    transformation_ctx="output_silver"  # Required for job bookmarks
)

print("Job completed!")
job.commit()