---
name: operating-mhealth-services
description: Operates and deploys the mHealth ETL platform. Use when running build/deploy steps, Terraform applies, dbt/Elementary execution, or documenting runbooks and operational procedures.
---

# Operating mHealth Services

## Goal
Provide safe, repeatable operational steps for deployment and runtime procedures.

## Inputs
- Target environment (`dev` or `prod`).
- Change scope (Lambda/Layer/dbt image/Terraform/runbook).

## Workflow
1. Review `ai-doc/operations/deployment_strategy.md` and `ai-doc/infra/terraform-design.md`.
2. Follow the checklist in `references/operations-checklist.md`.
3. If dbt is involved, confirm env vars and preferred execution method (local wrapper or Docker).
4. Document the runbook steps and rollback note for any operational change.

## Output expectations
- Ordered runbook steps (build → upload → terraform apply).
- Explicit environment selection and image tag alignment.

## References
- `references/operations-checklist.md`
