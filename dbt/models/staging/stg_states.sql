select
    upper(trim(state_code)) as state_code,
    trim(state_name) as state_name,
    trim(region) as region,
    trim(division) as division
from {{ ref('states') }}
