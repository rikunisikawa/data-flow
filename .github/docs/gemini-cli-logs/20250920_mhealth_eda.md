# mHealth EDA (dev) — 2025-09-20

目的: Athena上の `raw_activities` を確認し、特徴量設計（featured_activities）に必要な観点を整理する。

対象テーブル
- Database: `dev_stage_mhealth`（Terraformのworkspace dev）
- Table: `raw_activities`
- Partitions: `subject_id` (string), `activity_label` (string)
- 留意: `activity_label = '0'` は除外対象（Nullクラス）

カラム（24列）
- chest_acc_x, chest_acc_y, chest_acc_z, chest_ecg_1, chest_ecg_2
- left_ankle_acc_x, left_ankle_acc_y, left_ankle_acc_z
- left_ankle_gyro_x, left_ankle_gyro_y, left_ankle_gyro_z
- left_ankle_mag_x, left_ankle_mag_y, left_ankle_mag_z
- right_lower_arm_acc_x, right_lower_arm_acc_y, right_lower_arm_acc_z
- right_lower_arm_gyro_x, right_lower_arm_gyro_y, right_lower_arm_gyro_z
- right_lower_arm_mag_x, right_lower_arm_mag_y, right_lower_arm_mag_z
- activity_label (bigint)

スキーマ確認
```sql
-- 先頭数件
SELECT *
FROM dev_stage_mhealth.raw_activities
LIMIT 10;

-- 列型（Athena/Glueメタデータ）
DESCRIBE dev_stage_mhealth.raw_activities;

-- パーティション一覧
SHOW PARTITIONS dev_stage_mhealth.raw_activities;
```

基本分布と件数確認
```sql
-- 活動ラベルの分布（nullクラス'0'は除外）
SELECT activity_label, COUNT(*) AS cnt
FROM dev_stage_mhealth.raw_activities
WHERE activity_label <> 0
GROUP BY activity_label
ORDER BY activity_label;

-- 被験者×活動のサンプル数
SELECT subject_id, activity_label, COUNT(*) AS cnt
FROM dev_stage_mhealth.raw_activities
WHERE activity_label <> 0
GROUP BY subject_id, activity_label
ORDER BY subject_id, activity_label;
```

レンジ/外れ値の当たりをつける（例: 胸部加速度）
```sql
SELECT
  MIN(chest_acc_x) AS min_x,
  MAX(chest_acc_x) AS max_x,
  AVG(chest_acc_x) AS avg_x,
  STDDEV_SAMP(chest_acc_x) AS std_x,
  MIN(chest_acc_y) AS min_y,
  MAX(chest_acc_y) AS max_y,
  AVG(chest_acc_y) AS avg_y,
  STDDEV_SAMP(chest_acc_y) AS std_y,
  MIN(chest_acc_z) AS min_z,
  MAX(chest_acc_z) AS max_z,
  AVG(chest_acc_z) AS avg_z,
  STDDEV_SAMP(chest_acc_z) AS std_z
FROM dev_stage_mhealth.raw_activities
WHERE activity_label <> 0;

-- 被験者単位の特徴の差異（例: subject_id単位）
SELECT subject_id,
       AVG(chest_acc_x) AS s_avg_x,
       STDDEV_SAMP(chest_acc_x) AS s_std_x
FROM dev_stage_mhealth.raw_activities
WHERE activity_label <> 0
GROUP BY subject_id
ORDER BY subject_id;
```

EDA所感（初期仮説）
- `activity_label` ごとに加速度のレンジ・分散に差異が出る想定。平均・標準偏差・min/maxが基本指標として有効。
- 特徴量の基本セットは、事前集計済みの `cleaned_activities` の平均列（3軸平均）をもとに、`mean/std/min/max` を `user_id（＝subject_id）×activity_label` で集約する方針が妥当。
- `activity_label = 0` を除外して学習データを作成する。

dbt設計との対応
- 入力: `cleaned_activities`（`user_id`, `activity_label`, `*_acc_avg` などの平均列）
- 出力: `featured_activities`（`*_acc_avg` の mean/std/min/max を `user_id`×`activity_label` で集約）
- 品質: `tests.yml` に `not_null` を付与済み（`user_id`, `activity_label`, 各特徴量）

次のアクション
1) ローカルで `.env.dev` を用いて接続検証
   - `data_flow_dbt/scripts/with-env.sh dbt debug`
2) 特徴量モデルの実行・検証
   - `data_flow_dbt/scripts/with-env.sh dbt run -m featured_activities`
   - `data_flow_dbt/scripts/with-env.sh dbt test -m featured_activities`
3) 分布・欠損・外れ値の再確認と、必要に応じて特徴量の追加（周波数領域などは将来検討）

