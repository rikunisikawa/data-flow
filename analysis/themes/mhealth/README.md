# mHealth EDA

## 目的
- mHealthログの品質と分布を把握し、後続の特徴量設計/モデル評価の前提を整える
- subject_id / activity_label の偏りや欠損を整理する

## 実行方法
```bash
python analysis/src/eda.py --input-dir analysis/data --output-dir analysis/reports/eda
```

## テーマ共通の構成
新規テーマは `analysis/themes/_template` をコピーして作成します。

## Dockerでの実行
### ビルド
```bash
docker build -f analysis/docker/Dockerfile -t data-flow-analysis .
```

### コンテナ起動
```bash
docker run --rm -it -v "$(pwd)":/workspace data-flow-analysis
```

### Notebook実行→要約生成（最小ループ）
コンテナ内で以下を実行します。
```bash
python analysis/themes/mhealth/src/run_pipeline.py
```

個別に実行したい場合は次のとおりです。
```bash
python analysis/src/eda.py --input-dir analysis/data --output-dir analysis/reports/eda
python analysis/themes/mhealth/src/extract_summary.py
```

## 使い方の流れ
1. `analysis/src/eda.py`で`analysis/reports/eda/`にCSV/PNG/JSONを出力
2. `analysis/themes/mhealth/src/extract_summary.py`で`summary.json`と`findings.txt`を生成
3. `analysis/themes/mhealth/src/run_pipeline.py`でNotebook実行→要約生成→状態更新を一括実行

## 成果物ディレクトリ
- 実行済みNotebook: `analysis/themes/mhealth/eda/executed/`
- 要約JSON: `analysis/themes/mhealth/artifacts/summaries/`
- 要約テキスト: `analysis/themes/mhealth/artifacts/findings/`
- ループ状態: `analysis/themes/mhealth/agent/state.json`

## 出力物
- `analysis/reports/eda/basic_stats.csv`
- `analysis/reports/eda/activity_counts.csv`
- `analysis/reports/eda/subject_counts.csv`
- `analysis/reports/eda/subject_activity_counts.csv`
- `analysis/reports/eda/activity_counts.png`
- `analysis/reports/eda/subject_counts.png`
- `analysis/reports/eda/subject_activity_heatmap.png`
- `analysis/reports/eda/checksums.json` (行数・合計の検算ログ)
