# Plan Checklist

## Plan alignment
- Confirm deliverable paths and naming (models, scripts, reports).
- Validate required dbt tests (`dbt test`) are included in completion criteria.

## Execution order (recommended)
1. Define/validate sources.
2. Build staging models.
3. Build intermediate/feature models.
4. Run tests and validate outputs.

## Divergence handling
- Record TODOs if plan conflicts with Terraform migration state or current architecture.
- Propose plan updates instead of silently changing scope.
