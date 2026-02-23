# Skill: 40-eda — 探索的データ分析（EDA）計画・仮説生成

## name
40-eda

## description
小サンプルを前提としたEDA計画・分析仮説リスト・ノートブックテンプレートを生成する。
大規模データの直接読み込み・クエリ実行は行わない。生成のみ。

---

## 目的
「何を探索し、どんな仮説を検証するか」を構造化する。
EDA実施前に仮説を明示しておくことでアンカリングを防ぎ、分析の質を高める。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:            依頼の識別子
date:            依頼日（YYYYMMDD）
question:        分析の問い（00-intakeと同じ）
target_variable: 予測/分析対象の変数（例: activity_label, 離脱フラグ）
feature_columns: 特徴量として検討するカラム群
sample_size:     検証用サンプルの想定件数（例: 1000行）
hypotheses:      ユーザーが持っている仮説（なくてもOK）
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/eda_plan.txt
docs/artifacts/<date>_<slug>/hypothesis_log.txt
```

---

## ガードレール（禁止事項）

- 大規模データのフルスキャンは行わない（サンプル前提のみ）
- クエリ実行・Jupyter Kernel実行は行わない
- 統計的結論を実データ確認前に断言しない（「仮説」として記述する）
- 個人データ・PIIを仮説例として使用しない

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 20-contract-qualityおよび10-discoverの成果物を参照してパラメータを埋める
2. 仮説は「仮説A（楽観）」と「反証B（悲観）」をセットで生成する（アンカリング回避）
3. Analyst Agent が仮説を拡張し、Governance Agent が PII観点でレビューする
4. ノートブックテンプレはローカルサンプルで人間が実行する（自動実行しない）

---

## 関連テンプレート

- `templates/eda_plan.txt`        → EDA計画の雛形
- `templates/hypothesis_log.txt`  → 仮説ログの雛形
