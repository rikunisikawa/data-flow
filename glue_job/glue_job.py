import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

## @params: JOB_NAME
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

## @type: datasource
## @args: [database, table_name, transformation_ctx]
## @return: datasource0
## @inputs: []
datasource0 = glueContext.create_dynamic_frame.from_catalog(database="default", table_name="stage", transformation_ctx="datasource0")

## @type: applymapping
## @args: [mappings, transformation_ctx]
## @return: applymapping1
## @inputs: [datasource0]
applymapping1 = ApplyMapping.apply(frame = datasource0, mappings = [("id", "string", "id", "string"), ("timestamp", "string", "timestamp", "timestamp"), ("accel_x", "double", "accel_x", "double"), ("accel_y", "double", "accel_y", "double"), ("accel_z", "double", "accel_z", "double")], transformation_ctx = "applymapping1")

## @type: selectfields
## @args: [paths, transformation_ctx]
## @return: selectfields2
## @inputs: [applymapping1]
selectfields2 = SelectFields.apply(frame = applymapping1, paths = ["id", "timestamp", "accel_x", "accel_y", "accel_z"], transformation_ctx = "selectfields2")

## @type: writedataframe
## @args: [frame, transformation_ctx]
## @return: writeparquet3
## @inputs: [selectfields2]
writeparquet3 = glueContext.write_dynamic_frame.from_options(frame = selectfields2, connection_type = "s3", connection_options = {"path": "s3://aws-data-platform-20250607/processed/"}, format = "parquet", transformation_ctx = "writeparquet3")

job.commit()
