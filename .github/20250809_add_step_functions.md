# Step Functionsの追加 (2025年8月9日)

## 概要
Terraformを使用して、既存のLambda関数（`DownloadAndUploadFunction`, `ConvertLogToParquetFunction`）を連携させるStep Functionsステートマシンを`dev`環境にデプロイした。

## 実施内容

### 1. 方針確認
当初、`ConvertLogToParquetFunction`をAWS Glueジョブに移行する計画だったが、ユーザーの指示により、まずStep Functionsの導入を優先し、Lambdaベースの構成を維持することになった。

### 2. Terraformコードの修正
- `terraform/main.tf`内の`templatefile`関数のパスを修正した。Dockerコンテナ内での実行時に、コンテナのルートディレクトリからの絶対パス(`/app/state_machine/data_processing.asl.json`)を参照するように変更した。

### 3. `dev`環境へのデプロイ
- `docker compose`経由でTerraformコマンドを実行した。
- `terraform plan`を実行し、以下の変更計画を確認した。
    - `aws_sfn_state_machine`リソースの新規作成
    - `aws_iam_role`（Step Functions実行用）の新規作成
    - 不要になった古いGlueジョブ関連のIAMロールの削除
- `terraform apply`を実行し、`dev`環境にStep Functionsを正常にデプロイした。

## 結果
`dev-data-processing-state-machine`という名前のStep FunctionsステートマシンがAWS上に作成された。これにより、データ処理パイプラインの基本的なオーケストレーションが実現した。
