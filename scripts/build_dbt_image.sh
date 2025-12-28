#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <env> <tag> [--update-tfvars] [--tfvars-path <path>] [--region <region>]" >&2
  echo "Example: $0 dev dev-latest --update-tfvars" >&2
  exit 1
fi

ENV="$1"
TAG="$2"
shift 2

UPDATE_TFVARS="false"
TFVARS_PATH=""
REGION="ap-northeast-1"

while [ $# -gt 0 ]; do
  case "$1" in
    --update-tfvars)
      UPDATE_TFVARS="true"
      shift
      ;;
    --tfvars-path)
      if [ $# -lt 2 ]; then
        echo "Error: --tfvars-path requires a value." >&2
        exit 1
      fi
      TFVARS_PATH="$2"
      shift 2
      ;;
    --region)
      if [ $# -lt 2 ]; then
        echo "Error: --region requires a value." >&2
        exit 1
      fi
      REGION="$2"
      shift 2
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      exit 1
      ;;
  esac
done

case "$ENV" in
  dev|prod) ;;
  *)
    echo "Error: env must be 'dev' or 'prod'." >&2
    exit 1
    ;;
esac

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: aws CLI is required." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is required." >&2
  exit 1
fi

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

if [ "${UPDATE_TFVARS}" = "true" ]; then
  if [ -z "${TFVARS_PATH}" ]; then
    TFVARS_PATH="terraform/${ENV}.tfvars"
  fi

  if [ ! -f "${TFVARS_PATH}" ]; then
    echo "Error: tfvars file not found: ${TFVARS_PATH}" >&2
    exit 1
  fi

  python - <<PY
from pathlib import Path
import re

path = Path("${TFVARS_PATH}")
text = path.read_text()
pattern = re.compile(r"^\\s*dbt_image_tag\\s*=.*\$", re.M)
replacement = f'dbt_image_tag = "{TAG}"'

if pattern.search(text):
    text = pattern.sub(replacement, text)
else:
    if text and not text.endswith("\\n"):
        text += "\\n"
    text += replacement + "\\n"

path.write_text(text)
PY

  echo "Updated ${TFVARS_PATH} with dbt_image_tag = \"${TAG}\""
fi

cat <<EOF

Successfully pushed dbt image:
  Repository: ${ECR_REPO}
  Tag       : ${TAG}

Remember to keep terraform/<env>.tfvars in sync:
  dbt_image_tag = "${TAG}"
before running terraform apply (if not updated automatically).
EOF
