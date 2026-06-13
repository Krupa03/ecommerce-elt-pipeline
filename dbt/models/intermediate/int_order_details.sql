with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

payments as (
    select
        order_id,
        sum(payment_value) as total_payment_value,
        count(distinct payment_type) as payment_types_used
    from {{ source('ecommerce_raw', 'order_payments') }}
    group by order_id
),

final as (
    select
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        count(i.order_item_id) as total_items,
        sum(i.price) as total_price,
        sum(i.freight_value) as total_freight,
        p.total_payment_value,
        p.payment_types_used,
        timestamp_diff(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp,
            day
        ) as delivery_days
    from orders o
    left join order_items i on o.order_id = i.order_id
    left join payments p on o.order_id = p.order_id
    group by
        o.order_id, o.customer_id, o.order_status,
        o.order_purchase_timestamp, o.order_delivered_customer_date,
        o.order_estimated_delivery_date, p.total_payment_value,
        p.payment_types_used
)

select * from final