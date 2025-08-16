#!/bin/bash

set -e

# Create build directory if it doesn't exist
mkdir -p build

# Zip download_and_upload function
cd download_and_upload
zip -r ../build/download_and_upload.zip .
cd ..

# Zip convert_log_to_parquet function
cd convert_log_to_parquet
zip -r ../build/convert_log_to_parquet.zip .
cd ..

# Build Lambda Layer
bash layer/terraform/build-layer.sh

echo "All Lambda deployment packages created in the 'build/' directory."
