-- Atualiza a RPC publica para aceitar adicionais por item, como leite nos sucos.
-- O adicional entra no preco unitario, no subtotal do item e no total do pedido.
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
  item_additional_amount numeric(10, 2);
  item_unit_price numeric(10, 2);
  item_product_name text;
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
    item_additional_amount := greatest(coalesce(nullif(item->>'unit_additional_amount', '')::numeric, 0), 0);
    item_unit_price := product_record.price + item_additional_amount;
    item_product_name := product_record.name;

    if coalesce(nullif(item->>'options_label', ''), '') <> '' then
      item_product_name := product_record.name || ' (' || item->>'options_label' || ')';
    end if;

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
      item_product_name,
      item_quantity,
      item_unit_price,
      item_unit_price * item_quantity
    );

    calculated_subtotal := calculated_subtotal + (item_unit_price * item_quantity);
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
