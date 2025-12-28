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

cleanup_container() {
  if docker ps -a --format '{{.Names}}' | grep -qx "${DOCKER_CONTAINER_NAME}"; then
    echo "Cleaning up existing container ${DOCKER_CONTAINER_NAME}..."
    docker rm -f "${DOCKER_CONTAINER_NAME}" >/dev/null 2>&1 || true
  fi
}

trap cleanup_container EXIT

# ビルドディレクトリのクリーンアップと作成
echo "Cleaning up and creating artifacts directory..."
rm -rf "${ARTIFACTS_DIR}"
mkdir -p "${ARTIFACTS_DIR}/python"

# Dockerイメージのビルド
echo "Building layer with custom Dockerfile for x86_64 architecture..."
docker build --platform linux/amd64 --no-cache -t "${DOCKER_IMAGE_NAME}" ../src

# Dockerコンテナから依存関係をコピー
cleanup_container

echo "Copying dependencies from Docker container..."
docker create --name "${DOCKER_CONTAINER_NAME}" "${DOCKER_IMAGE_NAME}"
docker cp "${DOCKER_CONTAINER_NAME}:/var/task/dependencies/." "${ARTIFACTS_DIR}/python"
docker rm -v "${DOCKER_CONTAINER_NAME}" >/dev/null 2>&1 || true

# 不要ファイルの削除
echo "Removing unnecessary files from layer..."
find "${ARTIFACTS_DIR}/python" -type d -name "__pycache__" -exec rm -rf {} +
find "${ARTIFACTS_DIR}/python" -type f -name "*.pyc" -delete

# Prune heavy optional dependencies that are not required at runtime
# pyarrow is not used (we use fastparquet) and easily exceeds the 250MB unzipped limit
if [ -d "${ARTIFACTS_DIR}/python" ]; then
  find "${ARTIFACTS_DIR}/python" -maxdepth 1 -type d -name "pyarrow*" -exec rm -rf {} + || true
  find "${ARTIFACTS_DIR}/python" -maxdepth 1 -type d -name "pyarrow.libs" -exec rm -rf {} + || true
  find "${ARTIFACTS_DIR}/python" -maxdepth 1 -type d -name "pyarrow-*.dist-info" -exec rm -rf {} + || true
  # Drop build-time tools if accidentally included
  find "${ARTIFACTS_DIR}/python" -maxdepth 1 -type d \( -name "pip*" -o -name "setuptools*" -o -name "wheel*" \) -exec rm -rf {} + || true
fi

# 事前サイズチェック（解凍後サイズの上限 262,144,000 bytes = 250MB）
MAX_UNZIPPED_SIZE=262144000
LAYER_DIR_PATH="${ARTIFACTS_DIR}/python"
UNZIPPED_SIZE_BYTES=$(du -sb "$LAYER_DIR_PATH" | awk '{print $1}')
UNZIPPED_SIZE_MB=$(awk -v b="$UNZIPPED_SIZE_BYTES" 'BEGIN { printf "%.2f", b/1024/1024 }')
MAX_UNZIPPED_SIZE_MB=$(awk -v b="$MAX_UNZIPPED_SIZE" 'BEGIN { printf "%.2f", b/1024/1024 }')

echo "Layer unzipped size (pre-zip): ${UNZIPPED_SIZE_BYTES} bytes (${UNZIPPED_SIZE_MB} MB)"
echo "AWS Lambda layer unzipped limit: ${MAX_UNZIPPED_SIZE} bytes (${MAX_UNZIPPED_SIZE_MB} MB)"

if [ "$UNZIPPED_SIZE_BYTES" -gt "$MAX_UNZIPPED_SIZE" ]; then
  echo "ERROR: レイヤーの解凍後サイズが上限を超えています。Terraform で 'InvalidParameterValueException: Unzipped size must be smaller than 262144000 bytes' のエラーになります。" >&2
  echo "対処: 不要依存を除外（例: pyarrow）, 依存の分割, あるいはコンテナイメージ化を検討してください。" >&2
  exit 1
fi

# レイヤーのzip化
echo "Zipping the layer..."
cd "${ARTIFACTS_DIR}"
zip -r "../../../build/layer.zip" python/
cd ..

echo "Successfully created layer.zip in build directory"

# zipファイルのサイズ情報も表示
ZIP_SIZE_BYTES=$(stat -c%s "../../build/layer.zip" 2>/dev/null || wc -c < "../../build/layer.zip")
ZIP_SIZE_MB=$(awk -v b="$ZIP_SIZE_BYTES" 'BEGIN { printf "%.2f", b/1024/1024 }')
echo "Layer zip size (compressed): ${ZIP_SIZE_BYTES} bytes (${ZIP_SIZE_MB} MB)"

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
