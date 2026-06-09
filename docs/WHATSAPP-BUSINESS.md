# WhatsApp Business - Configuracao Inicial

## Objetivo

Usar o WhatsApp Business como canal principal de atendimento, com o link do cardapio publicado no perfil, na saudacao e em respostas rapidas.

## 1. Perfil comercial

Configurar no aplicativo WhatsApp Business:

- Nome: `Sport Clube Lanches`
- Categoria: `Restaurante` ou `Lanchonete`
- Endereco: `Rua Espanha, 395 - Sport Clube III`
- Telefone: `(84) 92156-4101`
- Instagram: `@esportclubelanches`
- Descricao:

```text
Lanches, pasteis, hamburgueres, hot dogs, tapiocas, cuscuz, combos e bebidas por delivery.
```

## 2. Link do cardapio

Depois do deploy, usar o link publico da Vercel no perfil comercial e nas mensagens.

Exemplo:

```text
Confira nosso cardapio digital:
LINK_DO_CARDAPIO
```

## 3. Mensagem de saudacao

Sugestao:

```text
Ola! Seja bem-vindo ao Sport Clube Lanches.

Confira nosso cardapio digital:
LINK_DO_CARDAPIO

Por la voce escolhe os produtos, informa entrega ou retirada e envia o pedido prontinho aqui no WhatsApp.
```

## 4. Resposta rapida

Atalho:

```text
/cardapio
```

Mensagem:

```text
Segue nosso cardapio digital:
LINK_DO_CARDAPIO

Voce escolhe os produtos, monta o pedido e envia tudo pronto pelo WhatsApp.
```

## 5. Mensagem para pagamento

Como a confirmacao de pagamento ainda sera manual, manter o atendimento humano apos o pedido chegar.

Sugestao:

```text
Pedido recebido! Vamos conferir disponibilidade e forma de pagamento.
```

## 6. Operacao recomendada

1. Cliente chama no WhatsApp.
2. Kardiele/Ryan envia `/cardapio`.
3. Cliente monta pedido no site.
4. Cliente envia mensagem pronta pelo WhatsApp.
5. Kardiele/Ryan confirma pagamento, entrega/retirada e repassa para Leandro.

## 7. Fora do momento atual

- Bot automatico.
- Integracao oficial com WhatsApp Cloud API.
- Pagamento integrado.
- Confirmacao automatica de Pix/cartao.

Esses pontos ficam para fases futuras.
