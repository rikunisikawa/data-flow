# SAM から Terraform への移行計画 (Issue #29)

## 1. 概要
このドキュメントは、プロジェクトのインフラストラクチャ管理を AWS SAM から Terraform へ移行するための具体的な実装計画を定義します。

## 2. 移行フェーズとタスク

### フェーズ 1: 準備と設計 (1-2日)

- **タスク 1.1: Terraform 実行環境のセットアップ**
  - [ ] Terraformの実行にはDocker公式の`hashicorp/terraform`イメージを使用する。これにより、ローカル環境へのCLIインストールを不要にし、チーム内でのバージョン統一を容易にする。
  - [ ] リモートステート管理用の S3 バケットを作成する。Terraformのstate lock機能はS3バックエンドのデフォルト機能で十分なため、コストのかかるDynamoDBは使用しない。
    - バケット名: `data-flow-tfstate` (仮)

- **タスク 1.2: プロジェクト構成の設計と初期化**
  - [ ] Terraform Workspace を利用して、`dev` と `prod` の環境を分離する。これにより、ディレクトリ構成をシンプルに保つ。
    ```
    terraform/
    ├── modules/
    │   ├── lambda/
    │   ├── api_gateway/
    │   └── iam/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── backend.tf
    ```
  - [ ] `backend.tf` に S3 バックエンドの設定を記述する。
  - [ ] `terraform workspace new dev` と `terraform workspace new prod` を実行し、ワークスペースを作成する。
  - [ ] 環境ごとの変数は、`terraform.tfvars` ファイルではなく、`-var-file` オプションで環境別の `.tfvars` ファイル（例: `dev.tfvars`, `prod.tfvars`）を読み込む形式とする。

- **タスク 1.3: 既存リソースの棚卸し**
  - [ ] `sam package` コマンドを実行し、現在の SAM アプリケーションの CloudFormation テンプレートを生成する。
  - [ ] 生成されたテンプレートを分析し、移行対象となる全リソース（Lambda, API Gateway, IAM Role, S3, etc.）をリストアップする。

### フェーズ 2: Terraform コードの実装とインポート (3-5日)

- **タスク 2.1: Terraform モジュールの作成**
  - [ ] `modules/` ディレクトリ以下に、再利用可能なリソース（Lambda 関数、API Gateway など）のモジュールを作成する。

- **タスク 2.2: Terraform コードの記述**
  - [ ] 棚卸ししたリソースを `main.tf` に Terraform HCL で記述する。
  - [ ] SAM の `AWS::Serverless::*` リソースを、対応する `aws_*` リソースにマッピングする。
    - `AWS::Serverless::Function` -> `aws_lambda_function`
    - `AWS::Serverless::Api` -> `aws_apigatewayv2_api` など
  - [ ] 環境ごとの差異を `variables.tf` と `*.tfvars` ファイルで管理するように設計する。

- **タスク 2.3: 既存リソースのインポート**
  - [ ] `terraform import` コマンドを使用し、既存の AWS リソースを Terraform の state ファイルに取り込む。
    - 例: `terraform workspace select dev && terraform import module.lambda.aws_lambda_function.my_function my-lambda-function-name`
  - [ ] すべてのリソースをインポート後、`terraform plan` を実行し、差分（"No changes"）が出ないことを確認する。

### フェーズ 3: CI/CD パイプラインの構築 (2-3日)

- **タスク 3.1: Lambda のビルドプロセス分離**
  - [ ] Lambda 関数のソースコードを `zip` ファイルに固めるためのビルドスクリプト (`Makefile` やシェルスクリプト) を作成する。
  - [ ] ビルドされた `zip` ファイルを S3 バケットにアップロードする手順を確立する。

- **タスク 3.2: GitHub Actions ワークフローの作成**
  - [ ] `.github/workflows/terraform.yml` を新規作成する。
  - [ ] Pull Request 作成時に `terraform workspace select dev && terraform plan -var-file=dev.tfvars` を自動実行し、結果を PR コメントに投稿するジョブを定義する。
  - [ ] `main` ブランチへのマージ時に `terraform workspace select prod && terraform apply -var-file=prod.tfvars` を自動実行するジョブを定義する。（手動承認ステップを挟むことを推奨）
  - [ ] Lambda のビルドと S3 へのアップロード処理をワークフローに組み込む。

### フェーズ 4: 移行の完了とクリーンアップ (1日)

- **タスク 4.1: 最終動作確認**
  - [ ] Terraform によって管理されているインフラが、移行前と同様に正しく動作することを E2E テスト等で確認する。

- **タスク 4.2: SAM スタックの削除**
  - [ ] 全てのリソースが Terraform 管理下に置かれ、安定稼働が確認できた後、`aws cloudformation delete-stack` コマンドで元の SAM スタックを削除する。
  - [ ] SAM 関連のファイル (`template.yaml` など) をプロジェクトから削除する。

## 3. 補足事項
- 移行作業は、影響範囲の少ないリソース（例: IAM Role）から段階的に進めることを推奨します。
- `terraform import` は手作業が多く、ミスが発生しやすいため、ペアプログラミングや複数人でのレビューを徹底してください。