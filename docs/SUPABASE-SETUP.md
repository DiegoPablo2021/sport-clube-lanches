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

## Como aplicar

Depois de criar o projeto no Supabase:

1. Abrir o SQL Editor.
2. Executar as migrations em ordem.
3. Executar `supabase/seed.sql` apenas para teste inicial.

Quando usarmos Supabase CLI, o fluxo pode virar:

```bash
supabase link --project-ref PROJECT_REF
supabase db push
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

## Views para BI

- `vw_orders_base`
- `vw_daily_sales`
- `vw_product_sales`
- `vw_category_sales`
- `vw_payment_methods`
- `vw_neighborhood_sales`
- `vw_order_type_sales`
- `vw_hourly_sales`
- `vw_customer_recurrence`
- `vw_order_status_summary`

## Power BI sem Excel

O Power BI pode consumir o PostgreSQL do Supabase diretamente.

Recomendacao:

- Conectar usando host/porta/usuario/senha do Supabase.
- Preferir as views `vw_*`.
- Evitar conectar direto nas tabelas operacionais para nao misturar regra de negocio no BI.

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
