#!/bin/bash
set -euo pipefail

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
LAYER_BUCKET_NAME="$1" # 最初の引数をバケット名として取得
LAYER_S3_KEY="layers/layer.zip" # S3のキー

echo "Uploading build/layer.zip to s3://${LAYER_BUCKET_NAME}/${LAYER_S3_KEY}"
aws s3 cp "../build/layer.zip" "s3://${LAYER_BUCKET_NAME}/${LAYER_S3_KEY}"

echo "Successfully uploaded layer.zip to S3"
