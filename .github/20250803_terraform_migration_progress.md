# Terraform 移行進捗レポート (2025年8月3日)

## 概要
AWS SAMからTerraformへのインフラストラクチャ移行作業を開始し、Terraformの初期設定、Docker環境の構築、既存リソースの棚卸し、および主要なリソースのTerraformコード化とデプロイを完了しました。

## 実施内容

### フェーズ 1: 準備と設計
- **Terraform実行環境のセットアップ**:
    - `terraform/backend.tf` にS3バックエンド設定を記述。
    - `data-flow-tfstate` S3バケットを手動で作成。
    - `terraform/Dockerfile` を作成し、`terraform-cli` Dockerイメージをビルド。
    - `terraform/docker compose.yml` を作成し、`terraform-cli` コンテナを管理。
    - `terraform init` をコンテナ内で実行し、S3バックエンドを初期化。
- **プロジェクト構成の設計と初期化**:
    - `terraform workspace new dev` および `terraform workspace new prod` を実行し、ワークスペースを作成。
- **既存リソースの棚卸し**:
    - `sam package` を実行し、`packaged-template.yaml` を生成。既存のSAMリソース（Lambda関数、Step Functions、Glueジョブ、IAMロール、Lambdaレイヤー）を特定。

### フェーズ 2: Terraform コードの実装とインポート (一部)
- **Terraformモジュールの作成**:
    - `terraform/modules/lambda` モジュールを作成（Lambda関数用）。
    - `terraform/modules/iam` モジュールを作成（IAMロール用）。
- **Terraformコードの記述**:
    - `terraform/main.tf` にLambda関数、IAMロール、LambdaレイヤーのTerraformリソースを記述。
    - `terraform/variables.tf` を更新し、必要な変数を定義。
    - **機密情報管理の改善**: Kaggle認証情報（ユーザー名、キー）をSSM Parameter Store (`/data-flow/kaggle/username`, `/data-flow/kaggle/key`) に `SecureString` として保存するよう変更。TerraformコードはSSM Parameter Storeからこれらの値を取得するように修正。
    - `terraform/dev.tfvars` から機密情報を削除し、Git管理外とした。
- **Lambdaデプロイパッケージの構成変更**:
    - プロジェクトルートに `build/` ディレクトリを作成。
    - 各Lambda関数とレイヤーのzipファイルを `build/` ディレクトリに出力するようにビルドコマンドを修正。
    - `terraform/main.tf` の `filename` パスを `/app/build/` からの相対パスに修正。
    - `docker compose.yml` を修正し、ホストのプロジェクトルートをコンテナの `/app` にマウントするように変更。
- **Terraform Apply**:
    - `terraform plan` で変更内容を確認後、`terraform apply` を実行し、以下のリソースをAWS上に正常にデプロイ。
        - `aws_iam_role.lambda_execution_role`
        - `aws_lambda_layer_version.kaggle_api_layer`
        - `module.convert_log_to_parquet_lambda.aws_lambda_function.this`
        - `module.download_and_upload_lambda.aws_lambda_function.this`
        - `module.glue_job_role.aws_iam_role.this`
        - `module.glue_job_role.aws_iam_role_policy.this[0]`

## 次のステップ
- フェーズ3: CI/CD パイプラインの構築
    - タスク 3.1: Lambdaのビルドプロセス分離（`build.sh` スクリプトの作成と自動化）
