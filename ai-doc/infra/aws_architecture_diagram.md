## AWS Architecture Diagram

このドキュメントは、Terraformで管理されているAWSデータ基盤のアーキテクチャをMermaid形式で可視化したものです。

```mermaid
flowchart LR
    subgraph StepFunctions[Step Functions ワークフロー]
        SFN[Download → Convert → Run dbt]
        SFN -->|Lambda Invoke| L1[Lambda download_and_upload]
        SFN -->|Lambda Invoke| L2[Lambda convert_log_to_parquet]
        SFN -->|ECS RunTask| ECS["Fargate タスク<br/>dbt run/test"]
    end

    subgraph S3Bucket[S3 <workspace>-aws-data-platform-20250607]
        Raw[raw/]
        Stage[stage/]
        Processed[processed/]
    end

    L1 -->|PutObject| Raw
    L2 -->|Read/Write| Raw
    L2 -->|Write Parquet| Stage
    ECS -->|Read/Write| Stage
    ECS -->|Write Models| Processed

    ECS -->|Pull Image| ECR["ECR<br/><workspace>-data-platform/dbt"]
    ECS -->|Query| Athena[Athena]
    ECS -->|Glue API| Glue[Glue Catalog]
    ECS -->|Logs| Logs[CloudWatch Logs /ecs/<workspace>/dbt]

    subgraph VPC[VPC 10.20.0.0/16]
        IGW[Internet Gateway]
        subgraph PubA["Public Subnet A<br/>10.20.0.0/24"]
            ENIA["ENI (Public IP)"]
        end
        subgraph PubB["Public Subnet B<br/>10.20.1.0/24"]
            ENIB["ENI (Public IP)"]
        end
    end

    ECS --- ENIA
    ECS --- ENIB
    IGW --> ENIA
    IGW --> ENIB
```

### データフロー概要

1.  **データ収集**:
    - `download_and_upload` Lambda関数が、外部のKaggle APIからmHealthデータセットをダウンロードし、生のログファイルのままS3バケット (`Raw Data Bucket`) にアップロードします。

2.  **ETL (Extract, Transform, Load)**:
    - このプロセス全体は **Step Functions** によってオーキエストレーションされます。
    - Step Functionsはまず `download_and_upload` Lambda を呼び出し、その結果を `convert_log_to_parquet` Lambda へ渡します。
    - 変換後、Step Functions は ECS RunTask を介して **Fargate** 上の dbt タスクを起動し、`dbt run -m cleaned_activities` と `dbt test` を同期実行します。
    - Fargate タスクはパブリックサブネットで Public IP を取得し、ECR からコンテナイメージをプルしたのち S3/Glue/Athena にアクセスします。

3.  **DWH (Data Warehouse)**:
    - **Glue Data Catalog** が、S3上のデータに対するメタデータストアとして機能します。
    - `stage_mhealth` データベースは、Parquet変換後のStagingデータをテーブルとして定義します。
    - `processed_mhealth` データベースは、dbtによって変換された最終的なデータをテーブルとして定義します。
    - これにより、S3上のファイルが直接クエリ可能なテーブルとして扱えるようになります。

4.  **分析**:
    - **Amazon Athena** を使用して、Glue Data Catalogに登録されたテーブルに対して標準SQLでインタラクティブにクエリを実行し、データの分析や可視化を行います。
