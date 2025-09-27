# タスクリスト: dbt の Docker 移行

このリストは、dbt（Athena adapter）を Docker 実行へ移行するための具体的な実装タスクを定義します。

---

### Task 1: Dockerfile の作成（dbt CLI 用）
- 説明: 最小イメージで `dbt-core` と `dbt-athena-community` をインストールし、非 root ユーザーで実行できる `docker/dbt/Dockerfile` を作成する。
- 成果物:
  - `docker/dbt/Dockerfile`
- 検証方法:
  - `docker build -f docker/dbt/Dockerfile -t local/dbt:dev .` が成功する。
  - `docker run --rm local/dbt:dev dbt --version` がバージョンを出力。

---

### Task 2: docker-compose の追加（dbt サービス）
- 説明: dbt コンテナを簡便に起動するための compose を作成。リポジトリを `/work` にマウントし、`.env.dev` と `~/.aws` を取り込む。常駐（`sleep infinity`）で起動し、`exec` で対話実行可能にする。
- 成果物:
  - `docker/dbt/docker-compose.yml`
- 検証方法:
  - `docker compose -f docker/dbt/docker-compose.yml up -d` が成功し、`docker compose -f docker/dbt/docker-compose.yml ps` に `dbt` が表示される。
  - `docker compose -f docker/dbt/docker-compose.yml exec dbt dbt debug` がプロファイル検出まで成功（Athena 接続は認証次第）。

---

### Task 3: ラッパースクリプトの作成（ホスト UX 揃え）
- 説明: 既存の `with-env.sh` と同様の UX で Docker 経由の dbt を呼べるスクリプトを追加。
- 成果物:
  - `data_flow_dbt/scripts/dbt-docker.sh`
- 検証方法:
  - `data_flow_dbt/scripts/dbt-docker.sh debug` が `dbt debug` を実行し exit code 0。
  - `... dbt-docker.sh docs serve --port 8080 --no-browser` で 8080 が LISTEN。

---

### Task 4: 環境変数/プロファイルの伝播検証
- 説明: `.env.dev` と `.dbt/profiles.yml` を変更せずに Docker で `dbt` が動くことを確認。
- 成果物:
  - 変更なし（検証ログ/手順）
- 検証方法:
  - `dbt debug` の出力で `profile: data_flow_dbt`, `adapter: athena`, `DBT_PROFILES_DIR=/work/.dbt` を確認。

---

### Task 5: `dbt run/test` の E2E 検証（Athena/Glue 連携）
- 説明: 代表モデル（`cleaned_activities`, `featured_activities`）で Docker 実行の完全性を確認。
- 成果物:
  - 変更なし（検証ログ/手順）
- 検証方法:
  - `... dbt-docker.sh run -m cleaned_activities` が成功。
  - `... dbt-docker.sh test -m cleaned_activities` が成功。
  - S3/Glue 上の作成先スキーマが `.env.dev` と一致（`DBT_SCHEMA`）。

---

### Task 6: `dbt docs` の生成/配信検証
- 説明: Docker 経由で `dbt docs generate/serve` が動作し、DAG/カラムドキュメントを閲覧できること。
- 成果物:
  - 変更なし（検証ログ/手順）
- 検証方法:
  - `docker compose -f docker/dbt/docker-compose.yml run --rm dbt docs generate` が `data_flow_dbt/target/` に成果物を生成。
  - `docker compose -f docker/dbt/docker-compose.yml run --rm --service-ports dbt dbt docs serve --host 0.0.0.0 --port 8080 --no-browser` 後、`http://localhost:8080` で表示確認。
  - もしくは常駐中のコンテナで `exec dbt bash` → `dbt docs serve --host 0.0.0.0 --port 8080 --no-browser`。

---

### Task 9: dbt Docs メタデータ登録（Models/Sources）
- 説明: 既存ドキュメントに基づき、モデル/ソースの説明とデータテストを登録。
- 成果物:
  - `data_flow_dbt/models/schema.yml`（新規）
  - `data_flow_dbt/models/src_mhealth.yml`（拡充）
  - `data_flow_dbt/models/tests.yml`（重複上書き解消のため簡素化）
- 検証方法:
  - `dbt docs generate` 後、`manifest.json` の該当ノードに `description` が入っていることを確認。
  - Docs の Models/Sources 画面に Description と Tests が表示される。

---

### Task 7: ドキュメント更新（Docker 手順の追記）
- 説明: 既存の dbt セットアップドキュメントに Docker での実行手順を追記。
- 成果物:
  - `ai-doc/infra/dbt_athena_setup.md`（更新）
- 検証方法:
  - 記載された手順通りに実行し、Task 4〜6 の検証が再現できる。

---

### Task 8: セキュリティ/ロールバック記述
- 説明: 機密情報がイメージに入らないこと、失敗時のロールバック手順を specs に明記。
- 成果物:
  - 本 `plan.md` の「リスク/ロールバック」節を完成（本PRで達成）。
- 検証方法:
  - イメージ内に `~/.aws` 等が含まれないことを `docker run --rm local/dbt:dev sh -lc 'ls -la ~'` 等で確認。

---

### 参考コマンド（検証時）
- `docker compose -f docker/dbt/docker-compose.yml up -d`
- `docker compose -f docker/dbt/docker-compose.yml exec dbt dbt debug`
- `docker compose -f docker/dbt/docker-compose.yml run --rm dbt run -m cleaned_activities`
- `docker compose -f docker/dbt/docker-compose.yml run --rm --service-ports dbt dbt docs serve --host 0.0.0.0 --port 8080 --no-browser`
