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
begin
  -- Validacoes minimas para evitar pedido sem telefone ou sem itens.
  if payload is null then
    raise exception 'Payload is required';
  end if;

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
    delivery_fee_label,
    payment_method,
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
    payload->>'delivery_fee_label',
    coalesce(nullif(payload->>'payment_method', ''), 'A combinar'),
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
    total_amount = calculated_subtotal
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
