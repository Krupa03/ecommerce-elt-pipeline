with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

enriched as (
    select
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        timestamp_diff(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp,
            day
        ) as delivery_days,
        timestamp_diff(
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date,
            day
        ) as days_early_or_late,
        c.customer_city,
        c.customer_state,
        c.customer_unique_id
    from orders o
    left join customers c
        on o.customer_id = c.customer_id
)

select * from enriched 
