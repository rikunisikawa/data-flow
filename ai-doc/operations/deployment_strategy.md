# 🚀 Lambdaレイヤーを含むデプロイ戦略

このドキュメントは、Lambda関数とLambdaレイヤーをTerraformでデプロイするための戦略と、その運用方法について説明します。

## 🎯 目的

*   Lambda関数およびLambdaレイヤーのコード変更をTerraformで効率的かつ確実にデプロイする。
*   大規模なPythonライブラリを含むレイヤーのデプロイを可能にする。
*   ビルドプロセスとデプロイプロセスを明確に分離する。

## 🛠️ 主要コンポーネント

### 1. `build.sh` (プロジェクトルート)

*   **役割**: ローカルでのビルドプロセス全体をオーケストレーションします。
*   **機能**: Lambda関数のzip化、環境別レイヤービルドスクリプトの呼び出し、S3への成果物アップロードを行います。
*   **実行方法**: `./build.sh <env>` (`env` は `dev` または `prod`)

### 2. `layer/terraform/build-layer.sh`

*   **役割**: LambdaレイヤーのビルドとS3へのアップロードを担当します。
*   **機能**: Dockerを使用して`layer/src`内の`Dockerfile`と`requirements.txt`に基づきPythonライブラリをインストールし、不要ファイルを削除後、`build/layer.zip`を作成し、指定されたS3バケットにアップロードします。
*   **最適化**: レイヤーサイズ削減のため、`boto3`の除外、`__pycache__`や`*.pyc`の削除、`pyarrow`から`fastparquet`への移行を行っています。

### 3. `layer/src/`

*   **役割**: Lambdaレイヤーのソースコード（`Dockerfile`, `requirements.txt`）を格納します。

### 4. `scripts/build_dbt_image.sh`

*   **役割**: dbt コンテナイメージをビルドし、環境別の ECR リポジトリ（`<env>-data-platform/dbt`）へ push する。
*   **機能**: AWS アカウント ID の取得、ECR ログイン、`docker build` / `docker push` を一括実行。
*   **実行方法**: `scripts/build_dbt_image.sh <env> <tag>`（例: `scripts/build_dbt_image.sh dev dev-latest`）。
*   **オプション**:
    - `--update-tfvars`: `terraform/<env>.tfvars` の `dbt_image_tag` を自動更新
    - `--tfvars-path <path>`: 更新対象の tfvars パスを指定
    - `--region <region>`: ECR リージョンを上書き
*   **注意**: Terraform の `dbt_image_tag` と渡した `tag` を一致させる。

### 5. `terraform/main.tf`

*   **役割**: AWSリソース（Lambda関数、Lambdaレイヤーなど）の定義と管理を行います。
*   **レイヤーの参照**: `aws_lambda_layer_version`リソースは、`build/layer.zip`をS3から参照する形式（`s3_bucket`, `s3_key`）を採用しています。
*   **変更検知**: `source_code_hash`属性を使用して、`build/layer.zip`の内容変更を検知し、レイヤーの新しいバージョンをデプロイします。

### 5. `terraform/docker-compose.yml`

*   **役割**: Terraformの実行環境をDockerコンテナとして定義します。
*   **パス**: プロジェクトルートはコンテナ内の`/app`にマウントされます。

## 🚀 デプロイフロー

1.  **コード変更**: Lambda関数コード（例: `convert_log_to_parquet.py`）やレイヤーの依存関係（`layer/src/requirements.txt`）を変更します。

2.  **ビルドとS3アップロード**: ローカル環境で`build.sh`を実行し、デプロイパッケージとレイヤーのzipファイルを生成し、環境に応じたバケットへアップロードします。
    ```bash
    ./build.sh dev    # 開発環境: dev-aws-data-platform-20250607 へ配置
    ./build.sh prod   # 本番環境: prod-aws-data-platform-20250607 へ配置
    ```
    > `build.sh` は指定した環境を `layer/terraform/build-layer.sh` に引き渡し、`<env>-aws-data-platform-20250607/layers/layer.zip` に成果物をアップロードします。

3.  **dbt コンテナイメージのビルドと ECR プッシュ**: `scripts/build_dbt_image.sh` を使い、Fargate で使用する dbt イメージを環境別にビルドして ECR に push します。
    ```bash
    bash scripts/build_dbt_image.sh dev dev-latest
    bash scripts/build_dbt_image.sh prod prod-2025-09-28
    ```
    - `env` 引数は `dev` / `prod` のいずれか。
    - `tag` は Terraform の `dbt_image_tag` と一致させる。
    - 処理内容: `aws sts` でアカウント ID を取得 → `aws ecr get-login-password` でログイン → `docker build` → `docker push`。
    - 例: `--update-tfvars` を付けると `terraform/<env>.tfvars` の `dbt_image_tag` を自動更新。

4.  **Terraform適用**: Terraformコンテナ内で`terraform apply`を実行し、AWSリソースに変更を適用します。
    ```bash
    docker compose -f terraform/docker-compose.yml run --rm terraform terraform apply -var-file=dev.tfvars
    ```

## ✅ 解決された課題とポイント

*   **ビルドとデプロイの分離**: `build.sh`がビルドとS3アップロードを担当し、Terraformがデプロイを担当することで、責務が明確になりました。
*   **レイヤーの変更検知**: `aws_lambda_layer_version`リソースの`source_code_hash`属性により、`build/layer.zip`の内容変更が確実にTerraformに検知されるようになりました。
*   **大規模レイヤーのデプロイ**: S3経由でのレイヤー参照と、`fastparquet`への移行、不要ファイルの削除により、Lambdaのレイヤーサイズ制限（250MB展開後）に対応しました。
*   **パスの整合性**: Dockerコンテナ内のパス（`/app`）とホストのパスの整合性を確保し、ビルドスクリプトとTerraformが正しくファイルを参照できるようにしました。
*   **`null_resource`の削除**: ビルドトリガーとしての`null_resource`の複雑さを排除し、Terraform構成をシンプルに保ちました。

## ⚠️ 注意事項

*   `build.sh`は、`terraform apply`を実行する前に**必ず**実行してください。そうしないと、Terraformが参照する`build/layer.zip`が最新でなかったり、S3に存在しなかったりする可能性があります。
*   `terraform/docker-compose.yml`で定義されているTerraformコンテナには、`aws-cli`と`zip`コマンドがインストールされている必要があります。また、Dockerデーモンへのアクセス権限が必要です。
*   `aws_iam_role.sfn_execution_role`の`inline_policy`に関する警告は、現在のところ機能に影響はありませんが、将来的に`aws_iam_role_policy`リソースへの移行が推奨されます。
*   GitHub Actions の Terraform デプロイワークフローは dbt イメージのビルド/プッシュを行いません。必要に応じて `scripts/build_dbt_image.sh` を事前実行してください。
