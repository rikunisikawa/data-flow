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

# Zip Fitbit webhook handler
zip -r build/fitbit_webhook_handler.zip fitbit_webhook_handler fitbit_common

# Zip Fitbit fetcher
zip -r build/fitbit_fetcher.zip fitbit_fetcher fitbit_common

# Zip Fitbit poller
zip -r build/fitbit_poller.zip fitbit_poller fitbit_common

# Build Lambda Layer
bash layer/terraform/build-layer.sh "$1"

echo "All Lambda deployment packages created in the 'build/' directory."
