-- ============================================================
-- supabase/migrations/0001_core_schema.sql
-- ============================================================
-- Habilita geracao de UUIDs com gen_random_uuid().
create extension if not exists pgcrypto;

-- Categorias do cardapio, usadas para agrupar produtos na tela.
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  name text not null,
  description text,
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Produtos vendidos no cardapio, com preco, imagem e destaque.
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  category_id uuid not null references public.categories(id),
  name text not null,
  description text,
  price numeric(10, 2) not null check (price >= 0),
  image_url text,
  active boolean not null default true,
  highlight boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Clientes identificados principalmente pelo telefone informado no pedido.
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint customers_phone_key unique (phone)
);

-- Cabecalho do pedido: cliente, entrega/retirada, pagamento, valores e status.
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number bigint generated always as identity,
  customer_id uuid references public.customers(id),
  order_type text not null check (order_type in ('Entrega', 'Retirada')),
  address text,
  neighborhood text,
  delivery_fee_amount numeric(10, 2) not null default 0 check (delivery_fee_amount >= 0),
  delivery_fee_label text,
  payment_method text not null default 'Pix',
  payment_fee_amount numeric(10, 2) not null default 0 check (payment_fee_amount >= 0),
  change_for text,
  payment_status text not null default 'pending' check (payment_status in ('pending', 'paid', 'refunded', 'cancelled')),
  order_status text not null default 'new' check (order_status in ('new', 'awaiting_confirmation', 'awaiting_payment', 'paid', 'in_preparation', 'ready', 'out_for_delivery', 'finished', 'cancelled')),
  subtotal_amount numeric(10, 2) not null default 0 check (subtotal_amount >= 0),
  total_amount numeric(10, 2) not null default 0 check (total_amount >= 0),
  notes text,
  source text not null default 'web_menu',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_order_number_key unique (order_number)
);

-- Itens do pedido. A exclusao em cascata remove os itens quando o pedido e apagado.
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  subtotal numeric(10, 2) not null check (subtotal >= 0),
  created_at timestamptz not null default now()
);

-- Eventos de auditoria do pedido, como criacao e impressao da comanda.
create table if not exists public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Indices para acelerar buscas frequentes do cardapio, pedidos, itens e eventos.
create index if not exists products_category_id_idx on public.products(category_id);
create unique index if not exists categories_slug_key on public.categories(slug);
create unique index if not exists products_slug_key on public.products(slug);
create index if not exists products_active_idx on public.products(active) where active = true;
create index if not exists orders_customer_id_idx on public.orders(customer_id);
create index if not exists orders_created_at_idx on public.orders(created_at desc);
create index if not exists orders_status_created_at_idx on public.orders(order_status, created_at desc);
create index if not exists orders_neighborhood_idx on public.orders(neighborhood);
create index if not exists order_items_order_id_idx on public.order_items(order_id);
create index if not exists order_items_product_id_idx on public.order_items(product_id);
create index if not exists order_events_order_id_created_at_idx on public.order_events(order_id, created_at desc);

-- Funcao generica para atualizar updated_at automaticamente em alteracoes.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Triggers que aplicam updated_at nas tabelas editaveis.
drop trigger if exists categories_set_updated_at on public.categories;
create trigger categories_set_updated_at
before update on public.categories
for each row execute function public.set_updated_at();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();

drop trigger if exists customers_set_updated_at on public.customers;
create trigger customers_set_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

-- Ativa Row Level Security. Sem policies explicitas, tabelas sensiveis nao ficam abertas.
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_events enable row level security;

-- Permite leitura publica apenas das categorias ativas do cardapio.
drop policy if exists "Public can read active categories" on public.categories;
create policy "Public can read active categories"
on public.categories
for select
to anon, authenticated
using (active = true);

-- Permite leitura publica apenas dos produtos ativos do cardapio.
drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products"
on public.products
for select
to anon, authenticated
using (active = true);

-- ============================================================
-- supabase/migrations/0002_analytics_views.sql
-- ============================================================
-- Base consolidada de pedidos com dados do cliente. Serve como consulta operacional.
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
  o.delivery_fee_amount,
  o.payment_fee_amount,
  o.total_amount,
  c.name as customer_name,
  c.phone as customer_phone
from public.orders o
left join public.customers c on c.id = o.customer_id;

-- Vendas por dia: pedidos, cancelamentos, faturamento e ticket medio.
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

-- Vendas por dia da semana, util para descobrir os dias mais fortes.
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

-- Vendas agregadas por dia, semana, mes, trimestre, semestre e ano.
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

-- Produtos mais vendidos e faturamento por produto.
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

-- Faturamento por categoria do cardapio.
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

-- Distribuicao das formas de pagamento usadas nos pedidos.
create or replace view public.vw_payment_methods as
select
  payment_method,
  count(*) as total_orders,
  coalesce(sum(total_amount), 0) as gross_revenue
from public.orders
where order_status <> 'cancelled'
group by payment_method
order by total_orders desc;

-- Bairros/localidades com mais pedidos e maior faturamento.
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

-- Compara entrega e retirada.
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

-- Pedidos por hora do dia, usado para identificar horario de pico.
create or replace view public.vw_hourly_sales as
select
  extract(hour from created_at)::integer as order_hour,
  count(*) filter (where order_status <> 'cancelled') as total_orders,
  coalesce(sum(total_amount) filter (where order_status <> 'cancelled'), 0) as gross_revenue
from public.orders
group by 1
order by 1;

-- Ranking de clientes por quantidade de pedidos e faturamento.
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

-- Clientes candidatos a promocao com base em frequencia/valor nos ultimos 30 dias.
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

-- Produtos favoritos de cada cliente, limitado aos 3 mais comprados.
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

-- Snapshot geral para cards de KPI no dashboard.
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

-- Quantidade e valor por status do pedido.
create or replace view public.vw_order_status_summary as
select
  order_status,
  count(*) as total_orders,
  coalesce(sum(total_amount), 0) as total_amount
from public.orders
group by order_status
order by total_orders desc;

-- ============================================================
-- supabase/migrations/0003_public_order_rpc.sql
-- ============================================================
-- RPC publica chamada pelo cardapio Angular para registrar pedidos reais.
create or replace function public.create_public_order(payload jsonb)
returns table (
  order_id uuid,
  order_number bigint,
  total_amount numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_record public.customers%rowtype;
  order_record public.orders%rowtype;
  item jsonb;
  product_record public.products%rowtype;
  item_quantity integer;
  calculated_subtotal numeric(10, 2) := 0;
  delivery_fee_amount numeric(10, 2) := 0;
  payment_fee_amount numeric(10, 2) := 0;
begin
  -- Validacoes minimas para evitar pedido sem telefone ou sem itens.
  if payload is null then
    raise exception 'Payload is required';
  end if;

  delivery_fee_amount := greatest(coalesce(nullif(payload->>'delivery_fee_amount', '')::numeric, 0), 0);
  payment_fee_amount := greatest(coalesce(nullif(payload->>'payment_fee_amount', '')::numeric, 0), 0);

  if coalesce(payload->>'customer_phone', '') = '' then
    raise exception 'Customer phone is required';
  end if;

  if jsonb_typeof(payload->'items') <> 'array' or jsonb_array_length(payload->'items') = 0 then
    raise exception 'At least one item is required';
  end if;

  -- Cria ou atualiza o cliente usando telefone como chave unica.
  insert into public.customers (name, phone)
  values (
    coalesce(nullif(payload->>'customer_name', ''), 'A informar'),
    payload->>'customer_phone'
  )
  on conflict (phone)
  do update set
    name = excluded.name,
    updated_at = now()
  returning * into customer_record;

  -- Cria o cabecalho do pedido. Os valores entram zerados e sao calculados abaixo.
  insert into public.orders (
    customer_id,
    order_type,
    address,
    neighborhood,
    delivery_fee_amount,
    delivery_fee_label,
    payment_method,
    payment_fee_amount,
    change_for,
    subtotal_amount,
    total_amount,
    notes,
    source
  )
  values (
    customer_record.id,
    coalesce(nullif(payload->>'order_type', ''), 'Entrega'),
    payload->>'address',
    payload->>'neighborhood',
    delivery_fee_amount,
    payload->>'delivery_fee_label',
    coalesce(nullif(payload->>'payment_method', ''), 'Pix'),
    payment_fee_amount,
    payload->>'change_for',
    0,
    0,
    payload->>'notes',
    'web_menu'
  )
  returning * into order_record;

  -- Percorre os itens enviados, valida produto ativo e grava cada item do pedido.
  for item in select * from jsonb_array_elements(payload->'items')
  loop
    select *
    into product_record
    from public.products
    where slug = item->>'product_slug'
      and active = true;

    if not found then
      raise exception 'Invalid or inactive product: %', item->>'product_slug';
    end if;

    item_quantity := greatest(coalesce((item->>'quantity')::integer, 1), 1);

    insert into public.order_items (
      order_id,
      product_id,
      product_name,
      quantity,
      unit_price,
      subtotal
    )
    values (
      order_record.id,
      product_record.id,
      product_record.name,
      item_quantity,
      product_record.price,
      product_record.price * item_quantity
    );

    calculated_subtotal := calculated_subtotal + (product_record.price * item_quantity);
  end loop;

  -- Atualiza subtotal e total com base nos itens realmente gravados.
  update public.orders
  set
    subtotal_amount = calculated_subtotal,
    total_amount = calculated_subtotal + delivery_fee_amount + payment_fee_amount
  where id = order_record.id
  returning * into order_record;

  -- Registra evento de auditoria para rastrear a origem e payload do pedido.
  insert into public.order_events (order_id, event_type, payload)
  values (order_record.id, 'order.created', payload);

  return query
  select order_record.id, order_record.order_number, order_record.total_amount;
end;
$$;

-- Libera apenas a execucao da RPC para usuarios anonimos/autenticados.
revoke all on function public.create_public_order(jsonb) from public;
grant execute on function public.create_public_order(jsonb) to anon, authenticated;

-- ============================================================
-- supabase/migrations/0004_printing_rpc.sql
-- ============================================================
-- Busca pedidos ainda nao impressos para o agente local da impressora.
create or replace function public.get_pending_print_orders(limit_count integer default 10)
returns table (
  order_id uuid,
  order_number bigint,
  created_at timestamptz,
  order_type text,
  address text,
  neighborhood text,
  delivery_fee_amount numeric,
  delivery_fee_label text,
  payment_method text,
  payment_fee_amount numeric,
  change_for text,
  notes text,
  total_amount numeric,
  customer_name text,
  customer_phone text,
  items jsonb
)
language sql
security definer
set search_path = public
as $$
  select
    o.id as order_id,
    o.order_number,
    o.created_at,
    o.order_type,
    o.address,
    o.neighborhood,
    o.delivery_fee_amount,
    o.delivery_fee_label,
    o.payment_method,
    o.payment_fee_amount,
    o.change_for,
    o.notes,
    o.total_amount,
    c.name as customer_name,
    c.phone as customer_phone,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'product_name', oi.product_name,
          'quantity', oi.quantity,
          'unit_price', oi.unit_price,
          'subtotal', oi.subtotal
        )
        order by oi.created_at
      ) filter (where oi.id is not null),
      '[]'::jsonb
    ) as items
  from public.orders o
  left join public.customers c on c.id = o.customer_id
  left join public.order_items oi on oi.order_id = o.id
  where o.order_status in ('new', 'paid', 'in_preparation')
    and not exists (
      select 1
      from public.order_events e
      where e.order_id = o.id
        and e.event_type = 'order.printed'
    )
  group by o.id, c.id
  order by o.created_at asc
  limit greatest(coalesce(limit_count, 10), 1);
$$;

-- Marca pedido como impresso gravando evento de auditoria.
create or replace function public.mark_order_printed(target_order_id uuid, printer_name text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.order_events (order_id, event_type, payload)
  values (
    target_order_id,
    'order.printed',
    jsonb_build_object(
      'printer_name', printer_name,
      'printed_at', now()
    )
  );
end;
$$;

-- Funcoes de impressao usam service_role porque rodam apenas no agente local.
revoke all on function public.get_pending_print_orders(integer) from public;
revoke all on function public.mark_order_printed(uuid, text) from public;
grant execute on function public.get_pending_print_orders(integer) to service_role;
grant execute on function public.mark_order_printed(uuid, text) to service_role;

-- ============================================================
-- supabase/migrations/0005_advanced_kpi_views.sql
-- ============================================================
-- Vendas diarias por produto, util para tendencias e ranking por periodo.
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

-- Mapa de calor com dia da semana x hora, usado para identificar picos.
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

-- Classifica pedidos pelo volume de itens: individual, medio ou grande.
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

-- Pares de produtos comprados juntos, util para combos e sugestoes.
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

-- Segmenta clientes por recencia de compra para acoes de relacionamento.
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

-- Resumo operacional do dia atual para acompanhar pedidos abertos e receita.
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

-- ============================================================
-- supabase/migrations/0006_api_view_grants.sql
-- ============================================================
-- Permite que a API REST do Supabase leia objetos do schema public.
grant usage on schema public to anon, authenticated;

-- Libera leitura das views de analytics para o Streamlit e futuros dashboards.
grant select on
  public.vw_orders_base,
  public.vw_daily_sales,
  public.vw_weekday_sales,
  public.vw_period_sales,
  public.vw_product_sales,
  public.vw_category_sales,
  public.vw_payment_methods,
  public.vw_neighborhood_sales,
  public.vw_order_type_sales,
  public.vw_hourly_sales,
  public.vw_customer_recurrence,
  public.vw_customer_promotion_candidates,
  public.vw_customer_favorite_products,
  public.vw_kpi_snapshot,
  public.vw_order_status_summary,
  public.vw_product_daily_sales,
  public.vw_hour_weekday_heatmap,
  public.vw_basket_summary,
  public.vw_product_pair_sales,
  public.vw_customer_lifecycle,
  public.vw_daily_operational_summary
to anon, authenticated;

-- ============================================================
-- supabase/migrations/0007_order_fee_amounts.sql
-- ============================================================
-- Adiciona valores numericos de entrega e cartao para BI, recibo e auditoria.
alter table public.orders
add column if not exists delivery_fee_amount numeric(10, 2) not null default 0 check (delivery_fee_amount >= 0);

alter table public.orders
add column if not exists payment_fee_amount numeric(10, 2) not null default 0 check (payment_fee_amount >= 0);

-- Atualiza a base operacional para expor subtotal, taxas e total final.
-- A view e removida antes porque o Postgres nao permite mudar a ordem das colunas
-- com create or replace view quando a view ja existe.
drop view if exists public.vw_orders_base;

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
  o.delivery_fee_amount,
  o.payment_fee_amount,
  o.total_amount,
  c.name as customer_name,
  c.phone as customer_phone
from public.orders o
left join public.customers c on c.id = o.customer_id;

-- Atualiza a RPC publica para somar subtotal + entrega + taxa de cartao no total.
create or replace function public.create_public_order(payload jsonb)
returns table (
  order_id uuid,
  order_number bigint,
  total_amount numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_record public.customers%rowtype;
  order_record public.orders%rowtype;
  item jsonb;
  product_record public.products%rowtype;
  item_quantity integer;
  calculated_subtotal numeric(10, 2) := 0;
  delivery_fee_amount numeric(10, 2) := 0;
  payment_fee_amount numeric(10, 2) := 0;
begin
  if payload is null then
    raise exception 'Payload is required';
  end if;

  if coalesce(payload->>'customer_phone', '') = '' then
    raise exception 'Customer phone is required';
  end if;

  if jsonb_typeof(payload->'items') <> 'array' or jsonb_array_length(payload->'items') = 0 then
    raise exception 'At least one item is required';
  end if;

  delivery_fee_amount := greatest(coalesce(nullif(payload->>'delivery_fee_amount', '')::numeric, 0), 0);
  payment_fee_amount := greatest(coalesce(nullif(payload->>'payment_fee_amount', '')::numeric, 0), 0);

  insert into public.customers (name, phone)
  values (
    coalesce(nullif(payload->>'customer_name', ''), 'A informar'),
    payload->>'customer_phone'
  )
  on conflict (phone)
  do update set
    name = excluded.name,
    updated_at = now()
  returning * into customer_record;

  insert into public.orders (
    customer_id,
    order_type,
    address,
    neighborhood,
    delivery_fee_amount,
    delivery_fee_label,
    payment_method,
    payment_fee_amount,
    change_for,
    subtotal_amount,
    total_amount,
    notes,
    source
  )
  values (
    customer_record.id,
    coalesce(nullif(payload->>'order_type', ''), 'Entrega'),
    payload->>'address',
    payload->>'neighborhood',
    delivery_fee_amount,
    payload->>'delivery_fee_label',
    coalesce(nullif(payload->>'payment_method', ''), 'Pix'),
    payment_fee_amount,
    payload->>'change_for',
    0,
    0,
    payload->>'notes',
    'web_menu'
  )
  returning * into order_record;

  for item in select * from jsonb_array_elements(payload->'items')
  loop
    select *
    into product_record
    from public.products
    where slug = item->>'product_slug'
      and active = true;

    if not found then
      raise exception 'Invalid or inactive product: %', item->>'product_slug';
    end if;

    item_quantity := greatest(coalesce((item->>'quantity')::integer, 1), 1);

    insert into public.order_items (
      order_id,
      product_id,
      product_name,
      quantity,
      unit_price,
      subtotal
    )
    values (
      order_record.id,
      product_record.id,
      product_record.name,
      item_quantity,
      product_record.price,
      product_record.price * item_quantity
    );

    calculated_subtotal := calculated_subtotal + (product_record.price * item_quantity);
  end loop;

  update public.orders
  set
    subtotal_amount = calculated_subtotal,
    total_amount = calculated_subtotal + delivery_fee_amount + payment_fee_amount
  where id = order_record.id
  returning * into order_record;

  insert into public.order_events (order_id, event_type, payload)
  values (order_record.id, 'order.created', payload);

  return query
  select order_record.id, order_record.order_number, order_record.total_amount;
end;
$$;

revoke all on function public.create_public_order(jsonb) from public;
grant execute on function public.create_public_order(jsonb) to anon, authenticated;

-- Atualiza a RPC da impressora para a comanda exibir subtotal, entrega e taxa de cartao.
create or replace function public.get_pending_print_orders(limit_count integer default 10)
returns table (
  order_id uuid,
  order_number bigint,
  created_at timestamptz,
  order_type text,
  address text,
  neighborhood text,
  delivery_fee_amount numeric,
  delivery_fee_label text,
  payment_method text,
  payment_fee_amount numeric,
  change_for text,
  notes text,
  total_amount numeric,
  customer_name text,
  customer_phone text,
  items jsonb
)
language sql
security definer
set search_path = public
as $$
  select
    o.id as order_id,
    o.order_number,
    o.created_at,
    o.order_type,
    o.address,
    o.neighborhood,
    o.delivery_fee_amount,
    o.delivery_fee_label,
    o.payment_method,
    o.payment_fee_amount,
    o.change_for,
    o.notes,
    o.total_amount,
    c.name as customer_name,
    c.phone as customer_phone,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'product_name', oi.product_name,
          'quantity', oi.quantity,
          'unit_price', oi.unit_price,
          'subtotal', oi.subtotal
        )
        order by oi.created_at
      ) filter (where oi.id is not null),
      '[]'::jsonb
    ) as items
  from public.orders o
  left join public.customers c on c.id = o.customer_id
  left join public.order_items oi on oi.order_id = o.id
  where o.order_status in ('new', 'paid', 'in_preparation')
    and not exists (
      select 1
      from public.order_events e
      where e.order_id = o.id
        and e.event_type = 'order.printed'
    )
  group by o.id, c.id
  order by o.created_at asc
  limit greatest(coalesce(limit_count, 10), 1);
$$;

revoke all on function public.get_pending_print_orders(integer) from public;
grant execute on function public.get_pending_print_orders(integer) to service_role;

-- ============================================================
-- supabase/migrations/0008_menu_beverages_update.sql
-- ============================================================
-- Atualiza a categoria Bebidas com Pepsi lata e sucos individuais.
with bebida_category as (
  select id
  from public.categories
  where slug = 'bebidas'
),
product_seed(slug, name, description, price, image_url, active, highlight) as (
  values
  ('bebida-pepsi-350', 'Pepsi 350ml', 'Refrigerante Pepsi lata.', 5.50, '/menu-images/img11.jpeg', true, false),
  ('suco-uva', 'Suco de uva 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/img11.jpeg', true, false),
  ('suco-caja', 'Suco de cajá 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/img11.jpeg', true, false),
  ('suco-acerola', 'Suco de acerola 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/img11.jpeg', true, false)
)
insert into public.products (slug, category_id, name, description, price, image_url, active, highlight)
select
  product_seed.slug,
  bebida_category.id,
  product_seed.name,
  product_seed.description,
  product_seed.price,
  product_seed.image_url,
  product_seed.active,
  product_seed.highlight
from product_seed
cross join bebida_category
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  price = excluded.price,
  image_url = excluded.image_url,
  active = excluded.active,
  highlight = excluded.highlight,
  updated_at = now();

-- Desativa o item antigo que foi substituido por sucos individuais.
update public.products
set
  active = false,
  updated_at = now()
where slug = 'suco-uva-caja-acerola';

-- ============================================================
-- supabase/migrations/0009_menu_product_images.sql
-- ============================================================
-- Atualiza imagens especificas do cardapio depois da entrada de novas fotos.
update public.products
set
  image_url = '/menu-images/hot-dogao.jpeg',
  updated_at = now()
where slug in (
  'hotdog-andorra',
  'hotdog-reino-unido',
  'hotdog-estados-unidos'
);

-- Usa a mesma foto base de pastel em todos os sabores.
update public.products
set
  image_url = '/menu-images/pastel.jpeg',
  updated_at = now()
where slug in (
  'pastel-belgica',
  'pastel-russia',
  'pastel-franca',
  'pastel-suica',
  'pastel-brasil',
  'pastel-austria',
  'pastel-mexico'
);

-- Aplica a foto nova do petisco de frango.
update public.products
set
  image_url = '/menu-images/frango-a-passarinho-com-fritas.jpeg',
  updated_at = now()
where slug = 'petisco-frango';

-- ============================================================
-- supabase/migrations/0010_juice_product_images.sql
-- ============================================================
-- Atualiza as imagens dos sucos individuais no cardapio publicado pelo Supabase.
update public.products
set
  image_url = case slug
    when 'suco-manga-goiaba' then '/menu-images/suco-manga.jpeg'
    when 'suco-uva' then '/menu-images/suco-uva.jpeg'
    when 'suco-caja' then '/menu-images/suco-caja.jpeg'
    when 'suco-acerola' then '/menu-images/suco-acerola.jpeg'
    else image_url
  end,
  updated_at = now()
where slug in (
  'suco-manga-goiaba',
  'suco-uva',
  'suco-caja',
  'suco-acerola'
);

-- ============================================================
-- supabase/migrations/0011_split_manga_goiaba_and_soda_images.sql
-- ============================================================
-- Atualiza refrigerantes com imagens individuais e separa manga/goiaba em dois sucos.
with bebida_category as (
  select id
  from public.categories
  where slug = 'bebidas'
),
product_seed(slug, name, description, price, image_url, active, highlight) as (
  values
  ('bebida-guarana-1l', 'Guaraná 1 litro', 'Refrigerante Guaraná 1L.', 8.50, '/menu-images/bebida-guarana-1l.jpeg', true, false),
  ('bebida-pepsi-1l', 'Pepsi 1 litro', 'Refrigerante Pepsi 1L.', 8.50, '/menu-images/bebida-pepsi-1l.jpeg', true, false),
  ('bebida-coca-350', 'Coca Cola sem açúcar 350ml', 'Refrigerante Coca Cola sem açúcar lata.', 5.50, '/menu-images/bebida-coca-cola-sem-acucar-350.jpeg', true, false),
  ('bebida-pepsi-350', 'Pepsi 350ml', 'Refrigerante Pepsi lata.', 5.50, '/menu-images/bebida-pepsi-350.jpeg', true, false),
  ('bebida-guarana-350', 'Guaraná 350ml', 'Refrigerante Guaraná lata.', 5.00, '/menu-images/bebida-guarana-350.jpeg', true, false),
  ('bebida-fanta-uva-350', 'Fanta Uva 350ml', 'Refrigerante Fanta Uva lata.', 5.00, '/menu-images/bebida-fanta-uva-350.jpeg', true, false),
  ('suco-manga', 'Suco de manga 300ml', 'Adicionar leite custa R$ 2,00.', 4.50, '/menu-images/suco-manga.jpeg', true, false),
  ('suco-goiaba', 'Suco de goiaba 300ml', 'Adicionar leite custa R$ 2,00.', 4.50, '/menu-images/suco-goiaba.jpeg', true, false)
)
insert into public.products (slug, category_id, name, description, price, image_url, active, highlight)
select
  product_seed.slug,
  bebida_category.id,
  product_seed.name,
  product_seed.description,
  product_seed.price,
  product_seed.image_url,
  product_seed.active,
  product_seed.highlight
from product_seed
cross join bebida_category
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  price = excluded.price,
  image_url = excluded.image_url,
  active = excluded.active,
  highlight = excluded.highlight,
  updated_at = now();

-- O antigo item combinado deixa de aparecer no cardápio.
update public.products
set
  active = false,
  updated_at = now()
where slug = 'suco-manga-goiaba';

-- ============================================================
-- supabase/seed.sql
-- ============================================================
-- Seed completo gerado a partir de src/app/data/menu.data.ts.
-- Regerar sempre que o cardapio estatico mudar.

-- Carga das categorias do cardapio.
with category_seed(slug, name, description, active, sort_order) as (
  values
  ('promocoes', 'Promoções', 'Combos e ofertas para pedir rápido.', true, 1),
  ('hamburgueres', 'Hambúrgueres', 'Sanduíches da casa com nomes de seleções.', true, 2),
  ('baguetes', 'Baguetes', 'Baguetes recheadas para matar a fome.', true, 3),
  ('hot-dogao', 'Hot Dogão', 'Hot dogs completos e caprichados.', true, 4),
  ('pasteis', 'Pastéis', 'Pastéis tradicionais e especiais.', true, 5),
  ('cuscuz', 'Cuscuz', 'Cuscuz recheado feito na hora.', true, 6),
  ('tapiocas', 'Tapiocas', 'Tapiocas salgadas da casa.', true, 7),
  ('petiscos', 'Petiscos', 'Porções e petiscos para compartilhar.', true, 8),
  ('bebidas', 'Bebidas', 'Refrigerantes e sucos.', true, 9)
)
insert into public.categories (slug, name, description, active, sort_order)
select slug, name, description, active, sort_order
from category_seed
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  active = excluded.active,
  sort_order = excluded.sort_order,
  updated_at = now();

-- Carga dos produtos do cardapio, sempre ligada a categoria pelo slug.
with product_seed(slug, category_slug, name, description, price, image_url, active, highlight) as (
  values
  ('combo-completo', 'promocoes', 'Combo Completo', '3 hot dogão Andorra, 2 hambúrgueres Suécia, porção de batata com cheddar e refrigerante 1 litro.', 59.99, '/menu-images/combo-completo-semana.jpeg', true, true),
  ('combo-suecia', 'promocoes', 'Combo Suécia', '3 sanduíches, batata e refrigerante 1 litro.', 39.90, '/menu-images/img01.jpeg', true, true),
  ('promocao-andorra', 'promocoes', 'Promoção 3 Andorra', '3 hot dogão Andorra.', 15.00, '/menu-images/img03.jpeg', true, true),
  ('promocao-espanha', 'promocoes', 'Espanha com fritas', '1 hambúrguer Espanha com meia porção de fritas.', 16.00, '/menu-images/img04.jpeg', true, true),
  ('hamburguer-suecia', 'hamburgueres', 'Suécia', 'Pão, hambúrguer, ovo, presunto, requeijão cheddar, alface e tomate.', 8.00, '/menu-images/hamburguer-suecia.png', true, false),
  ('hamburguer-espanha', 'hamburgueres', 'Espanha', 'Pão, hambúrguer, mussarela, salsicha, ovo, alface, tomate e molho.', 10.00, '/menu-images/img06.jpeg', true, false),
  ('hamburguer-alemanha', 'hamburgueres', 'Alemanha', 'Pão, hambúrguer, frango, ovo, alface, tomate e mussarela.', 12.00, '/menu-images/img06.jpeg', true, false),
  ('hamburguer-polonia', 'hamburgueres', 'Polônia', 'Pão, hambúrguer, camarão com catupiry, mussarela, alface e tomate.', 16.00, '/menu-images/img06.jpeg', true, false),
  ('hamburguer-finlandia', 'hamburgueres', 'Finlândia', 'Pão, hambúrguer, bacon, ovo, mussarela, presunto, alface, tomate e molho.', 14.00, '/menu-images/img06.jpeg', true, false),
  ('hamburguer-inglaterra', 'hamburgueres', 'Inglaterra', 'Pão de hambúrguer, carne de sol desfiada, cebola grelhada, queijo coalho e mussarela.', 14.00, '/menu-images/img06.jpeg', true, false),
  ('baguete-italia', 'baguetes', 'Itália', 'Pão baguete, frango desfiado, cebola grelhada, mussarela, alface, tomate e molho.', 12.00, '/menu-images/baguete-italia.png', true, false),
  ('baguete-monaco', 'baguetes', 'Mônaco', 'Pão baguete, frango com catupiry, alface e tomate.', 13.00, '/menu-images/img06.jpeg', true, false),
  ('baguete-portugal', 'baguetes', 'Portugal', 'Pão baguete, salsicha, ovo, mussarela, alface, tomate e molho.', 12.00, '/menu-images/img06.jpeg', true, false),
  ('baguete-croacia', 'baguetes', 'Croácia', 'Pão baguete, calabresa, mussarela, alface, tomate, cebola grelhada e barbecue.', 12.00, '/menu-images/img06.jpeg', true, false),
  ('baguete-prime', 'baguetes', 'Prime', 'Pão baguete, carne de sol na nata, alface e tomate.', 14.00, '/menu-images/baguete-prime.png', true, false),
  ('hotdog-andorra', 'hot-dogao', 'Andorra', 'Frango, carne moída, salsicha, vinagrete, batata palha e queijo ralado.', 7.00, '/menu-images/hot-dogao.jpeg', true, false),
  ('hotdog-reino-unido', 'hot-dogao', 'Reino Unido', 'Salsicha, carne de sol na nata, vinagrete e queijo ralado.', 9.00, '/menu-images/hot-dogao.jpeg', true, false),
  ('hotdog-estados-unidos', 'hot-dogao', 'Estados Unidos', 'Frango com catupiry, salsicha, vinagrete, batata palha e queijo ralado.', 9.00, '/menu-images/hot-dogao.jpeg', true, false),
  ('pastel-belgica', 'pasteis', 'Bélgica', 'Carne de sol na nata.', 12.00, '/menu-images/pastel.jpeg', true, false),
  ('pastel-russia', 'pasteis', 'Rússia', 'Carne moída com mussarela.', 8.00, '/menu-images/pastel.jpeg', true, false),
  ('pastel-franca', 'pasteis', 'França', 'Frango desfiado com catupiry.', 8.00, '/menu-images/pastel.jpeg', true, false),
  ('pastel-suica', 'pasteis', 'Suíça', 'Camarão com catupiry.', 12.00, '/menu-images/pastel.jpeg', true, false),
  ('pastel-brasil', 'pasteis', 'Brasil', 'Queijo, presunto e orégano.', 5.00, '/menu-images/pastel.jpeg', true, false),
  ('pastel-austria', 'pasteis', 'Áustria', 'Calabresa, cebola, mussarela e orégano.', 8.00, '/menu-images/pastel.jpeg', true, false),
  ('pastel-mexico', 'pasteis', 'México', 'Frango desfiado, mussarela e orégano.', 8.00, '/menu-images/pastel.jpeg', true, false),
  ('cuscuz-opcao-1', 'cuscuz', 'Opção 1', 'Carne de sol na nata com fatias de mussarela.', 15.00, '/menu-images/img08.jpeg', true, false),
  ('cuscuz-opcao-2', 'cuscuz', 'Opção 2', 'Frango desfiado com requeijão.', 12.00, '/menu-images/img08.jpeg', true, false),
  ('cuscuz-opcao-3', 'cuscuz', 'Opção 3', 'Calabresa com fatias de mussarela.', 10.00, '/menu-images/img08.jpeg', true, false),
  ('cuscuz-opcao-4', 'cuscuz', 'Opção 4', 'Salsicha ao molho de tomate.', 10.00, '/menu-images/img08.jpeg', true, false),
  ('tapioca-carne-sol', 'tapiocas', 'Carne de sol na nata', 'Tapioca recheada com carne de sol na nata.', 10.00, '/menu-images/img09.jpeg', true, false),
  ('tapioca-calabresa', 'tapiocas', 'Calabresa com mussarela', 'Tapioca recheada com calabresa e mussarela.', 7.00, '/menu-images/img09.jpeg', true, false),
  ('tapioca-frango', 'tapiocas', 'Frango desfiado com mussarela', 'Tapioca recheada com frango desfiado e mussarela.', 7.00, '/menu-images/img09.jpeg', true, false),
  ('tapioca-queijo-presunto', 'tapiocas', 'Queijo mussarela e presunto', 'Tapioca recheada com queijo mussarela e presunto.', 6.00, '/menu-images/img09.jpeg', true, false),
  ('petisco-camarao', 'petiscos', 'Camarão ao alho e óleo com fritas', 'Petisco com camarão e fritas.', 30.00, '/menu-images/petisco-camarao.png', true, false),
  ('petisco-frango', 'petiscos', 'Frango a passarinho com fritas', 'Petisco de frango com fritas.', 25.00, '/menu-images/frango-a-passarinho-com-fritas.jpeg', true, false),
  ('petisco-carne-sol', 'petiscos', 'Carne de sol sertanejo com queijo coalho', 'Petisco de carne de sol com queijo coalho.', 30.00, '/menu-images/petisco-carne-sol.png', true, false),
  ('porcao-macaxeira', 'petiscos', 'Macaxeira 450g', 'Porção de macaxeira.', 12.00, '/menu-images/porcao-macaxeira.png', true, false),
  ('porcao-fritas', 'petiscos', 'Fritas 450g', 'Porção de batata frita.', 12.00, '/menu-images/porcao-fritas.png', true, false),
  ('porcao-fritas-cheddar', 'petiscos', 'Fritas com requeijão cheddar 450g', 'Porção de fritas com cheddar.', 15.00, '/menu-images/porcao-fritas-cheddar.png', true, false),
  ('bebida-guarana-1l', 'bebidas', 'Guaraná 1 litro', 'Refrigerante Guaraná 1L.', 8.50, '/menu-images/bebida-guarana-1l.jpeg', true, false),
  ('bebida-pepsi-1l', 'bebidas', 'Pepsi 1 litro', 'Refrigerante Pepsi 1L.', 8.50, '/menu-images/bebida-pepsi-1l.jpeg', true, false),
  ('bebida-coca-350', 'bebidas', 'Coca Cola sem açúcar 350ml', 'Refrigerante Coca Cola sem açúcar lata.', 5.50, '/menu-images/bebida-coca-cola-sem-acucar-350.jpeg', true, false),
  ('bebida-pepsi-350', 'bebidas', 'Pepsi 350ml', 'Refrigerante Pepsi lata.', 5.50, '/menu-images/bebida-pepsi-350.jpeg', true, false),
  ('bebida-guarana-350', 'bebidas', 'Guaraná 350ml', 'Refrigerante Guaraná lata.', 5.00, '/menu-images/bebida-guarana-350.jpeg', true, false),
  ('bebida-fanta-uva-350', 'bebidas', 'Fanta Uva 350ml', 'Refrigerante Fanta Uva lata.', 5.00, '/menu-images/bebida-fanta-uva-350.jpeg', true, false),
  ('suco-manga', 'bebidas', 'Suco de manga 300ml', 'Adicionar leite custa R$ 2,00.', 4.50, '/menu-images/suco-manga.jpeg', true, false),
  ('suco-goiaba', 'bebidas', 'Suco de goiaba 300ml', 'Adicionar leite custa R$ 2,00.', 4.50, '/menu-images/suco-goiaba.jpeg', true, false),
  ('suco-uva', 'bebidas', 'Suco de uva 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/suco-uva.jpeg', true, false),
  ('suco-caja', 'bebidas', 'Suco de cajá 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/suco-caja.jpeg', true, false),
  ('suco-acerola', 'bebidas', 'Suco de acerola 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/suco-acerola.jpeg', true, false)
)
insert into public.products (slug, category_id, name, description, price, image_url, active, highlight)
select
  product_seed.slug,
  categories.id,
  product_seed.name,
  product_seed.description,
  product_seed.price,
  product_seed.image_url,
  product_seed.active,
  product_seed.highlight
from product_seed
join public.categories on categories.slug = product_seed.category_slug
-- Atualiza produtos existentes sem duplicar registros.
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  price = excluded.price,
  image_url = excluded.image_url,
  active = excluded.active,
  highlight = excluded.highlight,
  updated_at = now();
