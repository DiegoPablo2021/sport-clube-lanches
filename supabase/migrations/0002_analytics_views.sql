create or replace view public.vw_orders_base as
select
  o.id,
  o.order_number,
  o.created_at,
  o.order_type,
  o.neighborhood,
  o.payment_method,
  o.payment_status,
  o.order_status,
  o.subtotal_amount,
  o.total_amount,
  c.name as customer_name,
  c.phone as customer_phone
from public.orders o
left join public.customers c on c.id = o.customer_id;

create or replace view public.vw_daily_sales as
select
  date_trunc('day', created_at)::date as order_date,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  count(*) filter (where order_status = 'cancelled') as cancelled_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1
order by 1 desc;

create or replace view public.vw_product_sales as
select
  oi.product_id,
  oi.product_name,
  sum(oi.quantity) as quantity_sold,
  sum(oi.subtotal) as gross_revenue,
  count(distinct oi.order_id) as orders_count
from public.order_items oi
join public.orders o on o.id = oi.order_id
where o.order_status <> 'cancelled'
group by oi.product_id, oi.product_name
order by gross_revenue desc;

create or replace view public.vw_category_sales as
select
  c.id as category_id,
  c.name as category_name,
  sum(oi.quantity) as quantity_sold,
  sum(oi.subtotal) as gross_revenue,
  count(distinct oi.order_id) as orders_count
from public.order_items oi
join public.orders o on o.id = oi.order_id
left join public.products p on p.id = oi.product_id
left join public.categories c on c.id = p.category_id
where o.order_status <> 'cancelled'
group by c.id, c.name
order by gross_revenue desc;

create or replace view public.vw_payment_methods as
select
  payment_method,
  count(*) as total_orders,
  coalesce(sum(total_amount), 0) as gross_revenue
from public.orders
where order_status <> 'cancelled'
group by payment_method
order by total_orders desc;

create or replace view public.vw_neighborhood_sales as
select
  coalesce(nullif(trim(neighborhood), ''), 'Retirada') as neighborhood,
  count(*) as total_orders,
  coalesce(sum(total_amount), 0) as gross_revenue,
  coalesce(avg(total_amount), 0) as average_ticket
from public.orders
where order_status <> 'cancelled'
group by 1
order by total_orders desc;

create or replace view public.vw_order_type_sales as
select
  order_type,
  count(*) as total_orders,
  coalesce(sum(total_amount), 0) as gross_revenue,
  coalesce(avg(total_amount), 0) as average_ticket
from public.orders
where order_status <> 'cancelled'
group by order_type
order by total_orders desc;

create or replace view public.vw_hourly_sales as
select
  extract(hour from created_at)::integer as order_hour,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue
from public.orders
group by 1
order by 1;

create or replace view public.vw_customer_recurrence as
select
  c.id as customer_id,
  c.name as customer_name,
  c.phone as customer_phone,
  count(o.id) filter (where o.order_status <> 'cancelled') as total_orders,
  coalesce(sum(o.total_amount) filter (where o.order_status <> 'cancelled'), 0) as gross_revenue,
  min(o.created_at) as first_order_at,
  max(o.created_at) as last_order_at
from public.customers c
left join public.orders o on o.customer_id = c.id
group by c.id, c.name, c.phone
order by total_orders desc, gross_revenue desc;

create or replace view public.vw_order_status_summary as
select
  order_status,
  count(*) as total_orders,
  coalesce(sum(total_amount), 0) as total_amount
from public.orders
group by order_status
order by total_orders desc;
