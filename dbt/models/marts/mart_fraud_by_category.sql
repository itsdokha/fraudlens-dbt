{{ config(order_by='category') }}

with

transactions as (
    select * from {{ ref('stg_transactions') }}
),

by_category as (
    select
        category,
        count() as transactions_count,
        sum(is_fraud) as fraud_count,
        countIf(is_fraud = 0) as legit_count,
        {{ rate_pct('sum(is_fraud)', 'count()') }} as fraud_rate,
        round(sum(amount), 2) as total_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        round(avg(amount), 2) as avg_amount,
        round(avgIfOrNull(amount, is_fraud = 1), 2) as avg_fraud_amount,
        round(avgIf(amount, is_fraud = 0), 2) as avg_legit_amount
    from transactions
    group by category
)

select
    category,
    transactions_count,
    fraud_count,
    legit_count,
    fraud_rate,
    total_amount,
    fraud_amount,
    {{ rate_pct('fraud_amount', 'total_amount') }} as fraud_amount_share_pct,
    {{ rate_pct('fraud_count', 'sum(fraud_count) over ()') }} as share_of_all_fraud_pct,
    avg_amount,
    avg_fraud_amount,
    avg_legit_amount,
    toUInt32(rank() over (order by fraud_rate desc)) as fraud_rate_rank
from by_category
