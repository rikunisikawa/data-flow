# GitHub Actions: Terraform デプロイワークフロー

## 概要

このドキュメントは、Terraformによるインフラストラクチャのデプロイを自動化するためのGitHub Actionsワークフローについて説明します。

## ワークフローの目的

`main`ブランチへのコードプッシュをトリガーとして、Lambda関数のデプロイパッケージをビルドし、Terraformを使用してAWSリソースを自動的にデプロイします。

## トリガー

- `main`ブランチへの`push`イベント

## ワークフローのステップ

1.  **コードのチェックアウト**: リポジトリのコードをGitHub Actionsランナーにチェックアウトします。

2.  **AWS認証情報の設定**: GitHub Secretsに保存されているAWS認証情報（`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`）を使用して、AWS CLIを設定します。

3.  **Lambdaデプロイパッケージのビルド**: `build.sh`スクリプトを実行し、Lambda関数およびレイヤーのデプロイに必要なzipファイルを作成します。これらのファイルは`build/`ディレクトリに生成されます。

4.  **Terraformの実行**: 
    - `terraform-cli` Dockerコンテナを起動します。
    - コンテナ内で`terraform init`を実行し、S3バックエンドを初期化します。
    - `terraform apply -auto-approve`を実行し、Terraformの変更を自動的に適用します。

## 前提条件

- GitHubリポジトリのSettings > Secretsに以下のAWS認証情報が設定されていること。
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
- `terraform/backend.tf`にS3バックエンドが正しく設定されており、対応するS3バケットが手動で作成済みであること。
- `terraform/Dockerfile`と`terraform/docker compose.yml`が正しく設定されていること。
- `build.sh`スクリプトが実行可能であり、Lambdaデプロイパッケージを正しく生成すること。
