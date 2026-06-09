# Requirements - Sport Clube Lanches

## 1. Requisitos de ambiente

Obrigatorio para desenvolvimento local:

- Node.js 24.x ou superior compativel com Angular 22.
- npm 11.x ou superior.
- Navegador moderno para testar o cardapio.

Este projeto nao usa `requirements.txt`, porque nao e um projeto Python. As dependencias ficam em:

- `package.json`
- `package-lock.json`

## 2. Como rodar localmente

Na raiz do projeto Angular:

```bash
cd delivery-web-menu
npm install
npm start
```

Depois abra:

```text
http://localhost:4200
```

Build de producao:

```bash
npm run build
```

## 3. Requisitos funcionais da Fase 1

- Exibir cardapio por categorias.
- Destacar promocoes e combos.
- Permitir adicionar e remover itens do carrinho.
- Calcular subtotal e total do pedido.
- Coletar nome e telefone do cliente.
- Permitir escolha entre entrega e retirada.
- Coletar endereco e bairro quando for entrega.
- Informar taxa de entrega: gratis para Sport Clube 3/4; demais localidades consultar taxa.
- Coletar forma de pagamento.
- Exibir campo de troco quando pagamento for dinheiro.
- Coletar observacao do pedido.
- Gerar mensagem pronta para WhatsApp.

## 4. Requisitos nao funcionais

- Interface mobile-first.
- Layout legivel em celulares pequenos.
- Dados iniciais isolados para futura troca por API.
- Componentes e servicos separados por responsabilidade.
- Build de producao sem erro.
- Sem dependencia de backend na Fase 1.

## 5. Deploy recomendado

Recomendacao inicial: Vercel.

Motivos:

- Suporta deploy de Angular.
- Deploy simples via Git.
- CDN e SSL automaticos.
- Bom caminho para evoluir depois para API/backend separado.

Alternativa equivalente: Netlify.

Tambem suporta Angular e e excelente para sites/apps estaticos. A decisao pode ficar entre Vercel e Netlify conforme a conta que voce preferir usar.

Configuracao esperada:

- Build command: `npm run build`
- Output directory: `dist/delivery-web-menu/browser`

O arquivo `vercel.json` fixa essas configuracoes para evitar divergencia entre ambiente local e deploy.

## 6. Observabilidade, metricas e KPIs

Na Fase 1, ainda nao ha banco de pedidos. Portanto, metricas reais dependem de registrar pedidos em uma base estruturada na Fase 2.

Fluxo recomendado de dados:

```text
Cardapio/checkout
  -> API de pedidos
  -> Supabase PostgreSQL
  -> Views/tabelas analiticas
  -> Power BI ou Streamlit
```

KPIs recomendados:

- Pedidos por dia.
- Faturamento por dia.
- Ticket medio.
- Produtos mais vendidos.
- Categorias mais vendidas.
- Formas de pagamento.
- Entrega vs retirada.
- Bairros com mais pedidos.
- Horarios de pico.
- Pedidos cancelados.

Ferramentas:

- Power BI: melhor para painel de negocio, relatórios recorrentes e visao profissional para o estabelecimento.
- Streamlit: melhor para prototipar rapidamente analises, simular dashboards e validar indicadores com baixo custo tecnico.

Recomendacao:

- Fase 2: salvar pedidos em Supabase PostgreSQL.
- Fase 3: criar views/tabelas de analise para nao conectar dashboard direto em tabelas operacionais cruas.
- Fase 4: usar Power BI para painel oficial.
- Streamlit pode ser usado antes como laboratorio analitico ou painel interno simples.
