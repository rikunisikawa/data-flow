---
name: governing-mhealth-infra
description: mHealth ETL 基盤のインフラとデータ契約の変更を統制する。Lambda/Step Functions/Glue/Athena/dbt/Terraform、S3 パス、スキーマ、パーティション、IAM、workspace/環境ルールを変更する場合に使用。
---

検証コード: SKILL_CANARY_9f3b7

# mHealth インフラ統制

## 目的
mHealth ETL 基盤のインフラとデータ契約の整合性を保ち、危険・非互換な変更を防ぐ。

## 使用する場面
- スキーマ、パーティション、S3 レイアウトを変更するとき。
- Lambda、Step Functions、Glue、dbt、Terraform の基盤動作を変えるとき。
- IAM ポリシーや workspace/環境ルールを変更するとき。

## 入力
- 対象ファイル/コンポーネント（Lambda/Step Functions/Glue/Athena/dbt/Terraform）。
- 変更内容（スキーマ、パーティション、IAM、S3 パス、workspace の挙動）。

## 手順
1. `AGENTS.md` の不変条件（スキーマ、パーティション、テスト、秘密情報）を確認する。
2. `ai-doc/infra/` と `ai-doc/operations/` で設計/運用方針を確認する。
3. `references/infra-checklist.md` のチェックリストを実行する。
4. スキーマ/パーティション変更がある場合、必要な下流更新（Glue Catalog、dbt モデル、テスト）を列挙する。
5. Step Functions 変更がある場合、ASL JSON と Terraform を同時に更新する。
6. IAM 変更がある場合、スコープと最小権限の理由を記録する。
7. 影響範囲と未決事項（TODO）を先に要約してから実装する。

## 出力期待
- 影響範囲の短い要約（変更点、必要更新、破壊可能性）。
- スキーマ/パーティション/IAM の具体的な更新リスト。

## 参照
- `references/infra-checklist.md`
