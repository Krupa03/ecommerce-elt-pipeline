with order_details as (
    select * from {{ ref('int_order_details') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select
        o.customer_id,
        count(distinct o.order_id) as total_orders,
        sum(o.total_payment_value) as lifetime_value,
        avg(o.total_payment_value) as avg_order_value,
        min(o.order_purchase_timestamp) as first_order_date,
        max(o.order_purchase_timestamp) as last_order_date,
        timestamp_diff(
            max(o.order_purchase_timestamp),
            min(o.order_purchase_timestamp),
            day
        ) as customer_lifetime_days,
        avg(o.delivery_days) as avg_delivery_days,
        countif(o.order_status = 'delivered') as delivered_orders,
        countif(o.order_status = 'canceled') as canceled_orders
    from order_details o
    group by o.customer_id
),

final as (
    select
        c.customer_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        co.total_orders,
        co.lifetime_value,
        co.avg_order_value,
        co.first_order_date,
        co.last_order_date,
        co.customer_lifetime_days,
        co.avg_delivery_days,
        co.delivered_orders,
        co.canceled_orders,
        case
            when co.lifetime_value >= 1000 then 'high'
            when co.lifetime_value >= 300 then 'medium'
            else 'low'
        end as customer_segment
    from customers c
    left join customer_orders co on c.customer_id = co.customer_id
)

select * from final