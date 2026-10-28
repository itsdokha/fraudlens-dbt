-- fraud_rate во всех витринах должен лежать в [0, 100].
{% set marts = [
    'mart_daily_state_metrics', 'mart_fraud_by_category', 'mart_fraud_by_state',
    'mart_customer_risk_profile', 'mart_hourly_fraud_pattern', 'mart_merchant_analytics'
] %}

{% for mart in marts %}
    select
        '{{ mart }}' as mart,
        fraud_rate
    from {{ ref(mart) }}
    where fraud_rate < 0 or fraud_rate > 100
    {% if not loop.last %}union all{% endif %}
{% endfor %}
