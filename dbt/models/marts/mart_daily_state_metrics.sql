{{ config(order_by='(transaction_date, state_code)') }}

with

transactions as (
    select * from {{ ref('stg_transactions') }}
),

states as (
    select * from {{ ref('stg_states') }}
),

daily as (
    select
        transaction_date,
        state_code,
        count() as transactions_count,
        round(sum(amount), 2) as total_amount,
        round(avg(amount), 2) as avg_amount,
        round(quantile(0.5)(amount), 2) as median_amount,  -- noqa: LT01
        round(quantile(0.95)(amount), 2) as p95_amount,  -- noqa: LT01
        round(max(amount), 2) as max_amount,
        sum(is_large_transaction) as large_transactions_count,
        {{ rate_pct('sum(is_large_transaction)', 'count()') }} as large_transactions_share_pct,
        uniqExact(customer_id) as unique_customers,
        sum(is_fraud) as fraud_count,
        {{ rate_pct('sum(is_fraud)', 'count()') }} as fraud_rate
    from transactions
    group by transaction_date, state_code
)

select
    daily.transaction_date,
    daily.state_code,
    states.state_name,
    states.region,
    {{ dbt_date.day_name('daily.transaction_date', short=false) }} as day_name,
    daily.transactions_count,
    daily.total_amount,
    daily.avg_amount,
    daily.median_amount,
    daily.p95_amount,
    daily.max_amount,
    daily.large_transactions_count,
    daily.large_transactions_share_pct,
    daily.unique_customers,
    daily.fraud_count,
    daily.fraud_rate
from daily
left join states on daily.state_code = states.state_code
