# Skill: 50-ml-optional — ML計画・モデルカード・評価設計（任意）

## name
50-ml-optional

## description
機械学習モデルの計画書・モデルカード・評価設計書を生成する。
モデルの学習・推論・デプロイは行わない。生成のみ。

---

## 目的
MLプロジェクトの意思決定を構造化する。
「何を予測するか・どう評価するか・どんなリスクがあるか」を
モデル実装前に明文化しておく。

---

## 入力（ユーザーが埋めるパラメータ）

```
slug:              依頼の識別子
date:              依頼日（YYYYMMDD）
task_type:         タスク種別（例: 分類 / 回帰 / 異常検知 / 時系列予測）
target:            予測ターゲット変数
features:          入力特徴量の候補（EDA成果物から引用可）
eval_metrics:      評価指標（例: AUC / RMSE / F1 / Precision@K）
business_threshold: ビジネス要件としての閾値（例: Precision >= 0.9）
constraints:       制約（例: 推論遅延 < 100ms / モデルサイズ < 100MB）
pii_risk:          PIIを含む特徴量があるか（Y/N + 詳細）
```

## 出力（成果物ファイルのパス）

```
docs/artifacts/<date>_<slug>/ml_plan.txt
docs/artifacts/<date>_<slug>/eval_plan.txt
docs/artifacts/<date>_<slug>/model_card.txt
```

---

## ガードレール（禁止事項）

- モデルの学習（fit/train）は行わない
- 推論・予測の実行は行わない
- モデルファイルの保存・デプロイは行わない
- テストデータを成果物に含めない
- PIIを含む特徴量を使う場合は必ずGovernance Agentのレビューを経る

> **このSkillは生成のみ。実行はしない。**

---

## 使用手順

1. 40-edaの仮説ログを参照してパラメータを埋める
2. ML Agentが計画を生成し、Governance Agentがリスクレビューをする
3. ml_plan.txtはL3承認後に実装担当者へ渡す
4. model_card.txtは将来の監査・説明責任に使う

---

## 関連テンプレート

- `templates/ml_plan.txt`    → ML計画書の雛形
- `templates/model_card.txt` → モデルカードの雛形
- `templates/eval_plan.txt`  → 評価設計書の雛形
