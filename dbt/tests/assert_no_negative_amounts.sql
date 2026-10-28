-- Суммы транзакций в staging должны быть строго положительными.
select
    transaction_id,
    amount
from {{ ref('stg_transactions') }}
where amount <= 0
