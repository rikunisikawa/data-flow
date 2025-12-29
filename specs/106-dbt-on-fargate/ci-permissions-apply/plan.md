# 計画: CI/CD で IAM 権限更新を先行適用する

**Branch**: `feature/106-dbt-on-fargate` | **Owner**: Data Platform | **Date**: 2025-10-03

## 目的
- CI/CD で IAM 権限変更がある場合、まず権限のみを apply してから全体 apply を実行する。
- `AccessDenied` による失敗を回避する。

## スコープ
- 追加: ワークフローの権限先行適用ステップ（提案のみ）
- 非対象: `.github/workflows/` の直接編集

## 方針/設計
- `-target` で IAM ポリシーを先に適用する。
- その後に通常の `terraform apply` を実行する。

## 対象リソース
- `aws_iam_role_policy.github_actions_terraform_deploy_policy`
- `aws_iam_role_policy.sfn_execution_policy`

## DoD（受入基準）
- IAM 変更が含まれる場合でも CI の apply が成功する。
- 通常の apply で他リソースが更新される。
