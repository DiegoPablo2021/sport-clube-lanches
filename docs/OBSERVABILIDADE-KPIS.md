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
