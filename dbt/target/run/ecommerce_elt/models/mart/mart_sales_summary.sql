
  
    

    create or replace table `ecommerce-elt-pipeline`.`ecommerce_raw_mart`.`mart_sales_summary`
      
    
    

    
    OPTIONS()
    as (
      with orders_enriched as (
    select * from `ecommerce-elt-pipeline`.`ecommerce_raw_intermediate`.`int_orders_enriched`
),

order_items as (
    select * from `ecommerce-elt-pipeline`.`ecommerce_raw`.`order_items`
),

payments as (
    select * from `ecommerce-elt-pipeline`.`ecommerce_raw`.`order_payments`
),

payment_summary as (
    select
        order_id,
        sum(payment_value) as total_payment_value,
        count(distinct payment_type) as payment_types_used
    from payments
    group by order_id
),

item_summary as (
    select
        order_id,
        count(order_item_id) as total_items,
        sum(price) as total_price,
        sum(freight_value) as total_freight
    from order_items
    group by order_id
),

final as (
    select
        o.order_id,
        o.customer_id,
        o.customer_unique_id,
        o.customer_city,
        o.customer_state,
        o.order_status,
        o.order_purchase_timestamp,
        o.delivery_days,
        o.days_early_or_late,
        i.total_items,
        i.total_price,
        i.total_freight,
        p.total_payment_value,
        p.payment_types_used,
        date_trunc(o.order_purchase_timestamp, month) as order_month
    from orders_enriched o
    left join item_summary i on o.order_id = i.order_id
    left join payment_summary p on o.order_id = p.order_id
)

select * from final
    );
  