# mHealth データ分析方針

## 目的
- mHealth のセンサーデータから活動ラベルを推定するための特徴量・モデル設計を整理する。
- AWS/Athena/dbt で作成した `featured_activities` を前提に、EDA と機械学習の再現手順を明確化する。

## データソース
- Athena/Glue Catalog 上の `featured_activities`（dbt で生成）。
- 主なカラム: `user_id`, `activity_label`, センサ統計量（mean/std/min/max）。

## EDA の進め方
1. **データ概要**
   - 行数・列数・データ型の確認。
   - 欠損値の有無を確認（`activity_label` を含む）。
2. **分布の確認**
   - `activity_label` のクラス分布（偏り有無の確認）。
   - `user_id` のサンプル数分布（ユーザー偏りの確認）。
3. **特徴量の統計量**
   - 各特徴量の平均・分散・最小/最大の確認。
   - ラベルごとの代表統計量（mean/std）を確認し、識別可能性を検討。
4. **簡易チェック**
   - 異常値の有無やスケール差が大きい特徴量をリスト化。
   - 必要に応じて標準化/正規化の要否を判断。

## 機械学習の進め方
1. **前処理**
   - 目的変数: `activity_label`（整数ラベル）。
   - 特徴量: `user_id` を除いた数値列。
   - ユーザー単位でのデータ分割（GroupShuffleSplit）。
2. **モデル候補**
   - ベースライン: XGBoost（多クラス）。
   - 追加検討: RandomForest / LightGBM（必要に応じて）。
3. **評価指標**
   - Accuracy と Macro F1 を基本指標に採用。
   - クラス不均衡が大きい場合は per-class F1 も確認。
4. **成果物**
   - ローカル保存: `notebooks/artifacts/mhealth_metrics_*.json`。
   - S3 保存（任意）: `S3_DATA_DIR/model_results/` 配下。

## 実装場所
- EDA と学習コード: `notebooks/01_eda_modeling.ipynb`
- 依存ライブラリ: `notebooks/requirements.txt`

## 次のアクション
- Athena から実データ取得ができる状態で EDA を実行し、分布・クラスバランスを確認。
- 必要に応じて特徴量追加（周波数領域特徴やセンサ軸別統計など）を dbt 側で拡張。
