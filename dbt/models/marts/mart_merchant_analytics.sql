{{ config(order_by='merchant_name') }}

with

transactions as (
    select * from {{ ref('stg_transactions') }}
),

overall as (
    select avg(is_fraud) * 100 as overall_fraud_rate
    from transactions
),

by_merchant as (
    select
        merchant_name,
        arrayElement(topK(1)(category), 1) as primary_category,  -- noqa: LT01
        uniqExact(category) as categories_count,
        min(transaction_at) as first_transaction_at,
        max(transaction_at) as last_transaction_at,
        count() as transactions_count,
        uniqExact(customer_id) as unique_customers,
        uniqExact(state_code) as states_count,
        round(sum(amount), 2) as turnover,
        round(avg(amount), 2) as avg_amount,
        round(quantile(0.95)(amount), 2) as p95_amount,  -- noqa: LT01
        sum(is_fraud) as fraud_count,
        {{ rate_pct('sum(is_fraud)', 'count()') }} as fraud_rate,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        round(avg(customer_merchant_distance_km), 2) as avg_distance_km
    from transactions
    group by merchant_name
)

select
    by_merchant.*,
    {{ rate_pct('by_merchant.fraud_amount', 'by_merchant.turnover') }} as fraud_amount_share_pct,
    round(by_merchant.fraud_rate / overall.overall_fraud_rate, 2) as fraud_rate_lift,
    toUInt8(
        by_merchant.fraud_rate >= {{ var('suspicious_merchant_rate_multiplier') }} * overall.overall_fraud_rate
    ) as is_suspicious,
    toUInt32(rank() over (order by by_merchant.turnover desc)) as turnover_rank
from by_merchant
cross join overall
