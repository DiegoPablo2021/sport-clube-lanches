create or replace view public.vw_orders_base as
select
  o.id,
  o.order_number,
  o.created_at,
  o.order_type,
  o.neighborhood,
  o.payment_method,
  o.change_for,
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

create or replace view public.vw_weekday_sales as
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
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
order by 1;

create or replace view public.vw_period_sales as
select
  'day' as period_type,
  date_trunc('day', created_at)::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'week' as period_type,
  date_trunc('week', created_at)::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'month' as period_type,
  date_trunc('month', created_at)::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'quarter' as period_type,
  date_trunc('quarter', created_at)::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'semester' as period_type,
  make_date(
    extract(year from created_at)::integer,
    case when extract(month from created_at)::integer <= 6 then 1 else 7 end,
    1
  ) as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'year' as period_type,
  date_trunc('year', created_at)::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2;

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

create or replace view public.vw_customer_promotion_candidates as
select
  c.id as customer_id,
  c.name as customer_name,
  c.phone as customer_phone,
  count(o.id) filter (
    where o.order_status <> 'cancelled'
      and o.created_at >= now() - interval '30 days'
  ) as orders_last_30_days,
  coalesce(sum(o.total_amount) filter (
    where o.order_status <> 'cancelled'
      and o.created_at >= now() - interval '30 days'
  ), 0) as revenue_last_30_days,
  max(o.created_at) filter (where o.order_status <> 'cancelled') as last_order_at,
  case
    when count(o.id) filter (
      where o.order_status <> 'cancelled'
        and o.created_at >= now() - interval '30 days'
    ) >= 5 then 'Promocao fidelidade: brinde ou cupom'
    when coalesce(sum(o.total_amount) filter (
      where o.order_status <> 'cancelled'
        and o.created_at >= now() - interval '30 days'
    ), 0) >= 150 then 'Promocao por valor comprado'
    else 'Acompanhar'
  end as suggested_action
from public.customers c
left join public.orders o on o.customer_id = c.id
group by c.id, c.name, c.phone
order by orders_last_30_days desc, revenue_last_30_days desc;

create or replace view public.vw_customer_favorite_products as
select
  customer_id,
  customer_name,
  customer_phone,
  product_name,
  quantity_sold,
  gross_revenue,
  product_rank
from (
  select
    c.id as customer_id,
    c.name as customer_name,
    c.phone as customer_phone,
    oi.product_name,
    sum(oi.quantity) as quantity_sold,
    sum(oi.subtotal) as gross_revenue,
    row_number() over (
      partition by c.id
      order by sum(oi.quantity) desc, sum(oi.subtotal) desc
    ) as product_rank
  from public.customers c
  join public.orders o on o.customer_id = c.id
  join public.order_items oi on oi.order_id = o.id
  where o.order_status <> 'cancelled'
  group by c.id, c.name, c.phone, oi.product_name
) ranked
where product_rank <= 3
order by customer_name, product_rank;

create or replace view public.vw_kpi_snapshot as
select
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  count(*) filter (
    where order_status <> 'cancelled'
      and created_at::date = current_date
  ) as orders_today,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(sum(total_amount) filter (
    where order_status <> 'cancelled'
      and created_at::date = current_date
  ), 0) as revenue_today,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket,
  count(*) filter (where order_status = 'cancelled') as cancelled_orders,
  count(distinct customer_id) filter (where order_status <> 'cancelled') as unique_customers
from public.orders;

create or replace view public.vw_order_status_summary as
select
  order_status,
  count(*) as total_orders,
  coalesce(sum(total_amount), 0) as total_amount
from public.orders
group by order_status
order by total_orders desc;
