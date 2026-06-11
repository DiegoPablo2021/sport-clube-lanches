-- Validar se o catalogo foi carregado.
select count(*) as total_categories from public.categories;
select count(*) as total_products from public.products;

-- Ver produtos ativos por categoria.
select
  c.name as category_name,
  count(p.id) as active_products
from public.categories c
left join public.products p on p.category_id = c.id and p.active = true
group by c.name, c.sort_order
order by c.sort_order;

-- Criar um pedido de teste.
select *
from public.create_public_order(
  '{
    "customer_name": "Cliente Teste",
    "customer_phone": "84999999999",
    "order_type": "Entrega",
    "address": "Rua Teste, 123",
    "neighborhood": "Sport Clube 3/4",
    "delivery_fee_label": "Taxa de entrega: gratis para Sport Clube 3/4.",
    "payment_method": "Pix",
    "notes": "Pedido criado pelo SQL Editor",
    "items": [
      {
        "product_slug": "hamburguer-suecia",
        "quantity": 1
      },
      {
        "product_slug": "porcao-fritas",
        "quantity": 1
      }
    ]
  }'::jsonb
);

-- Ultimos pedidos.
select *
from public.vw_orders_base
order by created_at desc
limit 20;

-- Remover um pedido de teste pelo numero.
-- Use apenas para pedidos criados em validacao. Os itens e eventos sao removidos em cascata.
delete from public.orders
where order_number = 1;

-- Itens do ultimo pedido.
select
  o.order_number,
  oi.product_name,
  oi.quantity,
  oi.unit_price,
  oi.subtotal
from public.orders o
join public.order_items oi on oi.order_id = o.id
where o.order_number = (
  select max(order_number) from public.orders
)
order by oi.created_at;

-- Pedidos pendentes para impressao.
select *
from public.get_pending_print_orders(10);

-- Marcar o ultimo pedido como ainda nao impresso para testar novamente.
delete from public.order_events
where event_type = 'order.printed'
  and order_id = (
    select id
    from public.orders
    order by created_at desc
    limit 1
  );

-- KPIs principais.
select * from public.vw_kpi_snapshot;
select * from public.vw_daily_operational_summary;
select * from public.vw_daily_sales order by order_date desc limit 30;
select * from public.vw_product_sales limit 20;
select * from public.vw_customer_promotion_candidates limit 20;
select * from public.vw_customer_lifecycle limit 20;
select * from public.vw_hour_weekday_heatmap;
