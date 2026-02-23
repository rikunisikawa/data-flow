# Skill: 20-contract-quality — データ契約・品質計画

## name
20-contract-quality

## description
データスキーマの契約定義（型・NULL・値域・SLA）と品質チェック計画を生成する。
DDL/DMLの実行は行わない。生成のみ。

---

## 目的
「このデータはこうあるべき」という契約を文書化し、
後続の変換設計・EDAにおけるスキーマ不一致・品質トラブルを予防する。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:           依頼の識別子
date:           依頼日（YYYYMMDD）
tables:         対象テーブル/ファイルのリスト
columns:        各テーブルの主要カラム情報（わかる範囲で）
null_policy:    NULLを許容するカラムと禁止するカラムの方針
value_ranges:   値域の制約（例: age: 0-120, label: 0-12）
freshness_sla:  データ鮮度の要件（例: 24時間以内に更新）
pii_columns:    PII疑いカラム（不明の場合はTBD）
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/data_contract.yaml
docs/artifacts/<date>_<slug>/data_quality_plan.txt
```

---

## ガードレール（禁止事項）

- DDL実行（CREATE TABLE / ALTER TABLE 等）は行わない
- DML実行（INSERT / UPDATE / DELETE 等）は行わない
- 実データへのアクセス・プロファイリングは行わない
- 存在確認していないカラム名を確定的に記述しない（TBD を使う）
- PIIカラムを成果物ファイルに実値で含めない

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 10-discoverの成果物（data_map.txt）を参照してパラメータを埋める
2. カラム情報が不明な箇所は TBD とする
3. data_contract.yaml はYAML形式で生成され、将来のテスト自動化のベースになる
4. Governance Agent が独立レビューしてからレビュー承認する

---

## 関連テンプレート

- `templates/data_contract.yaml`      → データ契約のYAML雛形
- `templates/data_quality_plan.txt`   → 品質チェック計画の雛形
