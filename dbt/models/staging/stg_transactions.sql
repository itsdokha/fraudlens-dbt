with

source as (
    select * from {{ source('transactions_db', 'transactions') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'transaction_time', 'merch', 'amount', 'name_1', 'name_2',
            'street', 'merchant_lat', 'merchant_lon'
        ]) }} as transaction_id,

        -- время
        transaction_time as transaction_at,
        toDate(transaction_time) as transaction_date,
        toStartOfMonth(transaction_time) as transaction_month,
        toHour(transaction_time) as transaction_hour,
        {{ dbt_date.day_of_week('transaction_time', isoweek=true) }} as day_of_week,
        {{ dbt_date.day_name('transaction_time', short=false) }} as day_name,

        -- клиент
        {{ dbt_utils.generate_surrogate_key(['name_1', 'name_2', 'street', 'post_code']) }} as customer_id,
        trim(name_1) as customer_first_name,
        trim(name_2) as customer_last_name,
        upper(trim(gender)) as customer_gender,
        trim(street) as customer_street,
        trim(one_city) as customer_city,
        upper(trim(us_state)) as state_code,
        trim(post_code) as customer_post_code,
        population_city as city_population,
        trim(jobs) as customer_job,
        lat as customer_lat,
        lon as customer_lon,

        -- мерчант
        replaceRegexpOne(trim(merch), '^fraud_', '') as merchant_name,
        lower(trim(cat_id)) as category,
        merchant_lat,
        merchant_lon,
        round(geoDistance(lon, lat, merchant_lon, merchant_lat) / 1000, 2) as customer_merchant_distance_km,

        -- сумма
        round(amount, 2) as amount,
        {{ amount_bucket('amount') }} as amount_bucket,
        toUInt8(amount >= {{ var('large_amount_threshold') }}) as is_large_transaction,

        -- целевая метка
        toUInt8(target) as is_fraud
    from source
)

select * from renamed
