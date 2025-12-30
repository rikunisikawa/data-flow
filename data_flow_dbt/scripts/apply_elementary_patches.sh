#!/usr/bin/env bash
set -euo pipefail

DEFAULT_CONTAINER_PATH="/work/data_flow_dbt/dbt_packages/elementary/macros/edr/data_monitoring/monitors_query/column_monitoring_query.sql"
DEFAULT_LOCAL_PATH="data_flow_dbt/dbt_packages/elementary/macros/edr/data_monitoring/monitors_query/column_monitoring_query.sql"

TARGET_PATH="${1:-}"

if [ -z "${TARGET_PATH}" ]; then
  if [ -f "${DEFAULT_CONTAINER_PATH}" ]; then
    TARGET_PATH="${DEFAULT_CONTAINER_PATH}"
  elif [ -f "${DEFAULT_LOCAL_PATH}" ]; then
    TARGET_PATH="${DEFAULT_LOCAL_PATH}"
  else
    echo "Error: column_monitoring_query.sql not found." >&2
    exit 1
  fi
fi

if [ ! -f "${TARGET_PATH}" ]; then
  echo "Error: file not found: ${TARGET_PATH}" >&2
  exit 1
fi

TARGET_PATH="${TARGET_PATH}" python - <<'PY'
import re
from pathlib import Path
import sys
import os

path = Path(os.environ["TARGET_PATH"])
content = path.read_text()

pattern = re.compile(
    r"(\{\{\s*elementary\.null_timestamp\(\)\s*\}\}\s+as start_bucket_in_data)\s*,\s*\n(\s*from monitored_table)"
)

updated, count = pattern.subn(r"\\1\\n\\2", content)
if count == 0:
    print(f"[elementary patch] No changes applied: {path}")
    sys.exit(0)

path.write_text(updated)
print(f"[elementary patch] Applied ({count} change): {path}")
PY
