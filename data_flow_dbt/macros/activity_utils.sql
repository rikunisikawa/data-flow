{% macro three_axis_average(x, y, z) %}
    ({{ x }} + {{ y }} + {{ z }}) / 3
{% endmacro %}

{% macro activity_coalesce_user_id(partition_value, path_partition, path_filename) %}
    coalesce(
        {{ partition_value }},
        regexp_extract({{ path_partition }}, 'subject_id=(\\d+)', 1),
        regexp_extract({{ path_filename }}, 'mHealth_subject(\\d+)', 1)
    )
{% endmacro %}
