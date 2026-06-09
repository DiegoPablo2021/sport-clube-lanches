# Fase 1 - Cardapio Digital com WhatsApp

## Objetivo

Entregar uma primeira versao utilizavel do cardapio do Sport Clube Lanches para reduzir o tempo de atendimento no WhatsApp.

## Escopo

Incluido:

- Cardapio publico.
- Categorias.
- Produtos e promocoes.
- Carrinho local.
- Formulario de dados do pedido.
- Telefone do cliente.
- Tipo de pedido: entrega ou retirada.
- Bairro e endereco para entrega.
- Aviso de funcionamento.
- Taxa de entrega: gratis para Sport Clube 3/4; demais localidades consultar taxa.
- Campo de troco quando a forma de pagamento for dinheiro.
- Envio para WhatsApp.

Nao incluido:

- Admin.
- Banco de dados.
- Pagamento integrado.
- Bot WhatsApp.
- Impressora.

## Jornada principal

```text
Cliente recebe link
  -> abre cardapio
  -> adiciona itens
  -> informa dados basicos
  -> envia pedido pronto no WhatsApp
  -> Kardiele/Ryan confirmam
  -> Leandro prepara
```

## Direcao visual

O app deve aproveitar o reconhecimento visual das artes atuais:

- Fundo escuro.
- Acentos verde e magenta.
- Promocoes no topo.
- Cards compactos e legiveis.
- Botao de WhatsApp sempre facil de encontrar.

Conceito visual salvo em:

`docs/assets/fase-1-ui-concept.png`

Materiais originais usados como referencia:

- PDF inicial: `docs/references/initial-documentation/Documentação Inicial do Projeto Delivery.pdf`
- Imagens do cardapio: `docs/references/menu-images/`

Imagens usadas pela aplicacao:

- `public/menu-images/`

## Backlog inicial

- Criar projeto Angular `delivery-web-menu`.
- Copiar imagens atuais para assets publicos.
- Modelar categorias e produtos.
- Criar `CartService`.
- Criar `WhatsAppService`.
- Implementar tela principal do menu.
- Implementar carrinho fixo.
- Implementar checkout simples.
- Validar build.

## Evolucao planejada

Na Fase 2, os dados estaticos de produtos devem ser substituidos por API. A interface publica nao deve precisar conhecer detalhes do banco; ela deve consumir um contrato equivalente ao modelo atual.

## Decisoes atuais de entrega

- O cliente pode escolher `Entrega` ou `Retirada`.
- Para entrega, o checkout solicita endereco e bairro.
- Para retirada, a mensagem informa o endereco do Sport Clube Lanches.
- Sport Clube 3/4 nao paga taxa de entrega.
- Demais localidades devem consultar taxa.
- O horario de funcionamento fica como aviso configuravel em `business.config.ts`.
