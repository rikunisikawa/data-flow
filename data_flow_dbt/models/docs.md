{% docs stg_mhealth_activities_doc %}
`stg_mhealth_activities` は Glue カタログの外部テーブルを正規化し、ユーザー ID を `$path` から抽出するビューです。データコントラクトを有効化し、ダウンストリームの中間モデルに対して安定したスキーマを提供します。
{% enddocs %}

{% docs int_activity_features_doc %}
`int_activity_features` はエフェメラルモデルとして 3 軸加速度の平均値を計算し、繰り返し利用されるロジックを集約します。
{% enddocs %}

{% docs cleaned_activities_doc %}
`cleaned_activities` テーブルは `stg_mhealth_activities` ビューを基に、各センサーの 3 軸加速度の平均値を算出した中間テーブルです。`activity_label` が 0 の無効データを除外し、ユーザー ID を正規化した上で特徴量生成の前処理を担います。
{% enddocs %}

{% docs featured_activities_doc %}
`featured_activities` は `cleaned_activities` を `user_id × activity_label` で集約し、平均・標準偏差・最小・最大の代表統計量を算出します。`activity_labels` シードテーブルと結合することでビジネスで利用する説明文を付与します。
{% enddocs %}

{% docs fact_activity_metrics_doc %}
`fact_activity_metrics` は `featured_activities` の増分ロード版であり、CI や本番バッチにてマージ戦略で更新されます。`loaded_at` 列により差分抽出を行い、Slim CI などでの効率的な再実行を可能にします。
{% enddocs %}
