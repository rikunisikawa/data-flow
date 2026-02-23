# Skill: eda-notebook

## 目的
小サンプルデータを前提とした探索的データ分析（EDA）のノートブックテンプレートを生成し、
分析仮説リストを出力するスキル。
大規模データの直接読み込みや実行は行わない。

## 対象データ（本プロジェクト）
- mHealth Parquetファイル（S3 `/stage/` または `/processed/`）
- センサ種別: 胸部加速度・ECG・足首加速度・腕加速度
- ラベル: activity_label (0〜12, 活動種別)

## 提供する成果物
1. **EDAノートブックテンプレート**: Jupyter形式の分析骨格（.ipynb設計）
2. **分析仮説リスト**: 検証すべき仮説の列挙
3. **可視化プラン**: グラフ種別・軸・フィルタ条件
4. **小サンプル戦略**: 本番データを使わない検証設計

## 使用方法
```
# Orchestratorからの呼び出し例
[eda-notebook]: mHealthデータのEDAテンプレートを生成してください。
               センサ値の分布と活動ラベルとの関係に着目してください。
```

## 禁止事項
- 大規模データの直接読み込み（フルスキャン等）
- S3への書き込み
- Jupyter Kernelの実行

## EDAノートブックテンプレート構成
```python
# Cell 1: 環境設定（実行時に適宜パスを変更すること）
# ⚠ 小サンプル（1ファイル、先頭1000行）のみで検証すること
import pandas as pd
import pyarrow.parquet as pq
import matplotlib.pyplot as plt
import seaborn as sns

SAMPLE_PATH = "/tmp/sample_mhealth.parquet"  # ローカルサンプルパス

# Cell 2: データ読み込み（サンプルのみ）
df = pd.read_parquet(SAMPLE_PATH)
print(f"Shape: {df.shape}")
print(df.dtypes)
print(df.head())

# Cell 3: 基本統計
print(df.describe())
print(f"NULL件数:\n{df.isnull().sum()}")

# Cell 4: activity_label 分布
df['activity_label'].value_counts().plot(kind='bar')
plt.title('Activity Label Distribution')
plt.show()

# Cell 5: センサ値分布（activity_labelごと）
for col in ['acc_chest_x', 'acc_chest_y', 'acc_chest_z', 'ecg_lead1']:
    df.boxplot(column=col, by='activity_label', figsize=(10, 4))
    plt.title(f'{col} by activity_label')
    plt.show()

# Cell 6: 相関マトリックス
sensor_cols = [c for c in df.columns if c != 'activity_label']
corr = df[sensor_cols].corr()
sns.heatmap(corr, annot=False, cmap='coolwarm')
plt.title('Sensor Correlation Matrix')
plt.show()

# Cell 7: 時系列プロット（先頭500行）
df.head(500)[['acc_chest_x', 'ecg_lead1']].plot(figsize=(12, 4))
plt.title('Time Series Sample (first 500 rows)')
plt.show()
```

## 分析仮説リスト
- 仮説1: activity_labelが異なると加速度センサ値の平均・分散が有意に異なる
- 仮説2: 安静時（label=0）はECG値の変動が最小である
- 仮説3: 胸部・足首・腕の加速度は活動種別ごとに異なる相関パターンを示す
- 仮説4: NULLはセンサオフ期間に集中して発生する（時系列的な偏り）
- 仮説5: ECG lead1とlead2は高い正の相関を持つ

## 可視化プラン
| グラフ種別    | X軸              | Y軸/色        | 目的                    |
|-------------|-----------------|-------------|------------------------|
| Boxplot     | activity_label  | センサ値     | 活動別センサ分布の把握   |
| Heatmap     | カラム           | カラム       | センサ間相関の把握       |
| Line chart  | 行インデックス    | センサ値     | 時系列パターンの確認     |
| Histogram   | センサ値          | 頻度         | 分布の歪みの確認         |

## 関連スキル
- `sql-generator`: EDA仮説に基づくAthenaクエリ生成
- `schema-contract`: カラム定義の参照
- `data-governance-guard`: PIIカラムの確認
