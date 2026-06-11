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

## Criar o projeto no Supabase pelo painel

Na tela `New project`:

1. `Organization`
   - Manter `DiegoPablo2021's Org`, como aparece no print.

2. `GitHub (optional)`
   - Pode deixar sem selecionar agora.
   - Esse vinculo e util para fluxos avancados, mas nao e necessario para criar o banco e aplicar as migrations.

3. `Project name`
   - Sugestao:

```text
sport-clube-lanches
```

4. `Database password`
   - Gerar uma senha forte.
   - Guardar em local seguro.
   - Essa senha sera usada futuramente no Power BI/Streamlit para conectar no PostgreSQL.

5. `Region`
   - Escolher a regiao mais proxima.
   - Para o Brasil, normalmente usar uma regiao nas Americas.
   - Se existir `South America/Sao Paulo`, escolher essa. Caso nao apareca, manter `Americas`.

6. `Security`
   - `Enable Data API`: deixar marcado.
   - `Automatically expose new tables`: recomendacao: desmarcar.
   - `Enable automatic RLS`: pode marcar, mas nossas migrations tambem ativam RLS nas tabelas principais.

Recomendacao para este projeto:

```text
Enable Data API: marcado
Automatically expose new tables: desmarcado
Enable automatic RLS: marcado
```

7. Clicar em `Create new project`.
8. Aguardar o Supabase provisionar o banco.

## Aplicar schema e seed pelo SQL Editor

Depois de criar o projeto:

1. Abrir o SQL Editor.
2. Criar uma nova query.
3. Copiar e executar o conteudo de `supabase/migrations/0001_core_schema.sql`.
4. Criar outra query.
5. Copiar e executar `supabase/migrations/0002_analytics_views.sql`.
6. Criar outra query.
7. Copiar e executar `supabase/migrations/0003_public_order_rpc.sql`.
8. Criar outra query.
9. Copiar e executar `supabase/seed.sql`.

Ordem obrigatoria:

```text
0001_core_schema.sql
0002_analytics_views.sql
0003_public_order_rpc.sql
seed.sql
```

## Pegar URL e chave publica

No Supabase:

1. Ir em `Project Settings`.
2. Abrir `API`.
3. Copiar:
   - `Project URL`
   - `anon public`

No projeto Angular:

1. Abrir `src/environments/environment.prod.ts`.
2. Preencher:

```ts
export const environment = {
  production: true,
  supabaseUrl: 'https://SEU-PROJETO.supabase.co',
  supabaseAnonKey: 'SUA_ANON_KEY',
  persistOrders: true,
};
```

3. Rodar build:

```bash
npm run build
```

4. Fazer commit e push.
5. A Vercel fara o deploy automaticamente.

Quando usarmos Supabase CLI, o fluxo pode virar:

```bash
supabase link --project-ref PROJECT_REF
supabase db push
supabase db seed
```

Para usar a CLI, primeiro logar:

```bash
npx supabase login
```

Se preferir token:

```bash
$env:SUPABASE_ACCESS_TOKEN='SEU_TOKEN'
```

Depois:

```bash
npx supabase projects list
npx supabase link --project-ref PROJECT_REF
npx supabase db push
```

## Testar se esta funcionando

No SQL Editor, depois do seed:

```sql
select count(*) from public.categories;
select count(*) from public.products;
```

Esperado:

```text
categories: 9
products: 46
```

Para validar a funcao de pedido:

```sql
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
    "notes": "Pedido de teste",
    "items": [
      {
        "product_slug": "hamburguer-suecia",
        "quantity": 1
      }
    ]
  }'::jsonb
);
```

Depois conferir:

```sql
select * from public.vw_orders_base order by created_at desc limit 10;
select * from public.vw_product_sales;
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
