# Tips リファレンス

## Mermaid
- subgraph 名やノードラベルに括弧や記号を避ける。
- 改行は `<br/>` に置き換える。
- ラベルはできるだけ英数字に寄せる。

## Notebooks (.ipynb)
- ファイルが単一の JSON オブジェクトであることを確認する。
- `nbformat`, `nbformat_minor`, `metadata.kernelspec`, `metadata.language_info`, `cells` を含める。
- 破損が疑われる場合は最小構成の Notebook を再生成する。

## ツール Tips
- Spec Kit のセットアップは `ai-doc/tips/install-spec-kit.md` を参照する。
- Gemini CLI の利用とセキュリティは `ai-doc/tips/gemini-cli-tips.md` を参照する。
