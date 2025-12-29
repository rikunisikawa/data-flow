# dbt/Elementary 運用手順（Docker + Athena）

本ドキュメントは、本リポジトリの dbt 実行方法と Elementary の使い方をまとめた運用メモです。  
前提: `docker/dbt/docker-compose.yml` を利用し、Athena/Glue をターゲットに実行します。

## 1. 前提設定
- `.env.dev` に DBT/Athena 設定があること
  - `DBT_SCHEMA` 例: `dev_processed`
  - `ELEMENTARY_SCHEMA` 例: `elementary`（→ 実スキーマは `dev_processed_elementary`）
- `.dbt/profiles.yml` に `data_flow_dbt` と `elementary` の両プロファイルがあること

### 注意（env_file）
`.env.dev` を変更した場合は **再起動では反映されません**。  
必ず再作成してください。
```bash
docker compose -f docker/dbt/docker-compose.yml up -d --force-recreate dbt
```

## 2. dbt 実行方法（Docker）
### 2.1 コンテナ起動
```bash
docker compose -f docker/dbt/docker-compose.yml up -d
```

### 2.2 基本コマンド
```bash
# 依存取得
docker compose -f docker/dbt/docker-compose.yml exec dbt dbt deps

# モデル実行
docker compose -f docker/dbt/docker-compose.yml exec dbt dbt run

# テスト
docker compose -f docker/dbt/docker-compose.yml exec dbt dbt test
```

## 3. Elementary 導入後の運用
### 3.1 スキーマ作成（初回のみ）
Athena/Glue 側にスキーマ（DB）が必要です。例: `dev_processed_elementary`  
Athena で以下を実行:
```sql
CREATE DATABASE IF NOT EXISTS dev_processed_elementary
LOCATION 's3://<bucket>/processed/elementary/';
```
※ `DBT_SCHEMA=dev_processed` と `ELEMENTARY_SCHEMA=elementary` の場合、  
dbt の既定ルールで `dev_processed_elementary` が作成先になります。

### 3.2 Elementary テーブル作成（初回/更新時）
```bash
docker compose -f docker/dbt/docker-compose.yml exec dbt \
  dbt build --select elementary --full-refresh
```

### 3.3 レポート生成
```bash
docker compose -f docker/dbt/docker-compose.yml exec dbt \
  edr monitor report \
    --config-dir /work/data_flow_dbt \
    --profiles-dir /work/.dbt \
    --project-dir /work/data_flow_dbt \
    --profile-target dev \
    --days-back 7
```

出力先:  
`/work/data_flow_dbt/elementary/monitoring-reports/`

#### オプションの意味
- `--config-dir /work/data_flow_dbt`:
  `elementary_config.yml` が置かれているディレクトリ。Elementary の基本設定を読み込む。
- `--profiles-dir /work/.dbt`:
  dbt の `profiles.yml` がある場所。`elementary` プロファイルの接続情報を使う。
- `--project-dir /work/data_flow_dbt`:
  dbt プロジェクトのルート。Elementary のメタ情報取得に利用される。
- `--profile-target dev`:
  `elementary` プロファイルのターゲット名。`profiles.yml` の `elementary.outputs.dev` を参照。
- `--days-back 7`:
  直近何日分の実行結果をレポート対象にするかを指定。

## 4. 補足（スキーマ命名ルール）
dbt の既定では **`target.schema + '_' + custom_schema`** でスキーマ名が形成されます。  
例:
- `DBT_SCHEMA=dev_processed`
- `ELEMENTARY_SCHEMA=elementary`  
→ `dev_processed_elementary`

## 5. トラブルシュート
- `TABLE_NOT_FOUND: elementary_test_results`  
  - `dbt build --select elementary --full-refresh` を先に実行する
- `SCHEMA_NOT_FOUND`  
  - Athena で DB 作成を先に行う
- `edr: command not found`  
  - `docker/dbt/Dockerfile` の再ビルドが必要
