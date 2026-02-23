# Skill: 10-discover — データ発見・所在マッピング

## name
10-discover

## description
分析に必要なデータの所在・形式・粒度・依存関係を整理したデータマップを生成する。
実データへのアクセス・クエリ実行は行わない。生成のみ。

---

## 目的
「どのデータが、どこに、どんな形式で存在するか」を構造化する。
後続の契約（20-contract-quality）・変換設計（30-transform-blueprint）の前提を固める。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:          依頼の識別子（00-intakeと同じもの）
date:          依頼日（YYYYMMDD）
data_sources:  データソース名のリスト（プレースホルダOK。例: [source_a, source_b]）
known_tables:  既知のテーブル/ファイル名（不明ならTBD）
date_range:    対象期間（例: 2024-01〜2025-12）
grain:         想定する粒度（例: 1レコード = 被験者1名1分間のセンサログ）
join_keys:     テーブル間の結合キー候補（不明ならTBD）
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/data_map.txt
docs/artifacts/<date>_<slug>/grain_notes.txt
```

---

## ガードレール（禁止事項）

- 実データソースへの接続・クエリ実行は行わない
- テーブルの実スキーマを推測で断定しない（「不明」と明記する）
- secrets（接続文字列・アカウントID等）を成果物に含めない
- 「このテーブルには〇〇カラムがある」という確認前の断言はしない

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 00-intakeの成果物（analysis_charter.txt）を参照しながらパラメータを埋める
2. データソースはプレースホルダ（[source_name]）で構わない
3. 生成後に担当エンジニアが実際のパスと照合して補完する

---

## 関連テンプレート

- `templates/data_map.txt`        → データ所在マップの雛形
- `templates/grain_checklist.txt` → 粒度確認チェックリスト
