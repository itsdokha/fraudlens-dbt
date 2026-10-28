{#
    В ClickHouse schema = database. Кастомная схема (+schema) используется как есть,
    без префикса target.schema: staging-модели -> БД `staging`, витрины -> БД `marts`.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
