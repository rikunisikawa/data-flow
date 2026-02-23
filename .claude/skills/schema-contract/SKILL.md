# Skill: schema-contract

## 目的
データスキーマの契約定義を行うスキル。
NULL許容・型・値範囲を明示し、将来のテスト自動化に備えた契約書を生成する。
DDL/DMLの実行は行わない。

## 対象スキーマ（本プロジェクト）
mHealth データセットのカラム構成例:
- `timestamp`: BIGINT (Unix timestamp, NOT NULL)
- `acc_chest_x/y/z`: DOUBLE (加速度センサ値, NULLあり)
- `ecg_lead1/2`: DOUBLE (心電図, NULLあり)
- `acc_ankle_x/y/z`: DOUBLE (NULLあり)
- `acc_arm_x/y/z`: DOUBLE (NULLあり)
- `activity_label`: INT (0-12, NOT NULL)

## 提供する成果物
1. **スキーマ契約書**: カラム定義・型・NULL許容・値域
2. **整合性チェックリスト**: 将来のテストケース候補
3. **型不一致リスク表**: ログ→Parquet変換時の注意点
4. **Athena互換型マッピング**: Glue Catalog向けの型対応表

## 使用方法
```
# Orchestratorからの呼び出し例
[schema-contract]: mHealth Parquetファイルのスキーマ契約書を生成してください。
                  NULLポリシーと値域を明示すること。
```

## 禁止事項
- DDL実行（CREATE TABLE, ALTER TABLE等）
- DML実行（INSERT, UPDATE, DELETE等）
- Athena/Glueへの直接クエリ

## 出力フォーマット
```markdown
## スキーマ契約書: mhealth_processed

| カラム名       | 型      | NULL許容 | 値域          | 備考                    |
|---------------|---------|---------|--------------|------------------------|
| timestamp     | BIGINT  | NO      | > 0          | Unix timestamp (ms)    |
| acc_chest_x   | DOUBLE  | YES     | -20.0〜20.0  | 加速度 m/s²            |
| activity_label| INT     | NO      | 0〜12        | 0=静止, 1〜12=活動種別  |

## 整合性チェックリスト
- [ ] timestamp が NULL でないこと
- [ ] activity_label が 0〜12 の範囲内であること
- [ ] 各センサ値が物理的に妥当な範囲内であること

## 型不一致リスク
- ログファイルは空白区切りテキスト → DOUBLE変換時に空白・欠損に注意
- Parquet変換後の型をGlue Catalogと一致させること

## Athena互換型マッピング
| Pandas型 | Parquet型 | Athena型  |
|---------|---------|---------|
| float64 | DOUBLE  | double  |
| int64   | INT64   | bigint  |
```

## 関連スキル
- `data-intake`: データ所在の確認
- `sql-generator`: 契約に基づくSQLの生成
