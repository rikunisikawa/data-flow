{% macro _build_group_by_list(columns) %}
  {%- for column in columns -%}
    {{ column }}{% if not loop.last %}, {% endif %}
  {%- endfor -%}
{% endmacro %}

{% test unique_combination_of_columns(model, combination) %}
with duplicates as (
    select
        {{ _build_group_by_list(combination) }},
        count(*) as duplicate_count
    from {{ model }}
    group by {{ _build_group_by_list(combination) }}
    having count(*) > 1
)

select * from duplicates
{% endtest %}
