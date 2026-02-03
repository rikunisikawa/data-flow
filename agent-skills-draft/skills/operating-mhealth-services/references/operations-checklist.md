# Operations Checklist

## Deployment sequence
1. Run `build.sh <env>` to build Lambda/Layer artifacts and upload to S3.
2. Ensure dbt image tag matches `terraform/<env>.tfvars` (`dbt_image_tag`).
3. Run Terraform with explicit workspace selection (`dev`/`prod`).

## dbt execution
- Prefer `data_flow_dbt/scripts/with-env.sh` or Docker (`docker/dbt/docker compose.yml`).
- Validate required env vars: `S3_STAGING_DIR`, `S3_DATA_DIR`, `AWS_REGION`, `GLUE_DATABASE`, `DBT_SCHEMA`, `ATHENA_WORK_GROUP`.

## Operational notes
- Do not treat `terraform-deploy-workflow-change-proposal.md` as an implemented workflow.
- Keep a short rollback note when steps modify deployment or runtime behavior.
