# 計画: dbt を Fargate で実行し Step Functions に統合

**Branch**: `106-dbt-on-fargate` | **Owner**: Data Platform | **Date**: 2025-09-27

## 目的
- dbt（Athena adapter）の実行をコンテナ化し、ECS Fargate 上で安定・再現可能に実行。
- 既存の Step Functions に dbt 実行ステップを組み込み、Download→Convert→dbt の一連をサーバレスで自動化。

## スコープ
- 追加: ECR リポジトリ、ECS クラスター/タスク定義（Fargate）、実行/タスクロール、CloudWatch Logs。
- 変更: Step Functions（ECS RunTask ステップ追加/置換）、`ai-doc` 更新。
- 非対象: Glue、Lambda 本体の置換や大幅改修（最小変更）。

## 方針/設計
- イメージ: 既存の `docker/dbt/Dockerfile` をベースに ECR へ push（タグ: `dbt:<env>-<version>`）。
- 実行: Fargate タスク（例: 0.5 vCPU/1GB〜1 vCPU/2GB）。コマンド例: `dbt run -m cleaned_activities && dbt test`。
- 環境変数: `.env.dev` 相当をタスク定義の env/secret で注入（`S3_STAGING_DIR`, `DBT_SCHEMA`, `GLUE_STAGE_DATABASE`, `ATHENA_WORK_GROUP` など）。
- ネットワーク: パブリックサブネット + IGW（AssignPublicIp=ENABLED で ECR/S3/Athena へ到達、NAT なし）。
- 権限: 実行ロール（ECR pull）、タスクロール（Athena/Glue/S3/CloudWatch Logs 最小権限）。
- ログ: CloudWatch Logs に集約（dbt の JSON 風単行ログ方針に準拠）。

## フェーズ
1) コンテナ提供: ECR 作成・ビルド/プッシュ経路整備（手動/CI）。
2) 実行基盤: ECS（Fargate）と IAM/ログ/ネットワークの IaC 化（Terraform）。
3) オーケストレーション: Step Functions に ECS RunTask ステップを追加し、前後の入出力整合を確認。
4) 検証: dev ワークスペースで `dbt run/test` の成功と S3 への出力・Athena カタログの整合を確認。
5) ドキュメント: `ai-doc/infra/dbt_athena_setup.md`/`system_design.md` に反映。

## DoD（受入基準）
- Step Functions 実行で Fargate タスクが起動し、`dbt run -m cleaned_activities` と `dbt test` が成功。
- CloudWatch Logs に dbt 実行ログが保存され、S3 `processed/` に出力が生成。
- すべて Terraform で再現可能（最小の手動操作は ECR 初回 push のみ）。
- 既存 `.env.dev` と `.dbt/profiles.yml` の変数と矛盾しない。

## リスク/対策
- ネットワーク到達性: パブリックサブネット + Public IP で外向き接続。必要に応じて S3/Athena/Logs の VPC エンドポイントを検討。
- コスト: タスクサイズと起動回数を管理。Step Functions のリトライ設定を適正化。
- 権限過多: 最小権限の IAM ポリシーを作成し、データセットバケット/リージョンにスコープダウン。

---
