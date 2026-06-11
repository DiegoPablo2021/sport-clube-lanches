# Power BI - Sport Clube Lanches

Este diretorio prepara o consumo dos dados do Supabase no Power BI Desktop.

## Fonte recomendada

Conectar diretamente ao PostgreSQL do Supabase, usando as views `public.vw_*`.

Evitar Excel como ponte. Excel pode ser util para testes manuais, mas nao deve ser a fonte oficial do dashboard.

## Grao analitico

- `vw_orders_base`: 1 linha por pedido.
- `vw_product_sales`: agregado por produto.
- `vw_category_sales`: agregado por categoria.
- `vw_daily_sales`: agregado por dia.
- `vw_weekday_sales`: agregado por dia da semana.
- `vw_period_sales`: agregado por periodo calendario.
- `vw_neighborhood_sales`: agregado por bairro.
- `vw_hourly_sales`: agregado por hora.
- `vw_customer_recurrence`: agregado por cliente.
- `vw_customer_promotion_candidates`: agregado por cliente nos ultimos 30 dias.
- `vw_customer_favorite_products`: ate 3 produtos favoritos por cliente.

## Paginas sugeridas

1. Visao geral
   - Faturamento
   - Pedidos
   - Ticket medio
   - Clientes unicos
   - Cancelamentos

2. Vendas
   - Ganho por dia, semana, mes, trimestre, semestre e ano
   - Dia da semana que mais vende
   - Horario de pico

3. Cardapio
   - Produtos mais vendidos
   - Produtos com maior faturamento
   - Categorias mais fortes

4. Clientes
   - Clientes que mais compram
   - Clientes candidatos a promocao
   - Produtos favoritos por cliente

5. Bairros
   - Bairros que mais compram
   - Ticket medio por bairro
   - Entrega vs retirada

## Cuidados de privacidade

Telefone, endereco e historico de compra sao dados pessoais. Para compartilhar prints ou publicar relatorios, mascarar telefone e evitar expor endereco completo.

## Arquivos

- `measures.dax`: medidas base para criar no Power BI.
- `power-query.md`: passo a passo de conexao pelo Power Query.
