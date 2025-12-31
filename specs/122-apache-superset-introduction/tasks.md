# [タスクリスト] Apache Superset 導入 (issue #122)

## Phase 1: 環境構築と初期設定

-   **タスク 1.1: Docker Compose ファイルの作成**
    -   **内容:** Apache Superset 公式の Docker Compose 設定を参考に、プロジェクト用の `docker-compose.yml` を作成する。
    -   **成果物:** `docker/superset/docker-compose.yml`
    -   **検証方法:** `docker-compose up` コマンドで Superset に関連するコンテナ群がエラーなく起動すること。

-   **タスク 1.2: Superset 設定ファイルの作成とカスタマイズ**
    -   **内容:** タイムゾーン（`Asia/Tokyo`）、ロケール（`ja`）、その他必要な初期設定を記述した `superset_config.py` を作成する。
    -   **成果物:** `docker/superset/superset_config.py`
    -   **検証方法:** `docker-compose.yml` に `superset_config.py` をマウントする設定を追加し、起動後の Superset 管理画面で設定が反映されていることを確認する。

-   **タスク 1.3: 管理ユーザーの作成とログイン確認**
    -   **内容:** `docker-compose exec superset superset-init` などのコマンドを実行し、管理者アカウントを作成する。
    -   **成果物:** なし（Superset 内にユーザー作成）
    -   **検証方法:** `http://localhost:8088` にアクセスし、作成した管理者アカウントでログインできることを確認する。

## Phase 2: データソースへの接続

-   **タスク 2.1: 接続用 IAM ユーザーの準備**
    -   **内容:** Superset から Athena への接続に利用する、読み取り専用の IAM ユーザーを Terraform で作成し、認証情報（アクセスキー、シークレットキー）を SSM Parameter Store に保存する。必要な IAM ポリシー（Athena, Glue, S3 への読み取り権限）が付与されていることを確認する。
    -   **成果物:** SSM Parameter Store に `/data-flow/<workspace>/superset/athena/*` を作成
    -   **検証方法:** SSM のパラメータが取得できることを確認する。

-   **タスク 2.2: Superset から Athena への接続設定**
    -   **内容:** Superset の UI から「Data」->「Databases」を選択し、Athena への接続情報を設定する。SQLAlchemy URI は `awsathena+rest://{aws_access_key_id}:{aws_secret_access_key}@athena.{region_name}.amazonaws.com:443/{schema_name}?s3_staging_dir={s3_bucket_path}` の形式となる。
    -   **成果物:** なし（Superset UI 上での設定）
    -   **検証方法:** 「Test Connection」ボタンを押し、接続が成功することを確認する。

## Phase 3: データセットの定義

-   **タスク 3.1: dbt Gold テーブルの Dataset 登録**
    -   **内容:** dbt で生成された Gold 層のテーブル（例: `featured_activities`）を Superset の Dataset として登録する。
    -   **成果物:** なし（Superset UI 上での設定）
    -   **検証方法:** 「Data」->「Datasets」画面に `featured_activities` が追加され、データプレビューが正しく表示されることを確認する。時系列分析用のカラム（例: `timestamp`）を `Is temporal` として指定する。

## Phase 4: 可視化とダッシュボードの作成

-   **タスク 4.1: 基本的なチャートの作成**
    -   **内容:** `featured_activities` Dataset を使用して、以下の3種類のチャートを作成する。
        1.  KPI カード（レコード総数など）
        2.  時系列推移グラフ（アクティビティ数の時間変化）
        3.  構成比グラフ（アクティビティ種別ごとの割合）
    -   **成果物:** なし（Superset UI 上での設定）
    -   **検証方法:** 各チャートが意図した通りにデータを可視化できていることを確認する。SQL Lab や計算列で複雑なロジックを加えていないことを確認する。

-   **タスク 4.2: ダッシュボードの作成**
    -   **内容:** 作成したチャートを１つのダッシュボードにまとめる。
    -   **成果物:** なし（Superset UI 上での設定）
    -   **検証方法:** ダッシュボードが正しく表示され、日付などで基本的なフィルタが機能することを確認する。

## Phase 5: ドキュメントと運用ルールの整備

-   **タスク 5.1: README の作成**
    -   **内容:** Superset の起動方法、設定の概要、運用上の注意点をまとめた README ファイルを作成する。
    -   **成果物:** `docker/superset/README.md`
    -   **検証方法:** 第三者が README を読んで、環境の起動と基本的な操作を理解できるかレビューする。
