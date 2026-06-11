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
