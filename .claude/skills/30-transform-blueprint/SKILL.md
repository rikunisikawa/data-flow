# Skill: 30-transform-blueprint — 変換設計書の生成

## name
30-transform-blueprint

## description
データ変換ロジックの設計書（変換ブループリント）と命名規約を生成する。
変換コードの実行・ETLジョブの起動は行わない。生成のみ。

---

## 目的
「生データをどう加工してどのテーブルに格納するか」を設計文書として記述する。
dbt・Glue・Spark・SQLなど特定ツールに依存しない抽象設計書として生成する。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:              依頼の識別子
date:              依頼日（YYYYMMDD）
source_tables:     変換元テーブル/ファイル
target_tables:     変換先テーブル/ファイル
transform_steps:   変換ステップのサマリ（フィルタ・集計・結合・マスキング等）
dedup_strategy:    重複排除の方針（例: timestamp降順でROW_NUMBER=1）
null_handling:     NULL処理の方針（例: 埋める/除外/フラグ立て）
naming_rules:      命名規約の指定があれば（例: snake_case, prefix=stg_）
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/transform_blueprint.txt
```

---

## ガードレール（禁止事項）

- ETLジョブ・dbt run・Glue Job の実行は行わない
- テーブルへの書き込み・上書きは行わない
- 本番テーブルに対するDMLは絶対に行わない
- 実行用のコマンドを成果物に含める場合は「[実行禁止。要L3承認]」ラベルを付ける

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 20-contract-qualityの成果物（data_contract.yaml）を参照してパラメータを埋める
2. ツール名は抽象化して記述する（「集計処理」と書き、dbt/Glue/SQLを断定しない）
3. Builder Agent がレビューし、Governance Agent が承認確認する
4. 実装時はL3承認を得てからエンジニアが実施する

---

## 関連テンプレート

- `templates/transform_blueprint.txt` → 変換設計書の雛形
- `templates/naming_conventions.txt`  → 命名規約の雛形
