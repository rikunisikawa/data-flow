# Terraform 設計ドキュメント

## 概要

このドキュメントは、本プロジェクトにおけるTerraformを用いたインフラストラクチャ管理の設計思想と運用方針について説明します。

## 環境分離とTerraformワークスペース

本プロジェクトでは、開発環境 (`dev`) と本番環境 (`prod`) のインフラストラクチャを明確に分離し、Terraformの**ワークスペース**機能を用いて管理します。

-   **`dev` ワークスペース**: 開発者がローカル環境でインフラ変更の試行、テスト、デバッグを行うための環境です。開発者は自身のローカルマシンから `terraform workspace select dev` を実行し、開発用のAWSアカウントや特定の開発環境にリソースをデプロイします。
-   **`prod` ワークスペース**: コードレビューが完了し、安定したインフラコードを自動的かつ安全にデプロイするための本番環境です。

同じTerraformコードベースを使用しながら、ワークスペースを切り替えることで、それぞれの環境で独立したTerraformステートファイルと変数セットを管理し、環境間の影響を最小限に抑えます。

## CI/CDによるデプロイ

本番環境 (`prod`) へのデプロイは、GitHub Actionsを用いたCI/CDパイプラインによって自動化されています。

-   **トリガー**: `main` ブランチへのコードプッシュをトリガーとして、Terraformデプロイワークフロー (`.github/workflows/terraform-deploy.yml`) が自動的に実行されます。
-   **ワークフローの役割**: ワークフローは、`prod` ワークスペースを選択し、`prod.tfvars` ファイルを使用してTerraformの変更を適用します。これにより、手動によるデプロイミスを防ぎ、デプロイプロセスの一貫性と信頼性を確保します。
-   **補足**: dbt イメージのビルド/プッシュはワークフローに含まれていません。必要に応じて `scripts/build_dbt_image.sh` を実行し、`dbt_image_tag` を更新してください。

## リソース命名規則

各環境のリソースが明確に識別できるよう、Terraformのリソース名には、現在のワークスペース名を示すプレフィックスを付与します。これはTerraformの組み込み変数 `terraform.workspace` を利用して実現されます。

**例**:
```terraform
resource "aws_lambda_function" "my_lambda" {
  function_name = "${terraform.workspace}-my-lambda-function"
  # ...
}
```

これにより、`dev` ワークスペースでデプロイされたリソースは `dev-my-lambda-function` のように、`prod` ワークスペースでデプロイされたリソースは `prod-my-lambda-function` のように命名され、環境ごとのリソースの識別が容易になります。
