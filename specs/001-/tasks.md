# Tasks: データ基盤におけるテストの実装

**Input**: Design documents from `/specs/001-/`
**Prerequisites**: plan.md, research.md, quickstart.md

## Phase 3.1: Setup
- [ ] T001 [P] `tests/requirements.txt` を作成し、`pytest`, `boto3`, `pandas`, `pyarrow` を追加します。

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T002 [P] `tests/test_convert_log_to_parquet.py` を作成し、`convert_log_to_parquet.py` のための基本的な（失敗する）テストケースを1つ追加します。
- [ ] T003 [P] `tests/test_download_and_upload.py` を作成し、`download_and_upload.py` のための基本的な（失敗する）テストケースを1つ追加します。

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T004 `tests/test_convert_log_to_parquet.py` に、正常系および異常系のシナリオをカバーする具体的なテストを実装します。
- [ ] T005 `tests/test_download_and_upload.py` に、正常系および異常系のシナリオをカバーする具体的なテストを実装します。

## Phase 3.4: Integration
- [ ] T006 `data_flow_dbt/models/tests.yml` を設定し、`dbt test` を実行してdbtモデルのテストを実施します。

## Phase 3.5: Polish
- [ ] T007 [P] 作成したすべてのテストコードをレビューし、可読性と保守性を向上させるためのリファクタリングを行います。
- [ ] T008 [P] `README.md` または関連ドキュメントを更新し、テストの実行方法を記載します。

## Dependencies
- T001 は T002, T003 より前に実行する必要があります。
- T002, T003 は T004, T005 より前に実行する必要があります。
- T004, T005 は T007 より前に実行する必要があります。

## Parallel Example
```
# Launch T002 and T003 together:
Task: "T002 [P] `tests/test_convert_log_to_parquet.py` を作成し、`convert_log_to_parquet.py` のための基本的な（失敗する）テストケースを1つ追加します。"
Task: "T003 [P] `tests/test_download_and_upload.py` を作成し、`download_and_upload.py` のための基本的な（失敗する）テストケースを1つ追加します。"
```
