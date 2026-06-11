# Supabase - Setup da Fase 2

## Objetivo

Preparar o banco para registrar pedidos reais e alimentar dashboards no Streamlit e Power BI.

## Estrutura criada

Migrations:

- `supabase/migrations/0001_core_schema.sql`
- `supabase/migrations/0002_analytics_views.sql`
- `supabase/migrations/0003_public_order_rpc.sql`

Seed inicial:

- `supabase/seed.sql`

O seed agora contem o cardapio completo e e gerado a partir de `src/app/data/menu.data.ts`.

```bash
npm run seed:supabase
```

## Como aplicar

Depois de criar o projeto no Supabase:

1. Abrir o SQL Editor.
2. Executar as migrations em ordem.
3. Executar `supabase/seed.sql` para carregar o catalogo atual.
4. Copiar `Project URL` e `anon public key`.
5. Preencher `src/environments/environment.prod.ts`.
6. Alterar `persistOrders` para `true`.

Quando usarmos Supabase CLI, o fluxo pode virar:

```bash
supabase link --project-ref PROJECT_REF
supabase db push
supabase db seed
```

## Tabelas

- `categories`
- `products`
- `customers`
- `orders`
- `order_items`
- `order_events`

## Registro publico de pedidos

A migration `0003_public_order_rpc.sql` cria a funcao:

```sql
public.create_public_order(payload jsonb)
```

Ela permite criar pedidos a partir do cardapio sem expor inserts diretos nas tabelas. A funcao valida produtos ativos e usa o preco salvo no banco, nao o preco enviado pelo navegador.

Payload esperado:

```json
{
  "customer_name": "Cliente",
  "customer_phone": "(84) 99999-9999",
  "order_type": "Entrega",
  "address": "Rua exemplo, 123",
  "neighborhood": "Sport Clube 3/4",
  "delivery_fee_label": "Taxa de entrega: gratis para Sport Clube 3/4.",
  "payment_method": "Dinheiro",
  "change_for": "Troco para R$ 50,00",
  "notes": "Sem cebola",
  "items": [
    {
      "product_slug": "hamburguer-suecia",
      "quantity": 2
    }
  ]
}
```

## Views para BI

- `vw_orders_base`
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
- `vw_order_status_summary`
- `vw_kpi_snapshot`

## Power BI sem Excel

O Power BI pode consumir o PostgreSQL do Supabase diretamente.

Recomendacao:

- Conectar usando host/porta/usuario/senha do Supabase.
- Preferir as views `vw_*`.
- Evitar conectar direto nas tabelas operacionais para nao misturar regra de negocio no BI.

Indicadores contemplados:

- Dia que mais vende.
- Produto que mais sai.
- Cliente que mais compra.
- Bairro que mais compra.
- Horario de pico.
- Ganho por dia, semana, mes, trimestre, semestre e ano.
- Clientes candidatos a promocao.

## Streamlit

Foi criado um prototipo em:

```text
analytics/streamlit/
```

Para rodar:

```bash
cd analytics/streamlit
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
streamlit run app.py
```

Preencher `SUPABASE_DB_URL` no `.env` com a connection string do Supabase.
