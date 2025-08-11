# Terraform dev環境構築とS3管理の導入 (2025年8月9日)

## 概要
Terraformのワークスペース機能を利用して`dev`環境と`prod`環境の分離を行い、`dev`環境のインフラを構築した。また、これまでSAMの管理下にあったS3バケットをTerraformの管理対象とし、環境ごとに異なるバケット名が自動で付与されるように設定した。

## 実施内容

### 1. 課題の確認と方針決定
- `issue-29`の移行計画と現状のコードを比較し、Step FunctionsとGlueジョブが未移行であることを確認。
- S3バケットがTerraform管理外であり、SAMが生成したデプロイパッケージが混在している状況を確認。
- **方針として、まずS3バケットをTerraform管理下に置き、`dev`と`prod`で環境分離を徹底することを決定。Step FunctionsとGlueは一時的に対象外とした。**

### 2. Terraformコードの修正

- **ワークスペースによる環境分離:**
    - リソース名やバケット名に`${terraform.workspace}`を付与し、`dev`と`prod`で名前が重複しないようにした。
    - `variables.tf`の`bucket_name`を`base_bucket_name`に変更し、役割を明確化。
    - `dev.tfvars`も上記変更に追従。

- **S3バケットのTerraform管理:**
    - `main.tf`に`aws_s3_bucket`リソースを追加。
    - バケット名は`locals`を利用して`${terraform.workspace}-${var.base_bucket_name}`の形式で動的に生成するようにした。
    - Lambda関数の環境変数など、バケット名を参照するすべての箇所を`local.bucket_name`に更新。
    - Glueジョブで利用するスクリプトを配置するため、`aws_s3_object`リソースも追加。

### 3. `dev`環境のデプロイ

- **`terraform plan`での問題解決:**
    - Dockerコンテナ内での実行において、`terraform-cli`というサービス名の間違いや、`bash`ではなく`sh`を使うべきである問題、`aws_s3_object`のソースパスの問題などを特定し、都度修正した。
    - 当初、現在選択中のワークスペースが`prod`のままだったため、`-var-file=dev.tfvars`を指定しても`prod`環境の計画が作成される問題を特定。`terraform workspace select dev`を実行することで解決した。

- **`terraform apply`の実行:**
    - `dev`ワークスペースに切り替えた上で`terraform apply`を実行。
    - `dev-`の接頭辞を持つIAMロール、Lambda関数、Lambdaレイヤー、S3バケットなど、合計8つのリソースを`dev`環境として新規にAWS上に構築した。

## 次のステップ

1.  **Step FunctionsのTerraform管理:**
    - `main.tf`でコメントアウトしている`aws_sfn_state_machine`リソースを有効化する。
    - Step Functionsの定義(`data_processing.asl.json`)を修正し、Glueジョブを呼び出す部分を削除、代わりに`stage`にデータを格納するまでの処理（`DownloadAndUploadFunction`と`ConvertLogToParquetFunction`の連携）を定義する。
2.  **LambdaからGlueへの移行:**
    - 現在`ConvertLogToParquetFunction` (Lambda) で行っているParquet変換処理を、dbtと連携可能なGlueジョブに置き換える。
    - README.mdの該当箇所を更新する。
