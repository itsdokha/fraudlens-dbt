{#
    Сегментирует сумму транзакции по фиксированным порогам (USD).
    Пример: {{ amount_bucket('amount') }} -> 'small'
#}
{% macro amount_bucket(column) -%}
    multiIf(
        {{ column }} < 10, 'micro',
        {{ column }} < 50, 'small',
        {{ column }} < 200, 'medium',
        {{ column }} < {{ var('large_amount_threshold') }}, 'large',
        'very_large'
    )
{%- endmacro %}
