# Feature: Apache Superset 導入 (issue #122)

## 1. 目的と前提

### 目的
- 既存の AWS × dbt × データ分析基盤に Apache Superset を追加する。
- Superset は **可視化専用（Read Only）** とし、既存基盤の設計思想を維持する。
- 既存の ELT / dbt / データ定義は変更しない。

### 前提
- S3 を中心としたデータレイク（Bronze / Silver / Gold）が存在する。
- dbt により Gold 層のテーブルが作成済みである。
- クエリエンジンとして Amazon Athena を利用している。
- 利用者は単一ユーザーとし、認証連携やマルチユーザー、RLS（行レベルセキュリティ）は考慮しない。

---

## 2. アーキテクチャ上の位置づけ

### Superset の役割
- Superset は **Visualization Layer** として機能する。
- Superset は以下のロジックを持たない。
  - ビジネスロジック定義
  - JOIN / 集計ロジック
  - データの書き込み・更新

### 依存関係
Source → EL → S3（Bronze）→ Glue / dbt（Silver / Gold）→ Athena → **Apache Superset（参照のみ）**

---

## 3. 導入方針（設計原則）

### 原則1：Single Source of Truth は dbt
- KPI 定義、集計粒度、ビジネスルールはすべて dbt で定義する。
- Superset 側でこれらのロジックを再定義しない。

### 原則2：Superset は Gold 層のみ参照
- Silver / Bronze 層のテーブルは Superset に接続・登録しない。
- Dataset の登録対象は dbt が生成した Gold 層のテーブルのみとする。

### 原則3：Superset は再生成可能（Reproducible）
- Docker および Docker Compose を用いて環境を構築する。
- 手動設定への依存を避け、環境の破棄・再作成が容易な状態を維持する。

---

## 4. 導入タスク概要

1.  **Superset 実行環境の構築**: Docker Compose を用いてローカルまたは単一ホストで Superset を起動する。
2.  **Superset 初期設定**: タイムゾーンやロケールを日本環境に設定する。
3.  **Athena への接続**: Read Only 権限を持つ IAM ユーザーを用いて、Superset から Athena へ接続する。
4.  **Superset Dataset 定義**: dbt Gold モデルを Superset の Dataset として登録する。
5.  **可視化とダッシュボード作成**: KPI や時系列推移を可視化し、目的別のダッシュボードを作成する。

---

## 5. dbt × Superset 連携ルール

### dbt の責務
- KPI の定義
- 集計粒度の固定
- カラム定義とその意味を `dbt docs` に記載

### Superset の責務
- `dbt docs` を参照して可視化を設計
- dbt で定義された意味やロジックを変更しない

> **定義の正は常に dbt とする。**

---

## 6. セキュリティ・運用ルール

### セキュリティ
- Superset からのデータ書き込み権限は付与しない。
- Athena 接続に用いる IAM ユーザーの権限は、必要な Glue Data Catalog と S3 バケットへの読み取りアクセスに限定する（最小権限の原則）。
- 個人利用を前提とし、RLS は設定しない。

### 運用
- Superset 環境は jederzeit 停止・再作成可能であること。
- データは Superset 内に保存せず、キャッシュ利用を基本とする。
- Superset の障害がデータ基盤全体の障害に影響を与えないように分離する。

---

## 7. 完了条件

- Superset が Docker 環境で起動し、管理者としてログイン可能である。
- dbt Gold テーブルが Superset の Dataset として参照可能である。
- dbt で定義した KPI が Superset 上で正しく可視化されている。
- Superset 内に独自のビジネスロジック（SQL での JOIN、複雑な計算列など）が存在しない。

---

## 8. 回避すべきアンチパターン

- Superset の SQL Lab で複雑な集計 SQL を作成し、チャートの元データとすること。
- Silver 層のテーブルを Dataset として登録すること。
- Superset を「定義の正」としてしまい、dbt との二重管理状態に陥ること。
- 手動での環境設定に依存し、再現性のない運用を行うこと。
