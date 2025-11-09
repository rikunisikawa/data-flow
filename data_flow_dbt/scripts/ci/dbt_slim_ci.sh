#!/usr/bin/env bash
set -euo pipefail

STATE_DIR=${1:-"state"}
TARGET_PATH=${2:-"target"}

if [ -d "$STATE_DIR" ]; then
  echo "Restoring previous dbt state from $STATE_DIR"
  mkdir -p "$TARGET_PATH"
  cp -r "$STATE_DIR"/* "$TARGET_PATH"/ || true
fi

dbt deps

dbt seed --select activity_labels --full-refresh

dbt build --selector state_modified_plus_seeds --state "$STATE_DIR" --defer --target prod

dbt docs generate

DBT_TARGET_PATH="$TARGET_PATH" python scripts/ci/upload_artifacts.py
