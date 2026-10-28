{#
    ClickHouse-реализации макросов dbt_date (в пакете есть только default__/snowflake__/bigquery__ и т.д.).
    Подключаются через dispatch в dbt_project.yml.
#}

{% macro clickhouse__day_of_week(date, isoweek) -%}
    {%- if isoweek -%}
        toDayOfWeek({{ date }}, 0)  {#- понедельник = 1 ... воскресенье = 7 -#}
    {%- else -%}
        toDayOfWeek({{ date }}, 3)  {#- воскресенье = 1 ... суббота = 7 -#}
    {%- endif -%}
{%- endmacro %}

{% macro clickhouse__day_name(date, short, language) -%}
    {%- if short -%}
        substring(dateName('weekday', {{ date }}), 1, 3)
    {%- else -%}
        dateName('weekday', {{ date }})
    {%- endif -%}
{%- endmacro %}
