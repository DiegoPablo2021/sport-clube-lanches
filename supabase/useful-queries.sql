-- ============================================================
-- Query: 01 - Validar carga do catalogo
-- O que faz: mostra se as categorias e produtos do cardapio foram carregados.
-- Como usar: rode depois do seed ou apply-all para conferir se ha dados.
-- ============================================================
select count(*) as total_categories from public.categories;
select count(*) as total_products from public.products;


-- ============================================================
-- Query: 02 - Produtos ativos por categoria
-- O que faz: mostra quantos produtos ativos existem em cada categoria.
-- Como usar: ajuda a conferir se alguma categoria ficou vazia no cardapio.
-- ============================================================
select
  c.name as category_name,
  count(p.id) as active_products
from public.categories c
left join public.products p on p.category_id = c.id and p.active = true
group by c.name, c.sort_order
order by c.sort_order;


-- ============================================================
-- Query: 03 - Criar pedido de teste
-- O que faz: cria um pedido fake para validar Supabase, Streamlit e impressora.
-- Como usar: rode apenas em validacao; depois remova com a query 07 ou 08.
-- ============================================================
select *
from public.create_public_order(
  '{
    "customer_name": "Cliente Teste",
    "customer_phone": "84999999999",
    "order_type": "Entrega",
    "address": "Rua Teste, 123",
    "neighborhood": "Sport Clube 3/4",
    "delivery_fee_amount": 0,
    "delivery_fee_label": "Taxa de entrega: gratis para Sport Clube 3/4.",
    "payment_fee_amount": 0,
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


-- ============================================================
-- Query: 04 - Operacao - Listar ultimos pedidos
-- O que faz: lista os pedidos mais recentes com cliente, status e valores.
-- Como usar: rode antes de apagar testes para descobrir o order_number correto.
-- ============================================================
select *
from public.vw_orders_base
order by created_at desc
limit 20;


-- ============================================================
-- Query: 05 - Operacao - Ver pedidos abertos
-- O que faz: lista pedidos que ainda estao em aberto ou preparo.
-- Como usar: boa para acompanhar a fila antes da impressora/tela da cozinha.
-- ============================================================
select *
from public.vw_orders_base
where order_status in ('new', 'awaiting_confirmation', 'awaiting_payment', 'paid', 'in_preparation', 'ready', 'out_for_delivery')
order by created_at asc;


-- ============================================================
-- Query: 06 - Operacao - Pedidos de hoje
-- O que faz: mostra todos os pedidos criados hoje, do mais recente para o mais antigo.
-- Como usar: consulta rapida para conferir o movimento do dia.
-- ============================================================
select *
from public.vw_orders_base
where created_at::date = current_date
order by created_at desc;


-- ============================================================
-- Query: 07 - Operacao - Ver itens de um pedido
-- O que faz: mostra os itens de um pedido especifico.
-- Como usar: troque o numero 1 pelo numero do pedido que deseja conferir.
-- ============================================================
select
  o.order_number,
  oi.product_name,
  oi.quantity,
  oi.unit_price,
  oi.subtotal
from public.orders o
join public.order_items oi on oi.order_id = o.id
where o.order_number = 1
order by oi.created_at;


-- ============================================================
-- Query: 08 - Operacao - Ver itens do ultimo pedido
-- O que faz: mostra os itens do pedido mais recente.
-- Como usar: util depois de fazer um pedido de teste pelo cardapio.
-- ============================================================
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


-- ============================================================
-- Query: 09 - Limpeza - Remover pedidos de teste por numero
-- O que faz: remove pedidos especificos pelos numeros.
-- Como usar: rode a query 04 ou 06, veja os order_number de teste e troque no in (...).
-- Observacao: itens e eventos do pedido sao removidos automaticamente em cascata.
-- ============================================================
delete from public.orders
where order_number in (1, 2);


-- ============================================================
-- Query: 10 - Limpeza - Remover pedidos de teste por telefone
-- O que faz: remove todos os pedidos ligados a um telefone especifico.
-- Como usar: troque o telefone abaixo pelo telefone usado nos testes.
-- Cuidado: use apenas com telefone de teste, nunca com cliente real.
-- ============================================================
delete from public.orders o
using public.customers c
where c.id = o.customer_id
  and regexp_replace(c.phone, '\D', '', 'g') = '5584987245896';


-- ============================================================
-- Query: 11 - Limpeza - Limpar clientes sem pedido
-- O que faz: remove clientes que ficaram sem nenhum pedido apos apagar testes.
-- Como usar: rode depois das queries 09 ou 10, se quiser limpar cadastro teste.
-- ============================================================
delete from public.customers c
where not exists (
  select 1
  from public.orders o
  where o.customer_id = c.id
);


-- ============================================================
-- Query: 12 - Limpeza - Zerar pedidos de teste antes da operacao real
-- O que faz: remove todos os pedidos, itens e eventos, reiniciando a numeracao.
-- Como usar: rode SOMENTE quando tiver certeza de que ainda nao ha pedido real.
-- Observacao: mantem o catalogo/cardapio intacto; apaga apenas movimento.
-- ============================================================
truncate table
  public.order_events,
  public.order_items,
  public.orders
restart identity cascade;

delete from public.customers c
where not exists (
  select 1
  from public.orders o
  where o.customer_id = c.id
);


-- ============================================================
-- Query: 13 - Validacao - Confirmar banco sem pedidos
-- O que faz: confere se pedidos, itens e eventos foram removidos.
-- Como usar: rode depois da limpeza para confirmar que o dashboard deve zerar.
-- ============================================================
select 'orders' as tabela, count(*) as total from public.orders
union all
select 'order_items' as tabela, count(*) as total from public.order_items
union all
select 'order_events' as tabela, count(*) as total from public.order_events
union all
select 'customers' as tabela, count(*) as total from public.customers;


-- ============================================================
-- Query: 14 - Impressora - Pedidos pendentes para impressao
-- O que faz: mostra pedidos que o agente local da impressora deve imprimir.
-- Como usar: util quando a impressora chegar para testar a fila.
-- ============================================================
select *
from public.get_pending_print_orders(10);


-- ============================================================
-- Query: 15 - Impressora - Liberar ultimo pedido para reimpressao
-- O que faz: remove o evento order.printed do ultimo pedido.
-- Como usar: rode quando quiser testar a mesma comanda de novo na impressora.
-- ============================================================
delete from public.order_events
where event_type = 'order.printed'
  and order_id = (
    select id
    from public.orders
    order by created_at desc
    limit 1
  );


-- ============================================================
-- Query: 16 - Dashboard - KPI snapshot geral
-- O que faz: retorna os principais numeros acumulados do negocio.
-- Como usar: base para cards de Power BI ou conferencia rapida.
-- ============================================================
select * from public.vw_kpi_snapshot;


-- ============================================================
-- Query: 17 - Dashboard - Resumo operacional do dia
-- O que faz: mostra pedidos, receita, ticket medio e pedidos abertos do dia.
-- Como usar: ideal para acompanhamento diario da lanchonete.
-- ============================================================
select * from public.vw_daily_operational_summary;


-- ============================================================
-- Query: 18 - Dashboard - Vendas diarias
-- O que faz: mostra pedidos, cancelados, faturamento e ticket medio por dia.
-- Como usar: base para grafico de faturamento diario.
-- ============================================================
select *
from public.vw_daily_sales
order by order_date desc
limit 30;


-- ============================================================
-- Query: 19 - Dashboard - Produtos mais vendidos
-- O que faz: ranqueia produtos por quantidade vendida e faturamento.
-- Como usar: ajuda Leandro e Kardiele a saberem o que mais sai.
-- ============================================================
select *
from public.vw_product_sales
limit 20;


-- ============================================================
-- Query: 20 - Dashboard - Clientes que mais compram
-- O que faz: mostra ranking de clientes por pedidos e faturamento.
-- Como usar: bom para relacionamento e para descobrir clientes fieis.
-- ============================================================
select *
from public.vw_customer_recurrence
limit 30;


-- ============================================================
-- Query: 21 - Dashboard - Clientes candidatos a promocao
-- O que faz: sugere clientes para brinde/cupom pelo historico recente.
-- Como usar: base para campanhas manuais no WhatsApp.
-- ============================================================
select *
from public.vw_customer_promotion_candidates
limit 20;


-- ============================================================
-- Query: 22 - Dashboard - Ciclo de vida dos clientes
-- O que faz: classifica clientes como ativo, aquecido, risco de sumir ou inativo.
-- Como usar: ajuda em acoes de relacionamento e recuperacao.
-- ============================================================
select *
from public.vw_customer_lifecycle
limit 20;


-- ============================================================
-- Query: 23 - Dashboard - Horario de pico por dia da semana
-- O que faz: retorna pedidos por dia da semana e hora.
-- Como usar: base para mapa de calor no Streamlit ou Power BI.
-- ============================================================
select *
from public.vw_hour_weekday_heatmap;


-- ============================================================
-- Query: 24 - Dashboard - Bairros que mais compram
-- O que faz: mostra pedidos, faturamento e ticket medio por bairro/localidade.
-- Como usar: ajuda a entender onde vale divulgar e como revisar taxa de entrega.
-- ============================================================
select *
from public.vw_neighborhood_sales
limit 30;


-- ============================================================
-- Query: 25 - Dashboard - Formas de pagamento
-- O que faz: resume pedidos e faturamento por forma de pagamento.
-- Como usar: acompanha preferencia dos clientes e uso de Pix/cartao/dinheiro.
-- ============================================================
select *
from public.vw_payment_methods;


-- ============================================================
-- Query: 26 - Financeiro - Taxas de entrega e cartao
-- O que faz: mostra subtotal, taxa de entrega, taxa de cartao e total por pedido.
-- Como usar: confere se o pedido gravou os valores corretamente para o BI.
-- ============================================================
select
  order_number,
  created_at,
  customer_name,
  neighborhood,
  payment_method,
  subtotal_amount,
  delivery_fee_amount,
  payment_fee_amount,
  total_amount
from public.vw_orders_base
order by created_at desc
limit 30;


-- ============================================================
-- Query: 27 - Financeiro - Receita por forma de pagamento hoje
-- O que faz: resume pedidos e receita do dia por pagamento.
-- Como usar: ajuda no fechamento diario de caixa.
-- ============================================================
select
  payment_method,
  count(*) as total_orders,
  coalesce(sum(subtotal_amount), 0) as subtotal_amount,
  coalesce(sum(delivery_fee_amount), 0) as delivery_fee_amount,
  coalesce(sum(payment_fee_amount), 0) as payment_fee_amount,
  coalesce(sum(total_amount), 0) as total_amount
from public.vw_orders_base
where created_at::date = current_date
  and order_status <> 'cancelled'
group by payment_method
order by total_amount desc;


-- ============================================================
-- Query: 28 - Catalogo - Produtos sem imagem ou inativos
-- O que faz: lista produtos sem imagem cadastrada ou que estao inativos.
-- Como usar: manutencao rapida do cardapio.
-- ============================================================
select
  p.slug,
  p.name,
  c.name as category_name,
  p.image_url,
  p.active
from public.products p
join public.categories c on c.id = p.category_id
where p.image_url is null
   or trim(p.image_url) = ''
   or p.active = false
order by c.sort_order, p.name;
