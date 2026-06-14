-- Corrige analytics para o fuso local da lanchonete e padroniza bairros equivalentes.
-- Supabase grava created_at em UTC; o painel precisa enxergar dia/hora de Natal/Sao Paulo.

-- Normaliza variacoes digitadas pelos clientes sem alterar o texto original salvo no pedido.
create or replace function public.normalize_neighborhood_label(raw_neighborhood text)
returns text
language sql
immutable
as $$
  with normalized as (
    select
      nullif(trim(raw_neighborhood), '') as original_value,
      regexp_replace(lower(coalesce(raw_neighborhood, '')), '[^a-z0-9]+', ' ', 'g') as clean_value
  )
  select
    case
      when original_value is null then 'Retirada'
      when clean_value ~ '(^| )sport club(e)? (3|iii|4|iv)( |$)' then 'Sport Clube 3/4'
      when clean_value ~ '(^| )sport club(e)? (1|i)( |$)' then 'Sport Clube 1'
      when clean_value ~ '(^| )sport club(e)? (2|ii)( |$)' then 'Sport Clube 2'
      when clean_value ~ '(^| )sport club(e)? (5|v)( |$)' then 'Sport Clube 5'
      when clean_value ~ '(^| )sport club(e)? (6|vi)( |$)' then 'Sport Clube 6'
      when clean_value ~ '(^| )sport club(e)? natureza( |$)' then 'Sport Clube Natureza'
      else initcap(original_value)
    end
  from normalized;
$$;

grant execute on function public.normalize_neighborhood_label(text) to anon, authenticated;

-- Vendas por dia usando a data local da operacao.
create or replace view public.vw_daily_sales as
select
  date_trunc('day', timezone('America/Sao_Paulo', created_at))::date as order_date,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  count(*) filter (where order_status = 'cancelled') as cancelled_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1
order by 1 desc;

-- Dia da semana no fuso local para evitar pedidos da noite caindo no dia errado.
create or replace view public.vw_weekday_sales as
select
  extract(isodow from timezone('America/Sao_Paulo', created_at))::integer as weekday_number,
  case extract(isodow from timezone('America/Sao_Paulo', created_at))::integer
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

-- Vendas agregadas por periodo, sempre considerando a virada do dia no horario local.
create or replace view public.vw_period_sales as
select
  'day' as period_type,
  date_trunc('day', timezone('America/Sao_Paulo', created_at))::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'week' as period_type,
  date_trunc('week', timezone('America/Sao_Paulo', created_at))::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'month' as period_type,
  date_trunc('month', timezone('America/Sao_Paulo', created_at))::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'quarter' as period_type,
  date_trunc('quarter', timezone('America/Sao_Paulo', created_at))::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2
union all
select
  'semester' as period_type,
  make_date(
    extract(year from timezone('America/Sao_Paulo', created_at))::integer,
    case when extract(month from timezone('America/Sao_Paulo', created_at))::integer <= 6 then 1 else 7 end,
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
  date_trunc('year', timezone('America/Sao_Paulo', created_at))::date as period_start,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket
from public.orders
group by 1, 2;

-- Bairros/localidades com variacoes equivalentes agrupadas no mesmo nome.
create or replace view public.vw_neighborhood_sales as
select
  public.normalize_neighborhood_label(neighborhood) as neighborhood,
  count(*) as total_orders,
  coalesce(sum(total_amount), 0) as gross_revenue,
  coalesce(avg(total_amount), 0) as average_ticket
from public.orders
where order_status <> 'cancelled'
group by 1
order by total_orders desc;

-- Horario de pico local. Isso evita aparecer 01h quando o pedido foi feito por volta de 22h.
create or replace view public.vw_hourly_sales as
select
  extract(hour from timezone('America/Sao_Paulo', created_at))::integer as order_hour,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue
from public.orders
group by 1
order by 1;

-- Snapshot geral para cards de KPI com "hoje" no fuso da lanchonete.
create or replace view public.vw_kpi_snapshot as
select
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  count(*) filter (
    where order_status <> 'cancelled'
      and timezone('America/Sao_Paulo', created_at)::date = timezone('America/Sao_Paulo', now())::date
  ) as orders_today,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue,
  coalesce(sum(total_amount) filter (
    where order_status <> 'cancelled'
      and timezone('America/Sao_Paulo', created_at)::date = timezone('America/Sao_Paulo', now())::date
  ), 0) as revenue_today,
  coalesce(avg(total_amount) filter (where order_status <> 'cancelled'), 0) as average_ticket,
  count(*) filter (where order_status = 'cancelled') as cancelled_orders,
  count(distinct customer_id) filter (where order_status <> 'cancelled') as unique_customers
from public.orders;

-- Vendas diarias por produto com dia local.
create or replace view public.vw_product_daily_sales as
select
  date_trunc('day', timezone('America/Sao_Paulo', o.created_at))::date as order_date,
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

-- Mapa de calor local: dia da semana x hora.
create or replace view public.vw_hour_weekday_heatmap as
select
  extract(isodow from timezone('America/Sao_Paulo', created_at))::integer as weekday_number,
  case extract(isodow from timezone('America/Sao_Paulo', created_at))::integer
    when 1 then 'Segunda'
    when 2 then 'Terca'
    when 3 then 'Quarta'
    when 4 then 'Quinta'
    when 5 then 'Sexta'
    when 6 then 'Sabado'
    when 7 then 'Domingo'
  end as weekday_name,
  extract(hour from timezone('America/Sao_Paulo', created_at))::integer as order_hour,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue
from public.orders
group by 1, 2, 3
order by 1, 3;

-- Resumo operacional do dia atual no horario local.
create or replace view public.vw_daily_operational_summary as
select
  timezone('America/Sao_Paulo', now())::date as reference_date,
  count(*) filter (
    where order_status <> 'cancelled'
      and timezone('America/Sao_Paulo', created_at)::date = timezone('America/Sao_Paulo', now())::date
  ) as orders_today,
  coalesce(sum(total_amount) filter (
    where order_status <> 'cancelled'
      and timezone('America/Sao_Paulo', created_at)::date = timezone('America/Sao_Paulo', now())::date
  ), 0) as revenue_today,
  coalesce(avg(total_amount) filter (
    where order_status <> 'cancelled'
      and timezone('America/Sao_Paulo', created_at)::date = timezone('America/Sao_Paulo', now())::date
  ), 0) as average_ticket_today,
  count(*) filter (
    where order_status in ('new', 'paid', 'in_preparation')
      and timezone('America/Sao_Paulo', created_at)::date = timezone('America/Sao_Paulo', now())::date
  ) as open_orders_today,
  count(distinct customer_id) filter (
    where order_status <> 'cancelled'
      and timezone('America/Sao_Paulo', created_at)::date = timezone('America/Sao_Paulo', now())::date
  ) as unique_customers_today
from public.orders;
