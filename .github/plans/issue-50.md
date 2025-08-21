# AWS構成図作成の実装計画 (Issue #50)

## 1. 目的
Terraformで管理されているAWSデータ基盤の構成を可視化するため、Mermaid形式の構成図を作成し、プロジェクトのドキュメントとして追加する。

## 2. 成果物
- `ai-doc/infra/aws_architecture_diagram.md`
  - Mermaid形式で記述されたAWS構成図を含むMarkdownファイル。

## 3. タスク分割

### 3.1. 現状のAWS構成の分析 (調査フェーズ)
Mermaid図を作成する前に、現在のインフラ構成を正確に把握する必要がある。

- **Terraform定義の確認:**
  - `terraform/main.tf` および `terraform/modules/` ディレクトリ内の各tfファイルを読み解き、プロビジョニングされているAWSリソースをリストアップする。
    - S3バケット (生データ用、処理済みデータ用など)
    - Lambda関数 (`download_and_upload`, `convert_log_to_parquet` など)
    - Glueジョブ、Glueデータカタログ
    - Step Functions のステートマシン
    - IAMロール (各サービスの連携を把握)
    - (もしあれば) Athena, Redshift

- **Step Functionsのワークフロー分析:**
  - `state_machine/data_processing.asl.json` を精査し、各AWSサービスがどのような順序で、どのように連携してデータ処理パイプラインを構成しているかを正確に理解する。これがデータの流れ（矢印）の主要な情報源となる。

- **dbtの役割の確認:**
  - `data_flow_dbt/` ディレクトリ、特に `dbt_project.yml` と `models/` を確認し、dbtがETL/ELTプロセスのどの部分を担っているかを特定する。
  - dbtがどのコンピューティングリソース（例: Fargate, Glue, Lambda）上で実行されているか、またはどのようにトリガーされるかをTerraformやStep Functionsの定義から特定する。

### 3.2. Mermaid構成図の設計
分析結果を基に、Mermaidの構文で構成図を設計する。

- **グラフの方向定義:**
  - `graph TD` (Top Down) を使用し、上から下へのデータの流れを表現する。

- **subgraphの定義:**
  - 要件に基づき、以下の4つのsubgraphを定義する。
    - `subgraph データ収集`
    - `subgraph ETL`
    - `subgraph DWH`
    - `subgraph 分析`

- **ノードの定義:**
  - 分析フェーズでリストアップしたAWSサービスをノードとして定義する。
  - 例: `S3_Raw["S3 (Raw Data)"]`, `Lambda_Download["Lambda (Download)"]`, `SFN["Step Functions"]`, `Glue_Job["Glue (Parquet Convert)"]`, `DBT["dbt (Data Transform)"]`, `S3_Processed["S3 (Processed)"]`, `Athena["Athena"]`

- **データフローの定義 (矢印):**
  - Step Functionsのワークフローと各サービスの役割に基づき、ノード間を矢印で接続する。
  - 例: `S3_Raw -- "Trigger" --> Lambda_Download -- "Invoke" --> SFN`

### 3.3. ドキュメント作成と保存
設計したMermaidコードをMarkdownファイルにまとめ、指定された場所に出力する。

- **ファイル作成:**
  - `ai-doc/infra/aws_architecture_diagram.md` という名前で新規ファイルを作成する。

- **コンテンツの記述:**
  - ファイル内に `## AWS Architecture Diagram` のようなタイトルを追加する。
  - ` ```mermaid ``` ` コードブロックを作成し、その中に設計したMermaidコードを記述する。
  - 図の下に、データフローの概要や各コンポーネントの役割を補足する簡単な説明文を追加する。

## 4. 実行スケジュール
1. **構成分析:** 0.5h
2. **Mermaid設計:** 0.5h
3. **ドキュメント作成:** 0.5h
---
**合計見積もり:** 1.5h
