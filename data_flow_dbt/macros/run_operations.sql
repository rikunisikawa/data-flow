{% macro log_lineage(model_name) %}
    {% set node = graph.nodes.get('model.data_flow_dbt.' ~ model_name) %}
    {% if node is none %}
        {{ exceptions.raise_compiler_error('Model ' ~ model_name ~ ' not found in manifest') }}
    {% endif %}

    {% set parents = node.depends_on.nodes %}
    {% set children = graph.child_map.get(node.unique_id, []) %}

    {{ log('Lineage for ' ~ model_name, info=True) }}
    {{ log('Parents: ' ~ parents | tojson, info=True) }}
    {{ log('Children: ' ~ children | tojson, info=True) }}
{% endmacro %}
