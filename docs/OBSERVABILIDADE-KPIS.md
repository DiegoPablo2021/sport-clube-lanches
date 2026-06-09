# Observabilidade, Metricas e KPIs

## Objetivo

Criar uma visao simples e confiavel do funcionamento do delivery, sem atrapalhar a operacao familiar.

## Situacao atual

Na Fase 1, o pedido e enviado direto pelo WhatsApp. Isso melhora o atendimento, mas nao cria uma base estruturada de dados.

Portanto, dashboards reais dependem da Fase 2, quando os pedidos forem salvos em banco.

## Fonte dos dados

Fonte recomendada:

```text
Frontend
  -> Backend/API
  -> Supabase PostgreSQL
  -> Views analiticas
  -> Streamlit ou Power BI
```

O Supabase deve ser tratado como a base operacional e analitica inicial. A recomendacao e expor dados ao dashboard por views, nao por exportacoes manuais em Excel.

## Streamlit

Uso recomendado:

- Prototipar rapidamente dashboards.
- Testar indicadores.
- Criar um painel interno simples antes do Power BI.
- Validar com Kardiele/Leandro quais metricas realmente ajudam.

## Power BI

Uso recomendado:

- Painel oficial do estabelecimento.
- Relatorios recorrentes.
- Visao executiva de vendas, produtos e clientes.
- Compartilhamento profissional quando a operacao amadurecer.

Conexao recomendada:

- Conectar o Power BI ao PostgreSQL do Supabase.
- Usar views como `vw_daily_sales`, `vw_product_sales` e `vw_neighborhood_sales`.
- Evitar usar Excel como ponte quando os dados ja estiverem no banco.
- Se a conexao direta exigir configuracoes de rede/SSL, manter Streamlit como painel intermediario ate o ambiente ficar pronto.

## KPIs recomendados

- Pedidos por dia.
- Faturamento diario.
- Faturamento mensal.
- Ticket medio.
- Produtos mais vendidos.
- Categorias mais vendidas.
- Formas de pagamento.
- Entrega vs retirada.
- Bairros com mais pedidos.
- Horarios de pico.
- Pedidos cancelados.
- Clientes recorrentes.

## Primeira versao do dashboard

Para o primeiro Streamlit:

- Filtro por periodo.
- Total de pedidos.
- Faturamento estimado.
- Ticket medio.
- Top 10 produtos.
- Pedidos por bairro.
- Entrega vs retirada.
- Formas de pagamento.

## Cuidados

- Nao conectar dashboards diretamente em tabelas operacionais sem views.
- Evitar expor telefone/endereco em painel publico.
- Criar metricas simples antes de inventar indicadores complexos.
- Registrar cancelamentos para nao distorcer faturamento.
