# タスク: MHEALTHデータセット分析パイプライン実装

### 1. EDAとdbtモデル設計

- **内容**: AthenaコンソールまたはSQLクライアントを用いて `stage_raw_activities` テーブルの内容を調査する。どのような特徴量を作成するか（例：各センサー軸の平均、標準偏差、周波数領域の特徴など）を決定する。
- **成果物**:
    - EDAの結果メモ: `.github/docs/gemini-cli-logs/YYYYMMDD_mhealth_eda.md`
- **検証方法**: SQLクエリが実行でき、データの内容（カラム、データ型、サンプルデータ）が把握できること。

### 2. dbtによる特徴量生成モデルの実装

- **内容**: 調査結果に基づき、`featured_activities.sql` を作成する。ウィンドウ関数などを用いて、被験者ごと・活動ごとのセンサーデータから統計的特徴量を抽出する。
- **成果物**:
    - `data_flow_dbt/models/featured_activities.sql`
    - `data_flow_dbt/models/tests.yml` （`featured_activities` テーブル用のテストを追加）
- **検証方法**:
    - `dbt run` を実行し、Athena上に `featured_activities` テーブルが正常に作成されること。
    - `dbt test` を実行し、定義したテストがすべて成功すること。

### 3. モデル学習・評価用Pythonスクリプトの作成

- **内容**: `model_training` ディレクトリを新規作成し、`train_evaluate.py` を実装する。スクリプトには、データ取得、前処理、学習・テスト分割、XGBoostモデルの学習、評価指標（Accuracy, F1-Score）の計算、結果のS3への出力機能を含める。
- **成果物**:
    - `model_training/train_evaluate.py`
    - `tests/test_train_evaluate.py` （ユニットテスト）
- **検証方法**:
    - `pytest tests/test_train_evaluate.py` が成功すること。
    - スクリプトをローカルまたはLambda上で実行し、評価指標が計算され、S3に結果が出力されること。

### 4. Lambda実行環境の構築 (Terraform)

- **内容**: モデル学習に必要なライブラリを `layer/src/requirements.txt` に追加する。`terraform/modules/lambda/main.tf` に、`train_evaluate.py` を実行するLambda関数のリソース定義と、関連するIAMロールの権限（Athena, S3, Glueへのアクセス）を追加する。
- **成果物**:
    - `layer/src/requirements.txt` （更新）
    - `terraform/modules/lambda/main.tf` （追記）
    - `terraform/main.tf` （Lambdaモジュールの呼び出し部分を追記）
- **検証方法**:
    - `terraform plan` で差分が意図通りであること。
    - `terraform apply` が成功し、AWS上にLambda関数とレイヤーが作成されること。
    - AWSコンソールからLambda関数をテスト実行し、成功すること。

### 5. Step Functionsステートマシンの更新

- **内容**: `state_machine/data_processing.asl.json` を編集し、dbt実行タスクの後に、タスク4で作成したLambda関数を呼び出す `Task` ステートを追加する。
- **成果物**:
    - `state_machine/data_processing.asl.json` （更新）
- **検証方法**:
    - AWSコンソールでステートマシンの定義を更新し、グラフが意図したフローになっていることを確認する。
    - ステートマシンを実行し、すべてのステップが成功（Success）で完了すること。
    - 最終的な成果物（評価メトリクスファイル）がS3に保存されていることを確認する。
