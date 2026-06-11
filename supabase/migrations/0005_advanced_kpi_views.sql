create or replace view public.vw_product_daily_sales as
select
  date_trunc('day', o.created_at)::date as order_date,
  oi.product_id,
  oi.product_name,
  sum(oi.quantity) as quantity_sold,
  sum(oi.subtotal) as gross_revenue,
  count(distinct oi.order_id) as orders_count
from public.order_items oi
join public.orders o on o.id = oi.order_id
where o.order_status <> 'cancelled'
group by 1, 2, 3
order by order_date desc, gross_revenue desc;

create or replace view public.vw_hour_weekday_heatmap as
select
  extract(isodow from created_at)::integer as weekday_number,
  case extract(isodow from created_at)::integer
    when 1 then 'Segunda'
    when 2 then 'Terca'
    when 3 then 'Quarta'
    when 4 then 'Quinta'
    when 5 then 'Sexta'
    when 6 then 'Sabado'
    when 7 then 'Domingo'
  end as weekday_name,
  extract(hour from created_at)::integer as order_hour,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue
from public.orders
group by 1, 2, 3
order by 1, 3;

create or replace view public.vw_basket_summary as
select
  o.id as order_id,
  o.order_number,
  o.created_at,
  o.total_amount,
  count(oi.id) as distinct_products,
  sum(oi.quantity) as total_items,
  case
    when sum(oi.quantity) >= 4 then 'Pedido grande'
    when sum(oi.quantity) >= 2 then 'Pedido medio'
    else 'Pedido individual'
  end as basket_size_label
from public.orders o
join public.order_items oi on oi.order_id = o.id
where o.order_status <> 'cancelled'
group by o.id, o.order_number, o.created_at, o.total_amount
order by o.created_at desc;

create or replace view public.vw_product_pair_sales as
select
  least(i1.product_name, i2.product_name) as product_a,
  greatest(i1.product_name, i2.product_name) as product_b,
  count(distinct i1.order_id) as orders_together,
  coalesce(sum(o.total_amount), 0) as related_revenue
from public.order_items i1
join public.order_items i2
  on i2.order_id = i1.order_id
  and i2.product_id <> i1.product_id
join public.orders o on o.id = i1.order_id
where o.order_status <> 'cancelled'
group by 1, 2
order by orders_together desc, related_revenue desc;

create or replace view public.vw_customer_lifecycle as
with customer_metrics as (
  select
    c.id as customer_id,
    c.name as customer_name,
    c.phone as customer_phone,
    count(o.id) filter (where o.order_status <> 'cancelled') as total_orders,
    coalesce(sum(o.total_amount) filter (where o.order_status <> 'cancelled'), 0) as gross_revenue,
    max(o.created_at) filter (where o.order_status <> 'cancelled') as last_order_at
  from public.customers c
  left join public.orders o on o.customer_id = c.id
  group by c.id, c.name, c.phone
)
select
  customer_id,
  customer_name,
  customer_phone,
  total_orders,
  gross_revenue,
  last_order_at,
  case
    when last_order_at is null then null
    else current_date - last_order_at::date
  end as days_since_last_order,
  case
    when total_orders = 0 then 'Sem compra'
    when current_date - last_order_at::date <= 15 then 'Ativo'
    when current_date - last_order_at::date <= 30 then 'Aquecido'
    when current_date - last_order_at::date <= 60 then 'Risco de sumir'
    else 'Inativo'
  end as lifecycle_status
from customer_metrics
order by gross_revenue desc, total_orders desc;

create or replace view public.vw_daily_operational_summary as
select
  current_date as reference_date,
  count(*) filter (
    where order_status <> 'cancelled'
      and created_at::date = current_date
  ) as orders_today,
  coalesce(sum(total_amount) filter (
    where order_status <> 'cancelled'
      and created_at::date = current_date
  ), 0) as revenue_today,
  coalesce(avg(total_amount) filter (
    where order_status <> 'cancelled'
      and created_at::date = current_date
  ), 0) as average_ticket_today,
  count(*) filter (
    where order_status in ('new', 'paid', 'in_preparation')
      and created_at::date = current_date
  ) as open_orders_today,
  count(distinct customer_id) filter (
    where order_status <> 'cancelled'
      and created_at::date = current_date
  ) as unique_customers_today
from public.orders;
