#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <env> <tag>" >&2
  echo "Example: $0 dev dev-latest" >&2
  exit 1
fi

ENV="$1"
TAG="$2"

case "$ENV" in
  dev|prod) ;;
  *)
    echo "Error: env must be 'dev' or 'prod'." >&2
    exit 1
    ;;
esac

REGION="ap-northeast-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ENV}-data-platform/dbt"

echo "Logging in to ECR: ${ECR_REPO}"
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Building dbt image: ${ECR_REPO}:${TAG}"
docker build \
  --platform linux/amd64 \
  -f docker/dbt/Dockerfile \
  -t "${ECR_REPO}:${TAG}" \
  .

echo "Pushing image to ECR: ${ECR_REPO}:${TAG}"
docker push "${ECR_REPO}:${TAG}"

cat <<EOF

Successfully pushed dbt image:
  Repository: ${ECR_REPO}
  Tag       : ${TAG}

Remember to update terraform/<env>.tfvars with:
  dbt_image_tag = "${TAG}"
before running terraform apply.
EOF
