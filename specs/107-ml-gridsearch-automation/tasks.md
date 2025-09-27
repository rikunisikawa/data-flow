# タスクリスト: ML グリッドサーチ自動化

### Task 1: 学習スクリプトの雛形作成
- 説明: `model_training/train_evaluate.py` を作成。データ取得（Athena/S3）、前処理、Group 分割、GridSearch、保存までを実装。
- 検証: ローカル/Docker でサンプル検索空間にて動作確認。

### Task 2: 検索空間の外部化
- 説明: `configs/hyperparams.yaml` を追加（モデル種別/パラメータ候補）。
- 検証: スクリプトが YAML を読み込み、GridSearch に反映。

### Task 3: コンテナ化
- 説明: Dockerfile（学習用）作成。依存: pandas, scikit-learn, xgboost, awswrangler。
- 検証: `docker run ... python train_evaluate.py --help` が成功。

### Task 4: 実行基盤（ECS or SageMaker）
- 説明: Terraform で実行基盤を用意（ECS RunTask または SageMaker Processing）。
- 検証: dev でジョブが成功し、S3 に成果物が保存。

### Task 5: Step Functions 統合
- 説明: dbt ステップ完了後に学習ステップを起動。入力パラメータで split/cv/seed/search_space を切替。
- 検証: 実行成功と失敗ハンドリング（Catch→Fail）確認。

### Task 6: ユニットテスト
- 説明: Group 分割・評価関数・保存 I/F のテストを追加（pytest）。
- 検証: `pytest` がグリーン。

### Task 7: ドキュメント
- 説明: `ai-doc/infra/system_design.md`/`ai-doc/operations/deployment_strategy.md` に学習ステップを追記。
- 検証: 記載手順で再現。

---
