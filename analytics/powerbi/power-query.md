# Conexao Power BI com Supabase

## 1. Obter dados do Supabase

No Supabase:

1. Abrir o projeto.
2. Ir em `Project Settings > Database`.
3. Copiar host, database, port, user e password.
4. Preferir a conexao com pooler quando o relatorio crescer.

## 2. Conectar no Power BI Desktop

No Power BI Desktop:

1. `Obter dados > PostgreSQL database`.
2. Informar servidor e banco.
3. Usar modo `Import` no inicio.
4. Selecionar somente as views `public.vw_*`.

## 3. Views iniciais

Carregar:

- `vw_orders_base`
- `vw_daily_sales`
- `vw_weekday_sales`
- `vw_period_sales`
- `vw_product_sales`
- `vw_category_sales`
- `vw_neighborhood_sales`
- `vw_hourly_sales`
- `vw_customer_recurrence`
- `vw_customer_promotion_candidates`
- `vw_customer_favorite_products`

## 4. Recomendacao de modelo

Para o primeiro painel, usar as views agregadas acelera a entrega.

Quando o volume crescer, evoluir para modelo estrela:

- Fato: `orders`, `order_items`
- Dimensoes: `customers`, `products`, `categories`, `date`

## 5. Atualizacao

Enquanto o delivery for pequeno, atualizacao manual no Power BI Desktop atende.

Quando publicar no Power BI Service, configurar gateway ou conexao cloud conforme o modo de acesso escolhido no Supabase.
