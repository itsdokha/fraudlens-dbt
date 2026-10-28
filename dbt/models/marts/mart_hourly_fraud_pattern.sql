{{ config(order_by='(day_of_week, transaction_hour)') }}

with

transactions as (
    select * from {{ ref('stg_transactions') }}
),

overall as (
    select avg(is_fraud) * 100 as overall_fraud_rate
    from transactions
),

by_window as (
    select
        day_of_week,
        any(day_name) as day_name,
        transaction_hour,
        count() as transactions_count,
        sum(is_fraud) as fraud_count,
        {{ rate_pct('sum(is_fraud)', 'count()') }} as fraud_rate,
        round(avg(amount), 2) as avg_amount,
        round(avgIfOrNull(amount, is_fraud = 1), 2) as avg_fraud_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount
    from transactions
    group by day_of_week, transaction_hour
)

select
    by_window.day_of_week,
    by_window.day_name,
    toUInt8(by_window.day_of_week >= 6) as is_weekend,
    by_window.transaction_hour,
    multiIf(
        by_window.transaction_hour < 6, 'night',
        by_window.transaction_hour < 12, 'morning',
        by_window.transaction_hour < 18, 'afternoon',
        'evening'
    ) as day_part,
    by_window.transactions_count,
    by_window.fraud_count,
    by_window.fraud_rate,
    round(by_window.fraud_rate / overall.overall_fraud_rate, 2) as fraud_rate_lift,
    toUInt8(
        by_window.fraud_rate >= {{ var('high_risk_window_lift') }} * overall.overall_fraud_rate
    ) as is_high_risk_window,
    by_window.avg_amount,
    by_window.avg_fraud_amount,
    by_window.fraud_amount
from by_window
cross join overall
