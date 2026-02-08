---
name: operating-mhealth-services
description: mHealth ETL 基盤の運用・デプロイを扱う。build/deploy、Terraform apply、dbt/Elementary 実行、運用手順の整備に使用。
---

# mHealth 運用スキル

## 目的
安全で再現性のある運用手順（デプロイ/実行）を提示する。

## 使用する場面
- `build.sh` 実行や成果物のアップロード、Terraform apply を行うとき。
- dbt / Elementary をローカルまたは Docker で実行するとき。
- ランブックや運用手順を新規作成・更新するとき。

## 入力
- 対象環境（`dev` または `prod`）。
- 変更範囲（Lambda/Layer/dbt イメージ/Terraform/ランブック）。

## 手順
1. `ai-doc/operations/deployment_strategy.md` と `ai-doc/infra/terraform-design.md` を確認する。
2. `references/operations-checklist.md` のチェックリストを実行する。
3. dbt が関係する場合、必要な環境変数と実行方法（ローカル/ Docker）を確認する。
4. 運用変更がある場合、手順とロールバックメモを明記する。

## 出力期待
- 実行順序のあるランブック手順（build → upload → terraform apply）。
- 環境選択とイメージタグ整合の明示。

## 参照
- `references/operations-checklist.md`
