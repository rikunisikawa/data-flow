# Infra Checklist

## Must-keep invariants
- S3 layout remains `raw/`, `stage/`, `processed/`.
- `stage/` partitioning is `subject_id × activity_label`, excluding `activity_label=0`.
- Schema is 24 columns (last is `activity_label`), aligned to `convert_log_to_parquet`.
- dbt `cleaned_activities` extracts `user_id` from `$path` and computes 3-axis averages.
- Terraform uses `dev/prod` workspaces with workspace-prefixed resources.

## Required sync updates when changing schema/partition
- Glue Catalog table definition.
- dbt models and tests (e.g., `schema.yml`).
- Unit tests in `tests/` covering column count and partition paths.

## Guardrails
- Do not edit `.github/workflows/` directly.
- Keep IAM least-privilege and document any permission expansion.
- Avoid secret material in code or logs.

## Cross-file alignment
- `ai-doc/infra/system_design.md` and `ai-doc/infra/etl_flow.md` must stay consistent.
- Step Functions ASL and Terraform definitions must be updated together.
