# Fase 2 - Backend, Persistencia e Base de Dados

## Objetivo

Criar uma base operacional para salvar pedidos, clientes, produtos e eventos do delivery. Essa fase prepara o caminho para admin, dashboards, historico e automacoes.

## Motivacao

Na Fase 1, o pedido e montado no cardapio e enviado ao WhatsApp, mas nao fica salvo em banco. Isso resolve o atendimento inicial, mas ainda nao gera historico confiavel para KPIs.

Na Fase 2, cada pedido deve ser registrado antes ou durante o envio ao WhatsApp.

## Stack definida para a primeira entrega

- Supabase PostgreSQL
- Row Level Security
- Funcao RPC `public.create_public_order(payload jsonb)`
- Frontend Angular com persistencia opcional via `@supabase/supabase-js`
- Streamlit para prototipo de dashboard
- Power BI Desktop para dashboard oficial futuro

Um backend dedicado em Node.js/NestJS ou Fastify continua sendo uma evolucao possivel, mas nao e obrigatorio para a primeira gravacao real de pedidos.

## Entidades principais

### categories

- `id`
- `slug`
- `name`
- `description`
- `active`
- `sort_order`
- `created_at`
- `updated_at`

### products

- `id`
- `slug`
- `category_id`
- `name`
- `description`
- `price`
- `image_url`
- `active`
- `highlight`
- `created_at`
- `updated_at`

### customers

- `id`
- `name`
- `phone`
- `created_at`
- `updated_at`

### orders

- `id`
- `order_number`
- `customer_id`
- `order_type`
- `address`
- `neighborhood`
- `delivery_fee_label`
- `payment_method`
- `change_for`
- `payment_status`
- `order_status`
- `subtotal_amount`
- `total_amount`
- `notes`
- `created_at`
- `updated_at`

### order_items

- `id`
- `order_id`
- `product_id`
- `product_name`
- `quantity`
- `unit_price`
- `subtotal`
- `created_at`

### order_events

- `id`
- `order_id`
- `event_type`
- `payload`
- `created_at`

## Fluxo recomendado

```text
Cliente monta pedido
  -> frontend chama create_public_order no Supabase
  -> Supabase cria pedido com status "new"
  -> Supabase retorna numero do pedido
  -> frontend abre WhatsApp com numero e resumo do pedido
```

## Status iniciais

- `novo`
- `aguardando_confirmacao`
- `aguardando_pagamento`
- `pago`
- `em_preparo`
- `pronto`
- `saiu_para_entrega`
- `finalizado`
- `cancelado`

## Contrato inicial

- `select` publico em categorias e produtos ativos.
- `rpc create_public_order(payload jsonb)` para gravar pedidos.
- Status e eventos registrados em `orders` e `order_events`.

## Dashboard e dados

A Fase 2 e a origem dos dados para Streamlit e Power BI.

Fluxo:

```text
Supabase PostgreSQL
  -> views analiticas
  -> Streamlit para prototipo
  -> Power BI para painel oficial
```

O Power BI deve consumir os dados do Supabase, preferencialmente por views analiticas. Assim evitamos dependencia de planilhas Excel e reduzimos trabalho manual.

## Views analiticas sugeridas

- `vw_daily_sales`
- `vw_weekday_sales`
- `vw_period_sales`
- `vw_product_sales`
- `vw_category_sales`
- `vw_payment_methods`
- `vw_neighborhood_sales`
- `vw_order_type_sales`
- `vw_hourly_sales`
- `vw_customer_recurrence`
- `vw_customer_promotion_candidates`
- `vw_customer_favorite_products`
- `vw_kpi_snapshot`

## Relacao com impressao de pedidos

A impressora USB/Bluetooth entra melhor na Fase 3, consumindo os pedidos ja salvos no Supabase por meio do agente local em `printer-agent/`.

## Criterios de pronto

- Pedido salvo em banco.
- Numero de pedido gerado.
- Itens do pedido salvos com snapshot de nome e preco.
- Cliente salvo ou reutilizado por telefone.
- Status inicial registrado.
- Evento `order.created` registrado.
- Frontend continua conseguindo enviar o pedido pelo WhatsApp.
