# Fase 2 - Backend, Persistencia e Base de Dados

## Objetivo

Criar uma base operacional para salvar pedidos, clientes, produtos e eventos do delivery. Essa fase prepara o caminho para admin, dashboards, historico e automacoes.

## Motivacao

Na Fase 1, o pedido e montado no cardapio e enviado ao WhatsApp, mas nao fica salvo em banco. Isso resolve o atendimento inicial, mas ainda nao gera historico confiavel para KPIs.

Na Fase 2, cada pedido deve ser registrado antes ou durante o envio ao WhatsApp.

## Stack sugerida

- Node.js
- TypeScript
- NestJS ou Fastify
- Prisma ou Drizzle
- Supabase PostgreSQL
- Zod para validacao

## Modulos iniciais

```text
delivery-srv-admin/
  src/
    modules/
      categories/
      products/
      customers/
      orders/
      settings/
    shared/
    database/
    server.ts
```

## Entidades principais

### categories

- `id`
- `name`
- `description`
- `active`
- `sort_order`
- `created_at`
- `updated_at`

### products

- `id`
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
  -> frontend envia pedido para API
  -> API cria pedido com status "novo"
  -> API retorna numero do pedido
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

## APIs iniciais

- `GET /categories`
- `GET /products`
- `POST /orders`
- `GET /orders/:id`
- `PATCH /orders/:id/status`

## Dashboard e dados

A Fase 2 e a origem dos dados para Streamlit e Power BI.

Fluxo:

```text
Supabase PostgreSQL
  -> views analiticas
  -> Streamlit para prototipo
  -> Power BI para painel oficial
```

## Views analiticas sugeridas

- `vw_daily_sales`
- `vw_product_sales`
- `vw_payment_methods`
- `vw_neighborhood_sales`
- `vw_order_status_history`
- `vw_customer_recurrence`

## Criterios de pronto

- Pedido salvo em banco.
- Numero de pedido gerado.
- Itens do pedido salvos com snapshot de nome e preco.
- Cliente salvo ou reutilizado por telefone.
- Status inicial registrado.
- Evento `order.created` registrado.
- Frontend continua conseguindo enviar o pedido pelo WhatsApp.
