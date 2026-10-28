{{ config(order_by='state_code') }}

with

transactions as (
    select * from {{ ref('stg_transactions') }}
),

states as (
    select * from {{ ref('stg_states') }}
),

by_state as (
    select
        state_code,
        count() as transactions_count,
        sum(is_fraud) as fraud_count,
        {{ rate_pct('sum(is_fraud)', 'count()') }} as fraud_rate,
        uniqExact(customer_id) as unique_customers,
        uniqExactIf(customer_id, is_fraud = 1) as fraud_victims,
        uniqExact(merchant_name) as unique_merchants,
        uniqExactIf(merchant_name, is_fraud = 1) as merchants_with_fraud,
        round(sum(amount), 2) as total_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        round(avgIfOrNull(amount, is_fraud = 1), 2) as avg_fraud_amount
    from transactions
    group by state_code
)

select
    by_state.state_code,
    states.state_name,
    states.region,
    states.division,
    by_state.transactions_count,
    by_state.fraud_count,
    by_state.fraud_rate,
    by_state.unique_customers,
    by_state.fraud_victims,
    by_state.unique_merchants,
    by_state.merchants_with_fraud,
    by_state.total_amount,
    by_state.fraud_amount,
    {{ rate_pct('by_state.fraud_amount', 'by_state.total_amount') }} as fraud_amount_share_pct,
    by_state.avg_fraud_amount,
    toUInt32(rank() over (order by by_state.fraud_rate desc)) as fraud_rate_rank
from by_state
left join states on by_state.state_code = states.state_code
