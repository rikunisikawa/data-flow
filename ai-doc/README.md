# ai-doc README — ドキュメント案内

本フォルダは、本プロジェクト（mHealth データの ETL/分析基盤）の設計・運用・実行手順をまとめたナレッジベースです。初めて触れる方は「読み順のおすすめ」から確認してください。

## 読み順のおすすめ
- 全体像: `ai-doc/infra/system_design.md`
- データフロー/依存関係: `ai-doc/infra/etl_flow.md`
- dbt（Athena/Glue）セットアップ・実行: `ai-doc/infra/dbt_athena_setup.md`
- dbt 運用・設計メモ/トラブルシュート: `ai-doc/infra/dbt_usage_and_design.md`
- Terraform/デプロイ運用: `ai-doc/operations/deployment_strategy.md`, `ai-doc/infra/terraform-design.md`

## アーキテクチャ/フロー
- `ai-doc/infra/system_design.md`: システム全体の役割分担（Lambda/Step Functions/dbt/Athena/S3/Glue）、スキーマ方針、入出力先の設計。
- `ai-doc/infra/etl_flow.md`: Mermaid 図による ETL と dbt モデルのリネージ（入力→中間→出力）。
- `ai-doc/infra/aws_architecture_diagram.md`: AWS コンポーネントの構成図（補助資料）。

## dbt（Athena + Glue）
- `ai-doc/infra/dbt_athena_setup.md`: 実行手順（ローカル実行と Docker 実行の両方）、profiles/env の設定、dbt docs の生成/配信方法。
  - Docker 例: `docker compose -f docker/dbt/docker-compose.yml up -d` → `exec dbt bash` → `dbt docs serve --host 0.0.0.0 --port 8080`。
- `ai-doc/infra/dbt_usage_and_design.md`: 実行コマンド一覧、必要環境変数、モデル設計の要点、トラブルシュート（AccessDenied/WorkGroup/型不一致など）。
- `ai-doc/infra/dbt_environment_overview.md`: プロファイル構成と接続タイプ（athena）整理。
- 実プロジェクト: `data_flow_dbt/dbt_project.yml`, `data_flow_dbt/models/`（`src_mhealth.yml`/`schema.yml` で Docs 用メタデータを定義）。

## Orchestration（Step Functions）
- ステートマシン定義: `state_machine/` 配下の ASL JSON（Download → Convert → dbt など）。
- 変更時は Terraform の参照テンプレートと整合を取る（`AGENTS.md` 参照）。

## データ/スキーマ
- 入力データ（mHealth）とパーティション戦略、変更時の影響範囲は `AGENTS.md` に集約。
- 変換列・出力スキーマは dbt モデル（`data_flow_dbt/models/*.sql`）および `schema.yml` に記述。

## 運用/デプロイ
- `ai-doc/operations/deployment_strategy.md`: Terraform + Layer ビルド/アップロード、docker-compose での Terraform 実行フロー。
- `ai-doc/operations/workflow-usage.md`: ワークフロー利用ガイド（Issue 起票〜自動生成の運用方針）。
- `ai-doc/infra/terraform-design.md`: Terraform 設計やワークスペース分離（dev/prod）方針。

## Notebook/分析
- `notebooks/README.md`: ノートブックの前提・実行メモ（Athena/awswrangler 前提）。
- `notebooks/01_eda_modeling.ipynb`: Athena からの特徴量取得、前処理、Group ベース分割、学習・評価の PoC。

## トラブルシュート/ヒント
- `ai-doc/tips/troubleshooting-notebook-mermaid.md`: Notebook JSON 破損時や Mermaid 図の復旧手順。
- `ai-doc/tips/install-spec-kit.md`: spec-kit の導入メモ。
- `ai-doc/tips/gemini-cli-tips.md`: Gemini CLI の Tips。

## ルール/原則
- `AGENTS.md`: コーディング原則（安全・一貫・冪等・テスト・コスト）、データ/スキーマの前提、Lambda/Step Functions/dbt/Glue/Terraform/テストのガイドライン。

## よく使うコマンド（抜粋）
- dbt（ローカル）:
  - `./data_flow_dbt/scripts/with-env.sh dbt debug`
  - `./data_flow_dbt/scripts/with-env.sh dbt run -m cleaned_activities`
  - `./data_flow_dbt/scripts/with-env.sh dbt docs generate && ./data_flow_dbt/scripts/with-env.sh dbt docs serve --port 8080 --no-browser`
- dbt（Docker）:
  - `docker compose -f docker/dbt/docker-compose.yml up -d`
  - `docker compose -f docker/dbt/docker-compose.yml exec dbt bash`
  - `dbt docs generate && dbt docs serve --host 0.0.0.0 --port 8080 --no-browser`

## 補足
- dbt Docs のメタデータ（Models/Sources の Description/Tests）は `data_flow_dbt/models/schema.yml` と `data_flow_dbt/models/src_mhealth.yml` に登録済み。反映には `dbt docs generate` の再実行が必要です。
- 追加の図版/設計資料が増えた場合は、本 README に追記して参照性を維持してください。

