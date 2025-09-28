# AWS構成ダイアグラム（dbt on Fargate）

下図は現在の構成差分（NAT Gateway を廃止し、Fargate タスクをパブリックサブネットで稼働）を反映したアーキテクチャ図です。

```mermaid
flowchart LR
    subgraph StepFunctionsStack[Step Functions ワークフロー]
        SFN["Download → Convert → Run dbt"]
        SFN -->|Invoke| LambdaDownload["Lambda\nDownloadAndUpload"]
        SFN -->|Invoke| LambdaConvert["Lambda\nConvertLogToParquet"]
        SFN -->|RunTask| FargateTask["ECS Fargate タスク\ndbt run + dbt test"]
    end

    LambdaDownload -->|PutObject| S3Bucket["S3 バケット\n<workspace>-aws-data-platform-20250607"]
    LambdaConvert -->|Read/Write| S3Bucket
    FargateTask -->|Read/Write| S3Bucket

    FargateTask -->|Pull Image| ECR["ECR リポジトリ\n<workspace>-data-platform/dbt"]
    FargateTask -->|Query| Athena["Athena / Glue Catalog"]
    FargateTask -->|Logs| CWLogs["CloudWatch Logs\n/ecs/<workspace>/dbt"]

    subgraph Network[VPC 10.20.0.0/16]
        InternetGW[IGW]
        subgraph PublicA[Public Subnet A\n10.20.0.0/24]
            FargateENIA["Fargate ENI\n(AssignPublicIp=ENABLED)"]
        end
        subgraph PublicB[Public Subnet B\n10.20.1.0/24]
            FargateENIB["Fargate ENI"]
        end
    end

    FargateTask --- FargateENIA
    FargateTask --- FargateENIB
    InternetGW --> FargateENIA
    InternetGW --> FargateENIB
```

- Fargate タスクはパブリックサブネット内で起動し、Public IP を付与して ECR / S3 / Athena へ直接アクセスします。
- NAT Gateway やプライベートサブネットは使用していません。
- Step Functions は Lambda 2 本と Fargate タスクを同期実行し、CloudWatch Logs に dbt の実行ログが送られます。

