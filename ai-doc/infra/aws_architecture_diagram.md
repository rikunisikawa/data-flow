## AWS Architecture Diagram

このドキュメントは、Terraformで管理されているAWSデータ基盤のアーキテクチャをMermaid形式で可視化したものです。

```mermaid
graph TD
    subgraph データ収集
        A[Kaggle] --> B[Lambda: download_and_upload];
        B --> C[S3: Raw Data Bucket];
    end

    subgraph ETL
        D[Step Functions: Data Processing] -- Invoke --> B;
        D -- Invoke --> E[Lambda: convert_log_to_parquet];
        C -- Trigger --> E;
        E --> F[S3: Staging Data Bucket];
        G[dbt] -- Transform --> H[S3: Processed Data Bucket];
    end

    subgraph DWH
        F -- Defines --> I[Glue Catalog: stage_mhealth];
        H -- Defines --> J[Glue Catalog: processed_mhealth];
    end

    subgraph 分析
        K[Amazon Athena] -- Query --> I;
        K -- Query --> J;
    end

    style A fill:#FF9900,stroke:#333,stroke-width:2px
    style B fill:#FF9900,stroke:#333,stroke-width:2px
    style C fill:#5A6B86,stroke:#333,stroke-width:2px
    style D fill:#C61F7E,stroke:#333,stroke-width:2px
    style E fill:#FF9900,stroke:#333,stroke-width:2px
    style F fill:#5A6B86,stroke:#333,stroke-width:2px
    style G fill:#FF694A,stroke:#333,stroke-width:2px
    style H fill:#5A6B86,stroke:#333,stroke-width:2px
    style I fill:#2E73B8,stroke:#333,stroke-width:2px
    style J fill:#2E73B8,stroke:#333,stroke-width:2px
    style K fill:#2E73B8,stroke:#333,stroke-width:2px
```

### データフロー概要

1.  **データ収集**:
    - `download_and_upload` Lambda関数が、外部のKaggle APIからmHealthデータセットをダウンロードし、生のログファイルのままS3バケット (`Raw Data Bucket`) にアップロードします。

2.  **ETL (Extract, Transform, Load)**:
    - このプロセス全体は **Step Functions** によってオーキエストレーションされます。
    - Step Functionsはまず `download_and_upload` Lambdaをトリガーします。
    - 次に、`convert_log_to_parquet` LambdaがS3の生データをトリガーとして、ログ形式からクエリ効率の良いParquet形式に変換し、別のS3バケット (`Staging Data Bucket`) に保存します。
    - その後、**dbt** がStagingデータを読み込み、データクレンジングや変換処理（例: 不要な列の削除、データ型の統一、テーブルの結合など）を行い、最終的な分析用データとしてS3バケット (`Processed Data Bucket`) に出力します。

3.  **DWH (Data Warehouse)**:
    - **Glue Data Catalog** が、S3上のデータに対するメタデータストアとして機能します。
    - `stage_mhealth` データベースは、Parquet変換後のStagingデータをテーブルとして定義します。
    - `processed_mhealth` データベースは、dbtによって変換された最終的なデータをテーブルとして定義します。
    - これにより、S3上のファイルが直接クエリ可能なテーブルとして扱えるようになります。

4.  **分析**:
    - **Amazon Athena** を使用して、Glue Data Catalogに登録されたテーブルに対して標準SQLでインタラクティブにクエリを実行し、データの分析や可視化を行います。