# Sport Clube Lanches - Cardapio Digital e Delivery

Aplicacao web para organizar o cardapio, acelerar o atendimento via WhatsApp e preparar a base de dados do Sport Clube Lanches para gestao, historico de clientes e dashboards.

## Visao geral

O Sport Clube Lanches e um delivery familiar. A primeira dor resolvida pelo projeto e substituir o atendimento manual por imagens soltas no WhatsApp por um fluxo mais organizado:

```text
Cliente acessa o cardapio
  -> escolhe produtos
  -> informa entrega/retirada e pagamento
  -> envia pedido pronto pelo WhatsApp
```

A evolucao planejada adiciona backend, Supabase, Streamlit e Power BI para transformar pedidos em historico e inteligencia de negocio.

## URL de producao

```text
https://delivery-web-menu.vercel.app
```

## Repositorio

```text
https://github.com/DiegoPablo2021/sport-clube-lanches
```

## Funcionalidades atuais

- Cardapio digital responsivo.
- Categorias e produtos cadastrados a partir das artes originais.
- Fotos reais adicionais extraidas de `docs/references/menu-images/mais-fotos/Mais fotos.docx`.
- Promocoes e combos em destaque.
- Carrinho local.
- Dados do cliente: nome e telefone.
- Tipo de pedido: entrega ou retirada.
- Endereco e bairro para entrega.
- Retirada no local com endereco da lanchonete.
- Taxa de entrega: gratis para Sport Clube 3/4; demais localidades consultar taxa.
- Forma de pagamento: a combinar, Pix, cartao na entrega ou dinheiro.
- QR Code e Pix copia-e-cola quando pagamento for Pix.
- Campo de troco quando pagamento for dinheiro.
- Observacao livre do pedido.
- Geracao de mensagem pronta para WhatsApp.
- Persistencia opcional de pedidos no Supabase antes de abrir o WhatsApp.

## Stack

Frontend:

- Angular standalone
- TypeScript
- SCSS
- Angular Signals

Deploy:

- GitHub
- Vercel

Dados e BI:

- Supabase PostgreSQL
- SQL views para KPIs
- Streamlit para prototipo de dashboard
- Power BI para painel oficial futuro

## Estrutura do projeto

```text
.
├── analytics/
│   └── streamlit/              Dashboard inicial em Streamlit
├── docs/                       Documentacao, arquitetura e operacao
├── public/
│   └── menu-images/            Imagens usadas pela aplicacao
├── printer-agent/              Agente local para imprimir comandas
├── src/
│   └── app/
│       ├── core/               Configuracoes, modelos e servicos
│       ├── data/               Cardapio estatico da Fase 1
│       ├── features/           Telas e fluxos
│       └── shared/             Utilitarios reutilizaveis
├── supabase/
│   ├── migrations/             Schema, funcoes e views analiticas
│   ├── apply-all.sql           SQL unico para colar no Supabase
│   └── seed.sql                Seed completo do cardapio
└── vercel.json                 Configuracao de deploy
```

## Como rodar localmente

```bash
npm install
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
npm test
```

## Deploy

O projeto esta conectado ao GitHub na Vercel. Pushes na branch `main` disparam deploy automatico.

Configuracao:

- Build command: `npm run build`
- Output directory: `dist/delivery-web-menu/browser`
- Node.js: `24.x`

## Supabase

A Fase 2 prepara o banco para salvar pedidos reais.

Migrations:

- `supabase/migrations/0001_core_schema.sql`
- `supabase/migrations/0002_analytics_views.sql`
- `supabase/migrations/0003_public_order_rpc.sql`
- `supabase/migrations/0004_printing_rpc.sql`
- `supabase/migrations/0005_advanced_kpi_views.sql`
- `supabase/seed.sql`
- `supabase/apply-all.sql`
- `supabase/useful-queries.sql`

Tabelas principais:

- `categories`
- `products`
- `customers`
- `orders`
- `order_items`
- `order_events`

Funcao publica para criacao de pedido:

```sql
public.create_public_order(payload jsonb)
```

Essa funcao valida produtos ativos e usa os precos do banco, evitando confiar em preco enviado pelo navegador.

Para regenerar o seed do catalogo a partir do cardapio Angular:

```bash
npm run seed:supabase
```

Para ativar a gravacao de pedidos no frontend, preencher `src/environments/environment.prod.ts` com:

```ts
supabaseUrl: 'https://SEU-PROJETO.supabase.co',
supabaseAnonKey: 'SUA_ANON_KEY',
persistOrders: true,
```

## DataViz, KPIs e BI

O projeto foi preparado para responder perguntas como:

- Qual dia vende mais?
- Qual produto mais sai?
- Qual cliente compra mais?
- Qual bairro compra mais?
- Qual e o horario de pico?
- Qual o ganho por dia, semana, mes, trimestre, semestre e ano?
- Quais clientes podem receber promocao por recorrencia?
- Quais produtos favoritos de cada cliente podem orientar promocoes?

Views analiticas:

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
- `vw_product_daily_sales`
- `vw_hour_weekday_heatmap`
- `vw_basket_summary`
- `vw_product_pair_sales`
- `vw_customer_lifecycle`
- `vw_daily_operational_summary`
- `vw_order_status_summary`
- `vw_kpi_snapshot`

## Streamlit

Dashboard inicial:

```text
analytics/streamlit/app.py
```

O app usa tema dark alinhado ao cardapio e cobre KPIs operacionais, produtos, clientes, bairros, horarios e sugestoes de promocao.

Como rodar:

```bash
cd analytics/streamlit
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
streamlit run app.py
```

Configurar no `.env`:

```text
SUPABASE_URL=https://SEU-PROJETO.supabase.co
SUPABASE_KEY=SUA_CHAVE_ANON_OU_SECRET
```

## Power BI

O Power BI deve consumir o PostgreSQL do Supabase diretamente, sem Excel como ponte.

Recomendacao:

- Conectar o Power BI ao Supabase PostgreSQL.
- Usar as views `vw_*`.
- Evitar conectar diretamente nas tabelas operacionais.
- Preservar dados sensiveis de cliente, como telefone e endereco.

Materiais de apoio:

- `analytics/powerbi/README.md`
- `analytics/powerbi/power-query.md`
- `analytics/powerbi/measures.dax`

## Impressora de pedidos

O projeto inclui um agente local em `printer-agent/` para consultar pedidos no Supabase e imprimir comandas na cozinha.

## Documentacao

- Requirements: `docs/REQUIREMENTS.md`
- Arquitetura: `docs/ARQUITETURA-E-PLANO-DO-PROJETO.md`
- Fase 1: `docs/FASE-1-CARDAPIO-DIGITAL.md`
- Fase 2: `docs/FASE-2-BACKEND-PERSISTENCIA.md`
- WhatsApp Business: `docs/WHATSAPP-BUSINESS.md`
- Observabilidade e KPIs: `docs/OBSERVABILIDADE-KPIS.md`

## Status atual

- Fase 1 publicada.
- GitHub conectado a Vercel.
- Base Supabase versionada em SQL.
- Frontend preparado para persistencia opcional no Supabase.
- SQL unico `supabase/apply-all.sql` preparado para execucao no Supabase.
- Agente local de impressao criado em `printer-agent/`.
- Streamlit inicial criado.
- Views de BI preparadas.
- Power BI Desktop documentado.
- Proximo passo: logar no Supabase, criar o projeto real, aplicar migrations, rodar seed e preencher as chaves do ambiente.

## Desenvolvedor

Desenvolvido por:

**Diego Menezes**

- GitHub: `DiegoPablo2021`
- Email: `diegopmenezes@hotmail.com`
- Projeto: Sport Clube Lanches
