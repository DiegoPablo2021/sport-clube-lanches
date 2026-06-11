# Sport Clube Lanches - Cardapio Digital, Pedidos e Analytics

Aplicacao web criada para apoiar o delivery familiar Sport Clube Lanches, organizando o cardapio, acelerando o atendimento via WhatsApp, registrando pedidos no Supabase e preparando indicadores para tomada de decisao.

## Contexto

O Sport Clube Lanches funciona como delivery familiar. A rotina atual depende fortemente do WhatsApp: o cliente chama, pede cardapio, recebe imagens, monta o pedido em conversa e aguarda confirmacao manual.

Este projeto reduz esse atrito com um fluxo simples:

```text
Cliente acessa o cardapio
  -> escolhe produtos
  -> informa dados de entrega, retirada e pagamento
  -> visualiza Pix/QR Code quando necessario
  -> envia o pedido pronto pelo WhatsApp
  -> pedido pode ser salvo no Supabase
  -> dados alimentam Streamlit, Power BI e impressao local
```

## Links

Producao:

```text
https://delivery-web-menu.vercel.app
```

Repositorio:

```text
https://github.com/DiegoPablo2021/sport-clube-lanches
```

## Funcionalidades

- Cardapio digital responsivo.
- Categorias e produtos organizados.
- Imagens reais dos produtos tratadas e padronizadas.
- Promocoes e combos em destaque.
- Carrinho local.
- Checkout com nome, telefone, entrega/retirada, endereco, bairro e observacao.
- Regra de entrega: Sport Clube 3/4 sem taxa; demais localidades consultar taxa.
- Pagamentos: a combinar, Pix, cartao na entrega e dinheiro.
- QR Code Pix e Pix copia-e-cola.
- Campo de troco quando pagamento for dinheiro.
- Mensagem pronta para WhatsApp.
- Persistencia opcional de pedidos no Supabase.
- Views SQL para KPIs, BI e operacao.
- Dashboard Streamlit em tema dark.
- Preparacao para Power BI.
- Agente local para impressao de comandas.

## Stack

Frontend:

- Angular standalone
- TypeScript
- SCSS
- Angular Signals

Dados:

- Supabase PostgreSQL
- Row Level Security
- SQL views
- RPC functions

Analytics:

- Streamlit
- Pandas
- Plotly
- Power BI Desktop

Operacao:

- WhatsApp
- Agente local Node.js para impressao

Deploy:

- GitHub
- Vercel

## Estrutura

```text
delivery-web-menu/
├── analytics/
│   ├── powerbi/                Apoio para modelo Power BI
│   └── streamlit/              Dashboard operacional
├── docs/                       Documentacao do produto e arquitetura
├── printer-agent/              Agente local para impressao de pedidos
├── public/
│   └── menu-images/            Imagens usadas no cardapio
├── scripts/                    Geradores auxiliares
├── src/
│   ├── app/
│   │   ├── core/               Configuracoes, modelos e servicos
│   │   ├── data/               Cardapio estatico da Fase 1
│   │   ├── features/           Paginas e fluxos
│   │   └── shared/             Pipes e utilitarios
│   └── environments/           Configuracoes por ambiente
├── supabase/
│   ├── migrations/             Schema, funcoes e views
│   ├── apply-all.sql           SQL unico para colar no Supabase
│   ├── seed.sql                Carga do cardapio
│   └── useful-queries.sql      Consultas de teste e operacao
└── vercel.json
```

## Como Rodar o Cardapio

Instalar dependencias:

```bash
npm install
```

Subir em desenvolvimento:

```bash
npm start
```

Abrir:

```text
http://localhost:4200
```

Build de producao:

```bash
npm run build
```

Testes:

```bash
npm run test:ci
```

## Supabase

O Supabase guarda catalogo, clientes, pedidos, itens, eventos e serve como base para analytics e impressao.

### Arquivos

- `supabase/migrations/0001_core_schema.sql`: tabelas principais, indices, triggers e RLS.
- `supabase/migrations/0002_analytics_views.sql`: views basicas de vendas, clientes, bairros, horarios e produtos.
- `supabase/migrations/0003_public_order_rpc.sql`: funcao `create_public_order(payload jsonb)` usada pelo cardapio.
- `supabase/migrations/0004_printing_rpc.sql`: funcoes para buscar pedidos pendentes de impressao e marcar como impresso.
- `supabase/migrations/0005_advanced_kpi_views.sql`: KPIs avancados, ciclo de vida, produtos juntos e mapa dia/hora.
- `supabase/migrations/0006_api_view_grants.sql`: permissoes de leitura das views pela API.
- `supabase/seed.sql`: carga completa do cardapio.
- `supabase/apply-all.sql`: arquivo unico para executar no SQL Editor do Supabase.
- `supabase/useful-queries.sql`: consultas de validacao e operacao.

### Aplicar Banco

No Supabase SQL Editor:

1. Abrir `supabase/apply-all.sql`.
2. Copiar todo o conteudo.
3. Colar no SQL Editor.
4. Clicar em `Run`.

Para regenerar o SQL unico:

```bash
npm run sql:supabase
```

Para regenerar apenas o seed:

```bash
npm run seed:supabase
```

## Persistencia no Frontend

Por padrao, a gravacao de pedidos no Supabase fica desligada para evitar erro antes de configurar as chaves.

Para ativar em producao, preencher `src/environments/environment.prod.ts`:

```ts
export const environment = {
  production: true,
  supabaseUrl: 'https://SEU-PROJETO.supabase.co',
  supabaseAnonKey: 'SUA_CHAVE_PUBLICA',
  persistOrders: true,
};
```

Use chave publica/publishable no frontend. Nunca use `service_role` ou `secret key` dentro do Angular.

## Streamlit

Dashboard operacional em:

```text
analytics/streamlit/app.py
```

Rodar:

```bash
cd analytics/streamlit
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
streamlit run app.py
```

Configurar `analytics/streamlit/.env`:

```env
SUPABASE_URL=https://SEU-PROJETO.supabase.co
SUPABASE_KEY=SUA_CHAVE_PUBLISHABLE_OU_SECRET
```

O arquivo `.env.example` e apenas modelo. A chave real deve ficar em `.env`, que nao deve ser versionado.

KPIs principais:

- Pedidos.
- Faturamento.
- Ticket medio.
- Faturamento do dia.
- Pedidos abertos.
- Cancelamentos.
- Produtos mais vendidos.
- Categorias fortes.
- Bairros com maior demanda.
- Horarios de pico.
- Clientes recorrentes.
- Clientes candidatos a promocao.
- Ciclo de vida dos clientes.
- Produtos que saem juntos.

## Power BI

O modelo esta preparado para Power BI por meio das views `vw_*`.

Recomendacao inicial:

- Usar modo `Importar`.
- Usar as views em vez das tabelas cruas.
- Evitar expor telefone/endereco em telas compartilhadas.

Materiais:

- `analytics/powerbi/README.md`
- `analytics/powerbi/power-query.md`
- `analytics/powerbi/measures.dax`

Observacao: no plano free do Supabase, a conexao direta PostgreSQL pode envolver IPv6 ou validacao SSL. Se o Power BI apresentar erro de certificado, usar Streamlit como painel inicial e retomar Power BI depois com ODBC/gateway/certificado configurado.

## Impressao de Pedidos

O agente local fica em:

```text
printer-agent/
```

Configurar:

```bash
cd printer-agent
npm install
copy .env.example .env
```

Exemplo de `.env`:

```env
SUPABASE_URL=https://SEU-PROJETO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=SUA_SERVICE_ROLE_KEY
PRINT_MODE=file
POLL_INTERVAL_MS=5000
WINDOWS_PRINTER_NAME=
PAPER_COLUMNS=32
```

Modos:

- `file`: gera arquivo `.txt` da comanda em `printer-agent/out/`.
- `console`: imprime no terminal.
- `windows`: envia para a impressora padrao ou para `WINDOWS_PRINTER_NAME`.

Rodar uma vez:

```bash
npm run once
```

Rodar continuamente:

```bash
npm start
```

Use `service_role` apenas no agente local. Nao enviar essa chave para GitHub, Vercel ou frontend.

## Pix

O Pix configurado no cardapio gera QR Code e copia-e-cola no checkout.

Configuracao em:

```text
src/app/core/config/business.config.ts
```

## Deploy

O deploy e automatico pela Vercel a cada push na branch `main`.

Configuracao:

- Build command: `npm run build`
- Output directory: `dist/delivery-web-menu/browser`
- Node.js: `24.x`

## Seguranca

- Nao versionar `.env`.
- Nao usar `service_role` no frontend.
- Chaves reais devem ficar apenas em `.env` local ou ambiente seguro.
- Dados de cliente devem ser tratados com cuidado.
- Evitar expor telefone/endereco em dashboards compartilhados.

## Fluxo Operacional Sugerido

1. Cliente acessa o cardapio.
2. Cliente monta o pedido.
3. Cliente escolhe forma de pagamento.
4. Site abre WhatsApp com pedido formatado.
5. Pedido e salvo no Supabase quando persistencia estiver ativa.
6. Kardiele/Ryan confirmam pagamento/pedido.
7. Leandro recebe a comanda pela rotina local de impressao.
8. Dados alimentam Streamlit e, futuramente, Power BI.

## Status

- Cardapio publicado.
- QR Code Pix implementado.
- Supabase estruturado.
- SQL unico de aplicacao criado.
- Streamlit funcionando via API do Supabase.
- Agente local de impressao criado.
- Power BI preparado, aguardando ajuste de conexao/driver.

## Desenvolvedor

Desenvolvido por:

**Diego Menezes**

- GitHub: `DiegoPablo2021`
- Email: `diegopmenezes@hotmail.com`
- Projeto: Sport Clube Lanches
