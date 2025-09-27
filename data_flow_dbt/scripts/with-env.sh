#!/usr/bin/env bash
set -euo pipefail

# Resolve script directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Discover repo root by walking up until .git or .env(.example) is found
ROOT_DIR="${SCRIPT_DIR}"
while [[ "${ROOT_DIR}" != "/" ]]; do
  if [[ -d "${ROOT_DIR}/.git" || -f "${ROOT_DIR}/.env" || -f "${ROOT_DIR}/.env.example" ]]; then
    break
  fi
  ROOT_DIR="$(dirname -- "${ROOT_DIR}")"
done

# Determine ENV_FILE (priority: ENV_FILE -> .env -> .env.dev)
if [[ -n "${ENV_FILE:-}" ]]; then
  : # use provided ENV_FILE
elif [[ -f "${ROOT_DIR}/.env" ]]; then
  ENV_FILE="${ROOT_DIR}/.env"
elif [[ -f "${ROOT_DIR}/.env.dev" ]]; then
  ENV_FILE="${ROOT_DIR}/.env.dev"
else
  ENV_FILE=""
fi

if [[ -n "${ENV_FILE}" && -f "${ENV_FILE}" ]]; then
  # Export all variables defined in .env
  set -a
  # shellcheck disable=SC1090
  . "${ENV_FILE}"
  set +a
else
  echo "[with-env] No env file found. Checked: .env, .env.dev" >&2
  echo "[with-env] Create .env at repo root or use existing .env.dev, or set ENV_FILE=/path/to/file" >&2
fi

# Prefer project-local profiles if present
if [[ -f "${ROOT_DIR}/.dbt/profiles.yml" ]]; then
  export DBT_PROFILES_DIR="${ROOT_DIR}/.dbt"
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: data_flow_dbt/scripts/with-env.sh <command> [args...]" >&2
  echo " e.g.: data_flow_dbt/scripts/with-env.sh dbt debug" >&2
  exit 2
fi

# If invoking dbt without an explicit --project-dir, default to repo's data_flow_dbt
if [[ "$1" == "dbt" ]]; then
  # Determine the project directory: DBT_PROJECT_DIR env > <repo>/data_flow_dbt (if exists) > current
  TARGET_DIR=""
  if [[ -n "${DBT_PROJECT_DIR:-}" ]]; then
    TARGET_DIR="${DBT_PROJECT_DIR}"
  else
    CANDIDATE_DIR="${ROOT_DIR}/data_flow_dbt"
    if [[ -f "${CANDIDATE_DIR}/dbt_project.yml" ]]; then
      TARGET_DIR="${CANDIDATE_DIR}"
    fi
  fi

  if [[ -n "${TARGET_DIR}" ]]; then
    cd "${TARGET_DIR}"
    # Drop the leading 'dbt' and execute within the project dir
    shift
    exec dbt "$@"
  fi
fi

exec "$@"
