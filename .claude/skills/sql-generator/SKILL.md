# Skill: sql-generator

## 目的
Athena向けのSQLを説明責任・コスト配慮コメント付きで生成するスキル。
SQLの実行は行わない。生成のみ。

## 対象環境
- クエリエンジン: AWS Athena (Presto/Trino互換)
- データカタログ: AWS Glue Data Catalog
- 対象テーブル: `mhealth_processed`（Glue Catalogに登録済み想定）
- S3データ: `s3://aws-data-platform-20250607/processed/`

## 提供する成果物
1. **分析SQL**: 用途別クエリ（集計・フィルタ・時系列等）
2. **コスト見積もりコメント**: スキャンサイズの目安
3. **最適化ヒント**: パーティション活用・カラム絞り込み
4. **実行前チェックリスト**: 誤クエリ防止項目

## 使用方法
```
# Orchestratorからの呼び出し例
[sql-generator]: activity_label別の各センサ平均値を集計するSQLを生成してください。
                コスト配慮コメントを付与してください。
```

## 禁止事項
- SQLの実行（Athena API呼び出し等）
- DDL/DML文の生成（SELECT以外）
- 結果データの取得・保存

## 出力フォーマット
```sql
-- ============================================================
-- クエリ目的: activity_label別センサ平均値集計
-- 対象テーブル: mhealth_processed
-- 推定スキャンサイズ: データ量依存（Parquetカラム絞り込みで削減可）
-- コスト配慮: SELECT * は避け、必要カラムのみ指定すること
-- 実行前確認: LIMIT句を付けて小規模確認後に本番実行すること
-- ============================================================
SELECT
    activity_label,
    AVG(acc_chest_x)    AS avg_acc_chest_x,
    AVG(acc_chest_y)    AS avg_acc_chest_y,
    AVG(acc_chest_z)    AS avg_acc_chest_z,
    AVG(ecg_lead1)      AS avg_ecg_lead1,
    COUNT(*)            AS record_count
FROM
    mhealth_processed
WHERE
    activity_label IS NOT NULL
GROUP BY
    activity_label
ORDER BY
    activity_label
-- LIMIT 100  -- 検証時はLIMITを有効化すること
;

-- 実行前チェックリスト:
-- [ ] テーブル名が正しいか (mhealth_processed)
-- [ ] カラム名がスキーマ契約と一致しているか
-- [ ] LIMIT句を外す前に小規模テストを行ったか
-- [ ] コスト上限を設定しているか (Athena workgroup設定)
```

## よく使うクエリテンプレート
- 件数確認: `SELECT COUNT(*) FROM mhealth_processed`
- サンプル確認: `SELECT * FROM mhealth_processed LIMIT 10`
- activity_label分布: `SELECT activity_label, COUNT(*) FROM mhealth_processed GROUP BY 1`
- 時系列サンプル: `SELECT * FROM mhealth_processed ORDER BY timestamp LIMIT 100`

## 関連スキル
- `schema-contract`: カラム定義の確認
- `eda-notebook`: EDA仮説に基づくSQL設計
