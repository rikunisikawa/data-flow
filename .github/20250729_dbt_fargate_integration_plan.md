# 最終計画書：dbt導入と本番パイプラインへの統合

## 1. 目的

ローカル環境で開発・テストしたdbtによるデータ変換処理を、本番環境の自動化パイプラインに組み込む。
先行するETL処理（Lambda）の完了をトリガーに、dbtの処理（`dbt run` & `dbt test`）をAWS Fargate上で自動実行する、信頼性と保守性の高いワークフローを構築する。

## 2. 最終的なアーキテクチャ

現在のStep FunctionsによるETLフローの最終ステップとして、dbt実行用の**AWS Fargateタスク**を起動するステップを追加する。

**処理フロー:**

```
[EventBridge Trigger]
       ↓
[Step Functions Start]
       ↓
[Lambda①: Download]
       ↓
[Lambda②: Convert to Parquet]
       ↓
[**Fargate Task: dbt run & test**] (← 今回のスコープ)
       ↓
[Step Functions End]
```

**データフロー:**

- **ソース**: `stage_mhealth.raw_activities` (Lambdaが生成したParquetを外部テーブルとして定義)
- **成果物**: `mhealth_processed.cleaned_activities` (dbtが変換・整形して作成するテーブル)

---

## 3. 実装ステップ

### ステップ1：dbtプロジェクトのDocker化

dbtプロジェクトを実行環境ごとコンテナにパッケージングする。

1.  **`data_flow_dbt`ディレクトリに`Dockerfile`を作成する:**

    ```dockerfile
    # ベースイメージとして公式のPythonイメージを使用
    FROM python:3.11-slim

    # 作業ディレクトリを設定
    WORKDIR /dbt

    # 必要なライブラリをインストール (boto3はAthenaへの接続に必要)
    RUN pip install --no-cache-dir dbt-athena-community boto3

    # dbtプロジェクトのプロファイルとモデルをコピー
    COPY ./dbt_profiles/profiles.yml /root/.dbt/profiles.yml
    COPY ./data_flow_dbt/ /dbt/

    # コンテナ起動時に実行するデフォルトコマンドを設定
    ENTRYPOINT ["dbt"]
    CMD ["--help"]
    ```

2.  **`.dockerignore`ファイルを作成する:**
    ビルドに不要なファイルを除外し、イメージサイズを削減するため、プロジェクトルートに以下の内容で`.dockerignore`ファイルを作成する。

    ```
    .git/
    .venv/
    .pytest_cache/
    .aws-sam/
    dbt_packages/
    logs/
    target/
    ```

### ステップ2：DockerイメージのビルドとECRへのプッシュ

作成したDockerイメージを、AWSのコンテナリポジトリであるECR (Elastic Container Registry)に保存する。

1.  **ECRリポジトリを作成する:**

    ```bash
    aws ecr create-repository --repository-name data-flow-dbt --image-scanning-configuration scanOnPush=true
    ```

2.  **Dockerイメージをビルド＆プッシュする:**
    （`ACCOUNT_ID`と`AWS_REGION`は自身の環境に合わせてください）

    ```bash
    # ECRへのログイン
    aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com

    # Dockerイメージのビルド
    docker build -t data-flow-dbt .

    # ECRリポジトリ用にイメージをタギング
    docker tag data-flow-dbt:latest ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/data-flow-dbt:latest

    # ECRへイメージをプッシュ
    docker push ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/data-flow-dbt:latest
    ```

### ステップ3：Fargateタスク定義の作成

Fargateでどのようなコンテナを、どのような設定で実行するかを定義する。

1.  **IAMロールの準備:**
    -   **タスク実行ロール (Task Execution Role):** ECRからのイメージプル、CloudWatchへのログ書き込み権限を持つ。(`AmazonECSTaskExecutionRolePolicy`)
    -   **タスクロール (Task Role):** コンテナ内のdbtがAthena, S3, Glueにアクセスするための権限を持つ。

2.  **タスク定義ファイル (`task-definition.json`) を作成する:**
    `dbt run`の後に`dbt test`が実行されるように`command`を修正。

    ```json
    {
      "family": "dbt-task",
      "networkMode": "awsvpc",
      "requiresCompatibilities": ["FARGATE"],
      "cpu": "256",
      "memory": "512",
      "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
      "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/dbtFargateTaskRole",
      "containerDefinitions": [
        {
          "name": "dbt-container",
          "image": "ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/data-flow-dbt:latest",
          "command": [
            "bash", "-c", "dbt run && dbt test"
          ],
          "environment": [
            {
              "name": "S3_STAGING_DIR",
              "value": "s3://aws-data-platform-20250607/dbt-temp/"
            },
            {
              "name": "AWS_REGION",
              "value": "ap-northeast-1"
            },
            {
              "name": "GLUE_DATABASE",
              "value": "awsdatacatalog"
            },
            {
              "name": "ATHENA_WORK_GROUP",
              "value": "primary"
            }
          ],
          "essential": true
        }
      ]
    }
    ```

3.  **タスク定義を登録する:**

    ```bash
    aws ecs register-task-definition --cli-input-json file://task-definition.json
    ```

### ステップ4：Step Functionsステートマシンの更新

`state_machine/data_processing.asl.json`を修正し、Fargateタスクを呼び出すステップを追加する。

```json
{
  "Comment": "A state machine that orchestrates the mHealth data processing pipeline.",
  "StartAt": "DownloadLogs",
  "States": {
    "DownloadLogs": {
      // ... (既存の定義)
      "Next": "ConvertToParquet"
    },
    "ConvertToParquet": {
      // ... (既存の定義)
      "Next": "RunDbtViaFargate"
    },
    "RunDbtViaFargate": { // <-- このステップを丸ごと追加
      "Type": "Task",
      "Resource": "arn:aws:states:::ecs:runTask.sync",
      "Parameters": {
        "LaunchType": "FARGATE",
        "Cluster": "arn:aws:ecs:ap-northeast-1:ACCOUNT_ID:cluster/dbt-cluster",
        "TaskDefinition": "arn:aws:ecs:ap-northeast-1:ACCOUNT_ID:task-definition/dbt-task:1",
        "NetworkConfiguration": {
          "AwsvpcConfiguration": {
            "Subnets": ["subnet-xxxxxxxxxxxxxxxxx"],
            "AssignPublicIp": "ENABLED"
          }
        }
      },
      "End": true
    }
  }
}
```

---

## 4. 導入サマリー（ここまでの経緯）

本計画は、以下のプロセスを経て策定された。

1.  **環境準備とリセット**: `feature/dbt-integration`ブランチを作成し、既存のdbt環境をクリーンアップ。
2.  **dbtプロジェクト構築とデバッグ**: `dbt-athena-community`を導入し、`dbt debug`を駆使して接続プロファイルに関する複数の問題を解決。
3.  **アーキテクチャの再設計**: 当初不正確だったデータ定義をきっかけに、Glueへの依存をなくし、dbt中心の変換処理フローへとアーキテクチャを変更。設計書(`system_design.md`)もこれに合わせて更新。
4.  **dbt成果物の再実装**: 新しい設計に基づき、ソース定義、変換モデル、品質テストを全面的に再実装。
5.  **ベストプラクティス適用**: dbtのベストプラクティスに則り、成果物の出力先スキーマを`default`から専用の`mhealth_processed`に変更。`dbt-athena`アダプタの特殊な挙動を特定し、最終的な構成を確立した。

この反復的なプロセスにより、単なるツール導入に留まらない、プロジェクトの実態に即した堅牢なデータ基盤の設計が完成した。
