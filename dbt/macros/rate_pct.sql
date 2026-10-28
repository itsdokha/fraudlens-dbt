{#
    Доля в процентах с защитой от деления на ноль, округлённая до `precision` знаков.
    Пример: {{ rate_pct('sum(is_fraud)', 'count()') }}
#}
{% macro rate_pct(numerator, denominator, precision=4) -%}
    round(if({{ denominator }} = 0, 0, 100.0 * {{ numerator }} / {{ denominator }}), {{ precision }})
{%- endmacro %}
