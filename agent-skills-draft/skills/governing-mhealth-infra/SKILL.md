---
name: governing-mhealth-infra
description: Governs infrastructure and data-contract changes for the mHealth ETL platform. Use when updating Lambda/Step Functions/Glue/Athena/dbt/Terraform, changing S3 paths, schemas, partitions, IAM, or environment/workspace rules.
---

# Governing mHealth Infrastructure

## Goal
Maintain consistent infrastructure and data contracts for the mHealth ETL platform while preventing unsafe or incompatible changes.

## Inputs
- Target files or components (Lambda/Step Functions/Glue/Athena/dbt/Terraform).
- Intended change (schema, partition, IAM, S3 path, workspace behavior).

## Workflow
1. Read `AGENTS.md` for invariants (schema, partitions, tests, secrets).
2. Review `ai-doc/infra/` and `ai-doc/operations/` for current design and runbooks.
3. Run the checklist in `references/infra-checklist.md`.
4. If schema/partition changes are involved, list required downstream updates (Glue Catalog, dbt models, tests).
5. If Step Functions changes are involved, update ASL JSON and Terraform together.
6. If IAM changes are involved, document scope and least-privilege rationale.
7. Summarize impact and open TODOs before implementation.

## Output expectations
- A short impact summary (what changes, what must be updated, what can break).
- A concrete update list for schema/partitions/IAM.

## References
- `references/infra-checklist.md`
