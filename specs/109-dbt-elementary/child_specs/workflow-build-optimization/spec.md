# 要件: GitHub Actions の Lambda/Layer ビルドを条件付きでスキップ

## 背景/Context
- `build.sh` が毎回実行されることで Python パッケージの再ビルドに時間がかかる。
- 無条件にスキップすると `build/layer.zip` が無くて Terraform が失敗する。

## 目的
- 変更がない場合はビルドを省略し、PR/CI の所要時間を短縮する。
- 変更がある場合は確実にビルドを実行し、Terraform での参照エラーを防ぐ。

## 対象スコープ
- GitHub Actions の Lambda/Layer ビルドステップ
- `build/layer.zip` の生成要否判定

## 非対象
- `.github/workflows/` の直接編集（運用ルールにより別チケット対応）

## 機能要件（FR）
- FR-1: 変更が無い場合、Lambda/Layer のビルドをスキップできる。
- FR-2: 変更がある場合、必ずビルドを実行する。
- FR-3: スキップ時も `build/layer.zip` が存在していれば Terraform が成功する。

## 非機能要件（NFR）
- NFR-1: スキップ判定は明確で再現可能。
- NFR-2: ログにスキップ理由が出力される。

## 判定条件案
- 変更がある場合のみ build を実行
  - `layer/**` / `convert_log_to_parquet/**` / `download_and_upload/**`
  - `build.sh` / `requirements.txt` / `pyproject.toml` などの依存定義

## 実装方針
- GitHub Actions で `paths` か `git diff` 判定を行い、
  `build.sh` の実行可否を切り替える。
- スキップ時に `build/layer.zip` が存在しなければ build を実行する。

## 受け入れ基準（Acceptance Criteria）
- AC-1: 変更が無い PR で build がスキップされる。
- AC-2: 変更がある PR で build が実行される。
- AC-3: いずれの場合も Terraform が成功する。

---
