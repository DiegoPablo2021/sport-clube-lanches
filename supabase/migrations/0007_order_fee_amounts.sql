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
