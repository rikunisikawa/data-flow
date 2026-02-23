# Skill: data-intake

## 目的
データソースのメタデータを整理し、抽出設計を行うスキル。
実データの取得・書き込みは行わない。設計・定義のみを担う。

## 対象データソース（本プロジェクト）
- S3バケット: `s3://aws-data-platform-20250607/`
  - `/raw/`    : Kaggle mHealth ログファイル（生データ）
  - `/stage/`  : Parquet変換済みファイル
  - `/processed/`: Glue Job処理済みファイル
- Kaggle Dataset: mHealth dataset (ログ形式)

## 提供する成果物
1. **データ所在マップ**: パス・形式・推定サイズの一覧
2. **小サンプル設計書**: 検証用サンプル取得の設計（実取得はしない）
3. **依存関係図**: Lambda① → S3/raw → Lambda② → S3/stage → Glue → S3/processed
4. **リスク一覧**: データ欠損・形式不一致・スキーマ変動リスク

## 使用方法
```
# Orchestratorからの呼び出し例
[data-intake]: データソース `s3://aws-data-platform-20250607/raw/` のメタデータを整理し、
              サンプル設計書を生成してください。
```

## 禁止事項
- 実データの取得（`aws s3 cp`, `kaggle datasets download` 等の実行）
- S3への書き込み
- Lambda/Glue Jobの起動

## 出力フォーマット
```markdown
## データ所在マップ
| パス | 形式 | 推定サイズ | 更新頻度 |
|------|------|----------|---------|
| s3://.../raw/ | .log / CSV | 未計測 | バッチ |

## 小サンプル設計
- 対象: /raw/ 配下の先頭ファイル1件
- 取得方法: `aws s3 cp s3://.../<file> /tmp/sample.log` （設計のみ、実行禁止）
- サンプルサイズ目安: 先頭100行

## リスク一覧
- [ ] ログ形式のバリエーションによるパース失敗
- [ ] Parquet変換時のスキーマ不一致
- [ ] Kaggle API認証切れ
```

## 関連スキル
- `schema-contract`: スキーマ定義の詳細化
- `data-governance-guard`: PIIリスク評価
