# data_flow_dbt プロジェクト

mHealth ログデータを Athena 上で分析するための dbt プロジェクトです。ソース宣言、ステージング、特徴量生成、スナップショット、メトリクスおよびエクスポージャー定義、CI スクリプトを含み、dbt の主要機能をカバーしています。

## 主なディレクトリ
- `models/staging/`: 外部テーブルを正規化するビュー（データコントラクト対応）。
- `models/intermediate/`: エフェメラル中間モデル。
- `models/`: テーブル・インクリメンタルマートとドキュメント。
- `seeds/`: `activity_labels` シード（参照ディメンション）。
- `snapshots/`: `featured_activities` の SCD2 管理。
- `macros/`: 3 軸平均マクロ、カスタムテスト、アーティファクト集計、run-operation 用マクロ。
- `exposures/`: ダッシュボードや ML パイプラインとの依存関係。
- `scripts/ci/`: Slim CI を想定したビルド・アーティファクトアップロードスクリプト。

## 推奨コマンド
```bash
dbt deps
dbt seed
# state:modified セレクタを活用した差分ビルド
mkdir -p state && cp -r target state  # 初回は空でも可
dbt build --selector state_modified_plus_seeds --state state

dbt snapshot

dbt run-operation log_lineage --args '{"model_name": "fact_activity_metrics"}'

dbt docs generate && dbt docs serve
```

## CI 運用
- `scripts/ci/dbt_slim_ci.sh` を利用し、Slim CI + アーティファクト（manifest.json/run_results.json/catalog.json）を S3 へアップロードします。
- `selectors.yml` で state:modified とシードを組み合わせたセレクタを提供。
- `profiles.yml` で dev/stg/prod 環境を切り替え可能。

## 品質保証
- シード・モデルに対して `not_null`、`unique`、`relationships`、`non_negative` などのテストを定義。
- `fact_activity_metrics` にはカスタムデータテスト（負値検出）を追加。
- `stg_mhealth_activities` は契約 (`contract.enforced`) を有効化。
- `sources` で freshness 監視を設定。

## 拡張
- `packages.yml` で `dbt_utils` と `elementary` を導入。`elementary` による品質レポート出力や Great Expectations 連携の基礎として利用可能。
- `metrics.yml` に Semantic Layer 用メトリクスを定義。
- `exposures` を利用し、BI/ML 下流資産とのリネージを管理。
