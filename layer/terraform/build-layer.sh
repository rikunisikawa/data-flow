#!/bin/bash
set -euo pipefail

# 引数から環境名を取得
if [ $# -eq 0 ]; then
    echo "Usage: $0 <dev|prod>"
    exit 1
fi
readonly ENV="$1"

# スクリプトが配置されているディレクトリに移動
cd "$(dirname "$0")"

# 定数
readonly ARTIFACTS_DIR="artifacts"
readonly DOCKER_IMAGE_NAME="kaggle-layer-builder"
readonly DOCKER_CONTAINER_NAME="temp-builder"

# ビルドディレクトリのクリーンアップと作成
echo "Cleaning up and creating artifacts directory..."
rm -rf "${ARTIFACTS_DIR}"
mkdir -p "${ARTIFACTS_DIR}/python"

# Dockerイメージのビルド
echo "Building layer with custom Dockerfile for x86_64 architecture..."
docker build --platform linux/amd64 --no-cache -t "${DOCKER_IMAGE_NAME}" ../src

# Dockerコンテナから依存関係をコピー
echo "Copying dependencies from Docker container..."
docker create --name "${DOCKER_CONTAINER_NAME}" "${DOCKER_IMAGE_NAME}"
docker cp "${DOCKER_CONTAINER_NAME}:/var/task/dependencies/." "${ARTIFACTS_DIR}/python"
docker rm -v "${DOCKER_CONTAINER_NAME}"

# 不要ファイルの削除
echo "Removing unnecessary files from layer..."
find "${ARTIFACTS_DIR}/python" -type d -name "__pycache__" -exec rm -rf {} +
find "${ARTIFACTS_DIR}/python" -type f -name "*.pyc" -delete

# レイヤーのzip化
echo "Zipping the layer..."
cd "${ARTIFACTS_DIR}"
zip -r "../../../build/layer.zip" python/
cd ..

echo "Successfully created layer.zip in build directory"

# S3へのアップロード
echo "Determining S3 bucket based on environment: $ENV"

if [ "$ENV" = "dev" ]; then
    LAYER_BUCKET_NAME="dev-aws-data-platform-20250607"
elif [ "$ENV" = "prod" ]; then
    LAYER_BUCKET_NAME="prod-aws-data-platform-20250607"
else
    echo "Error: Invalid environment specified. Use 'dev' or 'prod'." >&2
    exit 1
fi

LAYER_S3_KEY="layers/layer.zip" # S3のキー

echo "Uploading ../../build/layer.zip to s3://${LAYER_BUCKET_NAME}/${LAYER_S3_KEY}"
aws s3 cp "../../build/layer.zip" "s3://${LAYER_BUCKET_NAME}/${LAYER_S3_KEY}"

echo "Successfully uploaded layer.zip to S3"