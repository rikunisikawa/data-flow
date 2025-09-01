# Issue-76: テストコード実装計画書

本計画書は、Issue-76「テストコードの実装」に基づき、pytestを用いた自動テストの設計と実装に関する具体的な計画を定義する。

## 1. 目的と範囲

-   **対象コンポーネント**:
    -   **Lambda**:
        -   `download_and_upload.py`: 外部ソースからのデータダウンロードとS3へのアップロード機能。
        -   `convert_log_to_parquet.py`: S3上のログファイル（JSON/CSV）をParquet形式に変換する機能。
    -   **AWS Glue**:
        -   `glue_job/glue_job.py`: S3上のデータを変換・加工するETLジョブ。
    -   **dbt Models**:
        -   `models/cleaned_activities.sql`: 生データをクレンジングし、分析用の基本テーブルを作成するモデル。
    -   **AWS Step Functions**:
        -   `state_machine/data_processing.asl.json`: データ処理パイプライン全体のオーケストレーション。
-   **テスト粒度**:
    -   **ユニットテスト**: Lambda関数内の特定のロジック（データ変換、バリデーション等）を対象とする。AWSサービスへの依存はモック化する。
    -   **統合テスト**: Lambda, Glue, Step Functionsが連携する一連のフローを対象とする。AWSサービスは`moto`や`localstack`を用いてエミュレートする。
    -   **データ品質テスト**: dbtの`test`機能を利用し、モデル生成後のデータの整合性（一意性、非NULL、参照整合性）を検証する。
-   **アウトオブスコープ**:
    -   外部APIのE2Eテスト。
    -   厳密なパフォーマンステストおよび負荷テスト。
    -   手動によるUIテスト。

## 2. 技術スタックと前提

-   **言語/バージョン**: Python 3.11
-   **テストFW**: pytest
-   **実行環境**:
    -   ローカル: `venv` を使用
    -   CI: GitHub Actions (`ubuntu-latest`)
-   **依存サービスと代替手段**:
    -   **AWSサービス**: S3, Lambda, Glue, Step Functions, IAM
    -   **代替**: `moto` をプライマリなモックライブラリとして使用する。`moto`でカバーできない部分は`botocore.stub.Stubber`で補完する。
-   **時刻/UUID/乱数の固定**: `freezegun`ライブラリを使用する。

## 3. テスト方針と優先度

クリティカルパスであるデータ処理フローの上流から下流にかけて優先的に実装する。

1.  **P0 (最優先)**: `download_and_upload.py` のユニット/統合テスト (データ取り込みの起点)
2.  **P0 (最優先)**: `convert_log_to_parquet.py` のユニット/統合テスト (後続処理の入力データ生成)
3.  **P1 (高)**: `glue_job.py` の統合テスト (コアなETLロジック)
4.  **P1 (高)**: `dbt models` のデータ品質テスト (データマートの信頼性担保)
5.  **P2 (中)**: Step Functions の統合テスト (ワークフロー全体の正常性)

## 4. 仕様と期待結果（GIVEN-WHEN-THEN）

-   **ケース1: Lambda `download_and_upload`**
    -   **GIVEN**: ダウンロード対象のURLとアップロード先のS3バケット/キーが環境変数で設定されている。
    -   **WHEN**: `download_and_upload.handler` を実行する。
    -   **THEN**: 指定したS3バケットに、ダウンロードしたファイルが期待されるキーで保存される。

-   **ケース2: Lambda `convert_log_to_parquet`**
    -   **GIVEN**: 入力S3バケットに、テスト用のJSONログファイルが配置されている。
    -   **WHEN**: S3 Putイベントを模したテストイベントで `convert_log_to_parquet.handler` を実行する。
    -   **THEN**: 出力S3バケットに、Parquet変換されたファイルが期待されるパーティションキー構造で保存され、スキーマが正しい。

-   **ケース3: Glue `glue_job`**
    -   **GIVEN**: 入力S3バケットに、変換元となるParquetファイルが配置されている。
    -   **WHEN**: Glueジョブスクリプトをローカルで実行する。
    -   **THEN**: 出力S3バケットに、変換後のParquetファイルが生成され、レコード数や特定のカラムの値が期待通りである。

-   **ケース4: dbt `cleaned_activities` モデル**
    -   **GIVEN**: dbtの`seeds`機能でソーステーブルにテストデータを投入する。`models/tests.yml`に主キーの一意性、非NULL制約のテストを定義する。
    -   **WHEN**: `dbt run` を実行後、`dbt test` を実行する。
    -   **THEN**: すべてのテストがパスし、CIの実行をブロックしない。

## 5. データとフィクスチャ

-   **固定データ**: `tests/data/` ディレクトリを新設し、各テストケースで使用する最小限のサンプルデータ（JSON, CSV, Parquet）を格納する。
-   **フィクスチャ**: `tests/conftest.py` にて、テスト全体で共通して利用する設定やリソースを定義する。
    -   `moto` を用いたAWSサービス（S3, IAM Role等）のセットアップ・テアダウン。
    -   `boto3` クライアントのフィクスチャ。
    -   `freezegun` を適用するフィクスチャ。

## 6. モック/スタブ/Spy

-   **置換対象**: `boto3.client` を `moto` でモックする。
-   **手段**: `pytest-mock` の `monkeypatch` フィクスチャを利用して、環境変数や外部ライブラリの関数をテスト用に差し替える。
-   **ネットワーク**: `moto` の利用により、テスト実行中の外部ネットワークアクセスは不要となる。

## 7. 構成と命名

-   **ディレクトリ構成**:
    ```
    tests/
    ├── unit/
    │   ├── test_convert_log_to_parquet.py
    │   └── test_download_and_upload.py
    ├── integration/
    │   ├── test_data_processing_workflow.py
    │   └── test_glue_job.py
    ├── data/
    │   ├── sample_log.json
    │   └── sample_input.parquet
    ├── utils/
    │   └── aws_helpers.py
    └── conftest.py
    ```
-   **命名規約**:
    -   ファイル名: `test_<module_name>.py`
    -   関数名: `test_<behavior>__<condition>` (例: `test_handler__success_on_valid_event`)

## 8. 実装ルール

-   **アサーション**: `assert` を使用する。データフレームの比較など、複雑な検証は `pandas.testing.assert_frame_equal` などを利用する。
-   **パラメタライズ**: 正常系・異常系の複数の入力パターンをテストするため、`@pytest.mark.parametrize` を積極的に活用する。
-   **ログ検証**: `caplog` フィクスチャを用いて、期待するログメッセージが出力されることを検証する。

## 9. 品質基準

-   **カバレッジ閾値**: `pytest-cov` を用いて計測し、以下の基準を満たすことを目標とする。
    -   行カバレッジ: 85%以上
    -   分岐カバレッジ: 70%以上
-   **静的解析**: `ruff` と `mypy` を導入し、CIでコード品質をチェックする。これらのチェックをパスしないPull Requestはマージをブロックする。

## 10. CI/CD 統合 (GitHub Actions)

-   `.github/workflows/` に `ci-test.yml` を新設する。
-   **CIジョブのステップ**:
    1.  リポジトリをチェックアウト
    2.  Python環境をセットアップ
    3.  `requirements.txt` および `tests/requirements.txt` から依存パッケージをインストール（キャッシュを有効化）
    4.  `ruff` と `mypy` による静的解析を実行
    5.  `pytest` を実行し、ユニットテストと統合テストを実施
    6.  `pytest-cov` を用いてカバレッジレポートを生成
    7.  カバレッジが閾値未満の場合、ジョブを失敗させる
    8.  テスト結果（JUnit形式）とカバレッジレポート（HTML）をアーティファクトとしてアップロード

-   **ローカル実行コマンド**:
    ```bash
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt -r tests/requirements.txt
    pytest --cov=src --cov-report=term-missing
    ```

## 11. セキュリティ/コンプライアンス

-   **シークレット**: テストコード内ではダミーのAWS認証情報を使用し、実際のシークレットは参照しない。
-   **PII/機微情報**: `tests/data/` に格納するサンプルデータは、PIIを含まない合成データまたは匿名化されたデータのみとする。

## 12. 曖昧性解消ルール

-   Issueテンプレートの記載に準拠する。
-   優先順位: 既存コードの挙動 > プロダクト仕様 > 一般的な慣習
-   原則として、不正な入力（例: `None`）に対しては例外を送出する設計とする。

## 13. 出力物

1.  **追加/変更ファイル一覧**:
    -   `tests/**`: テストコード、フィクスチャ、ヘルパー、サンプルデータ
    -   `.github/workflows/ci-test.yml`: CI設定ファイル
    -   `tests/requirements.txt`: テスト実行に必要なライブラリ
2.  **実行結果サマリ**: Pull Requestのコメントにpytestの実行結果とカバレッジレポートのサマリを記載する。
3.  **残課題**:
    -   `moto`でサポートされていないAWSサービスのテスト方法の検討。
    -   実行時間が長くなる統合テストの分離と最適化。

## 14. レビューチェックリスト（自己チェック）

-   [ ] 時刻/UUID/乱数固定で再現性がある
-   [ ] テスト間が独立（データ汚染なし）
-   [ ] Arrange-Act-Assert (または GIVEN-WHEN-THEN) の構造で可読性が高い
-   [ ] 外部通信なし（moto/stubs のみ）
-   [ ] データ品質ルール（主キー一意/Null/値域/参照整合）を明文化・検証
-   [ ] カバレッジ閾値達成、CI ブロッキング動作確認
-   [ ] 大きなファイルや長時間テストを避け、CI実行が5分以内に収まる
