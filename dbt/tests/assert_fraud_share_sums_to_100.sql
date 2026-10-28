-- Доли категорий во всём фроде в сумме дают 100% (допуск на округление 0.01 п.п.).
select sum(share_of_all_fraud_pct) as total_share
from {{ ref('mart_fraud_by_category') }}
having abs(total_share - 100) > 0.01
