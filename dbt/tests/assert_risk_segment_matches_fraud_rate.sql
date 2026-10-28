-- Сегмент риска клиента согласован с его fraud_rate и порогами из vars.
select
    customer_id,
    fraud_rate,
    risk_segment
from {{ ref('mart_customer_risk_profile') }}
where
    (risk_segment = 'HIGH' and fraud_rate < {{ var('customer_high_risk_fraud_rate') }})
    or (risk_segment = 'MEDIUM' and (
        fraud_rate < {{ var('customer_medium_risk_fraud_rate') }}
        or fraud_rate >= {{ var('customer_high_risk_fraud_rate') }}
    ))
    or (risk_segment = 'LOW' and fraud_rate >= {{ var('customer_medium_risk_fraud_rate') }})
