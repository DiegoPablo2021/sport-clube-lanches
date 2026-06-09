# Sport Clube Lanches - Cardapio Digital

Aplicacao web da Fase 1 do projeto Sport Clube Lanches. O objetivo e permitir que o cliente monte o pedido em um cardapio digital e envie a mensagem pronta para o WhatsApp da lanchonete.

## Entrega atual

- Cardapio digital responsivo.
- Categorias e produtos a partir das imagens originais do cardapio.
- Promocoes e combos em destaque.
- Carrinho local.
- Dados do cliente: nome, telefone, entrega/retirada, endereco e bairro.
- Aviso de funcionamento configuravel.
- Taxa de entrega: gratis para Sport Clube 3/4; demais localidades consultar taxa.
- Campo de troco quando a forma de pagamento for dinheiro.
- Geracao de mensagem para WhatsApp.

## Stack

- Angular standalone
- TypeScript
- SCSS
- Angular Signals
- Playwright para verificacoes locais quando necessario

## Estrutura

```text
.
├── docs/                       Documentacao, conceitos e referencias
│   ├── assets/                 Conceitos visuais e artefatos da documentacao
│   └── references/             Materiais originais recebidos
├── public/
│   └── menu-images/            Imagens usadas pela aplicacao
└── src/
    └── app/
        ├── core/               Configuracoes, modelos e servicos de dominio
        ├── data/               Cardapio inicial estatico
        ├── features/           Telas e fluxos principais
        └── shared/             Utilitarios reutilizaveis
```

## Documentacao

- Requirements: `docs/REQUIREMENTS.md`
- Plano e arquitetura: `docs/ARQUITETURA-E-PLANO-DO-PROJETO.md`
- Fase 1: `docs/FASE-1-CARDAPIO-DIGITAL.md`
- Fase 2: `docs/FASE-2-BACKEND-PERSISTENCIA.md`
- WhatsApp Business: `docs/WHATSAPP-BUSINESS.md`
- Observabilidade e KPIs: `docs/OBSERVABILIDADE-KPIS.md`
- PDF original: `docs/references/initial-documentation/Documentação Inicial do Projeto Delivery.pdf`
- Imagens originais do cardapio: `docs/references/menu-images/`

## Comandos

```bash
npm install
npm start
npm run build
```

Servidor local padrao:

```text
http://localhost:4200
```

## Observacao de arquitetura

Esta fase nao possui backend. A evolucao planejada e substituir `src/app/data/menu.data.ts` por chamadas de API, mantendo o contrato de tela e os modelos de dominio.
