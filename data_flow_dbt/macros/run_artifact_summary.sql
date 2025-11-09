{% macro summarize_run_artifacts(results) %}
    {% set success = [] %}
    {% set failures = [] %}

    {% for result in results %}
        {% if result.status == 'success' %}
            {% do success.append(result.node.name) %}
        {% else %}
            {% do failures.append(result.node.name ~ ' (' ~ result.status ~ ')') %}
        {% endif %}
    {% endfor %}

    {% set summary %}{
        "successful_models": {{ success | tojson }},
        "failed_models": {{ failures | tojson }},
        "generated_at": "{{ run_started_at }}"
    }{% endset %}

    {{ log('dbt artifact summary: ' ~ summary, info=True) }}
    {% do return(summary) %}
{% endmacro %}

{% macro artifact_paths() %}
    {% set target_path = target.path %}
    {% set manifest_path = target_path ~ '/manifest.json' %}
    {% set run_results_path = target_path ~ '/run_results.json' %}
    {% set catalog_path = target_path ~ '/catalog.json' %}

    {% set payload %}{
        "manifest": "{{ manifest_path }}",
        "run_results": "{{ run_results_path }}",
        "catalog": "{{ catalog_path }}"
    }{% endset %}

    {% do return(payload) %}
{% endmacro %}
