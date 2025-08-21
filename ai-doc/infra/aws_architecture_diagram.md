## AWS Architecture Diagram

This document outlines the architecture of the AWS data platform, managed by Terraform.

```mermaid
graph TD
    subgraph データ収集 [Data Ingestion]
        A[External Data Source<br>(e.g., Kaggle)] --> B(download-and-upload-function<br>Lambda);
        B --> C{dev-data-flow-bucket<br>S3};
    end

    subgraph ETL
        D(Step Functions) -- "Invoke" --> B;
        C -- "Trigger" --> D;
        D -- "Invoke" --> E(convert-log-to-parquet-function<br>Lambda);
        E --> F[S3<br>stage/];
        G[glue_catalog_raw_activities<br>Glue Catalog] -.-> F;
        subgraph dbt
            H(dbt)
        end
        F --> H;
        H --> I[S3<br>analytics/];
    end

    subgraph DWH [Data Warehouse]
       I -- "Data Source" --> J(Athena);
    end

    subgraph 分析 [Analysis]
        J -- "Query" --> K[BI Tools / Notebooks];
    end

    style C fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#f9f,stroke:#333,stroke-width:2px
    style I fill:#f9f,stroke:#333,stroke-width:2px
```

### Data Flow Overview

1.  **Data Ingestion**: The `download-and-upload` Lambda function is triggered to fetch data from an external source (like Kaggle) and places the raw data into an S3 bucket.
2.  **ETL**:
    *   An S3 event triggers a Step Functions workflow.
    *   The workflow first invokes the `download-and-upload` function.
    *   Next, it invokes the `convert-log-to-parquet` Lambda to transform the raw data into Parquet format and store it in the `stage/` directory of the S3 bucket.
    *   The AWS Glue Data Catalog is updated with the schema of the staged data.
    *   dbt is then used to run data transformation models, taking the staged data as a source and outputting the final, cleaned data to the `analytics/` directory in S3.
3.  **Data Warehouse**: Amazon Athena uses the Glue Data Catalog to query the transformed data stored in the `analytics/` S3 directory.
4.  **Analysis**: BI tools or data analysis notebooks can connect to Athena to run queries and visualize the data.
