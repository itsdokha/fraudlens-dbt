{{ config(order_by='customer_id') }}

with

transactions as (
    select * from {{ ref('stg_transactions') }}
),

by_customer as (
    select
        customer_id,
        any(customer_first_name) as first_name,
        any(customer_last_name) as last_name,
        any(customer_gender) as gender,
        any(customer_city) as city,
        any(state_code) as state_code,
        any(customer_job) as job,
        min(transaction_at) as first_transaction_at,
        max(transaction_at) as last_transaction_at,
        uniqExact(transaction_date) as active_days,
        count() as transactions_count,
        uniqExact(merchant_name) as unique_merchants,
        uniqExact(category) as unique_categories,
        arrayElement(topK(1)(category), 1) as favorite_category,  -- noqa: LT01
        round(sum(amount), 2) as total_amount,
        round(avg(amount), 2) as avg_amount,
        round(max(amount), 2) as max_amount,
        sum(is_fraud) as fraud_count,
        {{ rate_pct('sum(is_fraud)', 'count()') }} as fraud_rate,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        maxIfOrNull(transaction_at, is_fraud = 1) as last_fraud_at
    from transactions
    group by customer_id
)

select
    *,
    multiIf(
        fraud_rate >= {{ var('customer_high_risk_fraud_rate') }}, 'HIGH',
        fraud_rate >= {{ var('customer_medium_risk_fraud_rate') }}, 'MEDIUM',
        'LOW'
    ) as risk_segment
from by_customer
