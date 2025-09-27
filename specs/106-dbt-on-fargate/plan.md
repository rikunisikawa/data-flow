# 計画: dbt を Fargate で実行し Step Functions に統合

**Branch**: `feature/106-dbt-on-fargate` | **Owner**: Data Platform | **Date**: 2025-09-27

## 目的
- dbt（Athena adapter）の実行環境をコンテナ化し、AWS ECS Fargate 上で安定かつ再現可能に実行する。
- 既存の Step Functions ワークフローに dbt 実行ステップを統合し、データ取り込みから変換までの一連のパイプラインをサーバレスで自動化する。

## スコープ
- **追加**:
  - ECR リポジトリ (`terraform/modules/ecr/main.tf`)
  - ECS クラスター、Fargate タスク定義、関連 IAM ロール (実行/タスク)、CloudWatch Logs (`terraform/modules/fargate/main.tf`)
- **変更**:
  - Step Functions ステートマシンの定義 (`state_machine/data_processing.asl.json`) に Fargate 実行タスクを追加。
  - 関連ドキュメントの更新 (`ai-doc/infra/dbt_athena_setup.md`, `ai-doc/infra/system_design.md`)
- **非対象**:
  - Glue, Lambda の大幅な改修は行わず、Step Functions との連携に必要な最小限の変更に留める。

## 方針と設計
- **コンテナイメージ**: 既存の `docker/dbt/Dockerfile` をベースに、dbt 実行用の Docker イメージをビルドし、ECR へプッシュする。
- **タスク実行**: Fargate タスクとして `dbt run` および `dbt test` を実行する。リソースは `0.5 vCPU / 1GB` から開始し、必要に応じて調整する。
- **環境変数**: `S3_STAGING_DIR`, `DBT_SCHEMA` などの実行に必要な設定値は、Terraform を通じて Fargate タスク定義に環境変数として安全に渡す。
- **ネットワーク**: Fargate タスクは、Athena や S3 などの AWS サービスエンドポイントにアクセスできるよう、プライベートサブネット内で実行し、NAT Gateway を経由して外部と通信する。
- **権限管理**: IAM のベストプラクティスに従い、Fargate タスクには ECR からのイメージプル権限（実行ロール）と、S3/Athena/Glue へのアクセス権限（タスクロール）を最小権限で付与する。
- **ロギング**: dbt の実行ログはすべて CloudWatch Logs に集約し、監視とトラブルシューティングを容易にする。

## 実行フェーズ
1.  **コンテナ準備フェーズ**:
    1.  Terraform を用いて、dbt イメージを格納するための ECR リポジトリを作成する。
    2.  ローカル環境で Docker イメージをビルドし、作成した ECR リポジトリへ手動でプッシュする。
2.  **インフラ構築フェーズ**:
    1.  Terraform を用いて、ECS クラスター、Fargate タスク定義、および関連する IAM ロールやネットワーク設定（セキュリティグループ等）を含む実行基盤を構築する。
3.  **ワークフロー統合フェーズ**:
    1.  Step Functions のステートマシン定義を更新し、ECS Fargate タスクを同期的に呼び出すステップ (`ecs:runTask.sync`) を追加する。
4.  **検証フェーズ**:
    1.  dev 環境で Step Functions を実行し、データ取り込みから dbt on Fargate での変換まで、エンドツーエンドのパイプラインが正常に完了することを確認する。
    2.  Athena 上で、dbt によって変換されたデータが期待通りに生成されていることをクエリで確認する。
5.  **ドキュメント更新フェーズ**:
    1.  今回のアーキテクチャ変更を `ai-doc` 以下の関連ドキュメントに反映する。

## 受入基準 (DoD)
- Step Functions の実行が成功し、その過程で Fargate タスクが起動され、`dbt run` と `dbt test` が正常に完了する。
- dbt の実行ログが CloudWatch Logs に指定されたロググループへ保存されている。
- S3 の `processed/` ディレクトリ配下に、dbt によって変換されたデータが出力されている。
- すべてのインフラ構成が Terraform によってコード化され、再現可能であること（ECR への初回イメージプッシュのみ手動）。