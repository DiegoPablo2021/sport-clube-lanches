# Sport Clube Lanches - Arquitetura e Plano do Projeto

## 1. Contexto

O Sport Clube Lanches e um delivery familiar operado dentro de casa. Leandro concentra a cozinha; Kardiele e Ryan recebem pedidos pelo WhatsApp e repassam verbalmente para preparo. Hoje o atendimento depende de conversa manual, envio de imagens soltas do cardapio e confirmacao artesanal de pagamento pela maquininha/app Ton.

O primeiro objetivo nao e automatizar tudo. O objetivo correto para o momento e reduzir atrito no atendimento: o cliente acessa um link, monta o pedido e envia uma mensagem pronta pelo WhatsApp.

## 2. Dor principal

- Nao existe um cardapio digital unico e facil de compartilhar.
- Kardiele e Ryan repetem a mesma explicacao para cada cliente.
- As imagens atuais vendem bem, mas estao dispersas e exigem conversa manual.
- O pedido chega desorganizado, com risco de esquecimento de item, endereco, observacao ou forma de pagamento.
- O pagamento ainda e acompanhado por app/maquininha Ton, sem integracao automatica confiavel para o MVP.

## 3. Principios do produto

- Resolver primeiro o atendimento lento, nao criar um ERP.
- Manter a rotina familiar atual: WhatsApp, conversa humana e comunicacao verbal com Leandro.
- Evitar dependencias operacionais no inicio: impressora, fiscal, bot e pagamento integrado ficam fora da Fase 1.
- Construir com arquitetura preparada para evoluir, sem superdimensionar a primeira entrega.
- Preservar a identidade dos produtos, especialmente os nomes por paises e combos/promocoes.

## 4. MVP recomendado

### Fase 1 - Cardapio digital com WhatsApp

Entregas:

- Aplicacao web responsiva `delivery-web-menu`.
- Lista de categorias e produtos.
- Destaque para promocoes e combos.
- Carrinho local no navegador.
- Campos para nome, telefone, entrega/retirada, endereco, bairro, forma de pagamento, troco quando necessario e observacao.
- Aviso de funcionamento e regra de taxa de entrega.
- Geracao de mensagem pronta para WhatsApp.
- Uso de dados estaticos versionados no frontend.

Fora da Fase 1:

- Login administrativo.
- Banco de dados.
- Bot automatico.
- Confirmacao automatica de pagamento.
- Integracao Ton.
- Impressao de comanda.
- Tela dedicada para cozinha.

### Fase 2 - Backend e persistencia

Entregas:

- API `delivery-srv-admin`.
- Banco Supabase PostgreSQL.
- Cadastro de categorias, produtos e pedidos.
- Pedido salvo antes do redirecionamento para WhatsApp.
- Numero de pedido gerado pelo sistema.

### Fase 3 - Admin simples

Entregas:

- Aplicacao `delivery-web-admin`.
- Login administrativo.
- Cadastro e edicao de produtos.
- Ativar/desativar produtos.
- Gerenciar promocoes.
- Ajustar configuracoes do delivery.

### Fase 4 - Pagamento assistido

Entregas possiveis:

- Registro manual de pagamento.
- Campo para forma de pagamento: dinheiro, Pix ou cartao na entrega.
- Evolucao para link Pix via provedor com API, caso faca sentido operacional.

Observacao: a Ton deve permanecer como processo manual no inicio, pois a operacao atual ja consulta pagamentos pelo app/maquininha. Ela nao aparece como opcao de checkout na Fase 1.

### Fase 5 - Automacao WhatsApp

Entregas possiveis:

- WhatsApp Business Platform ou provedor homologado.
- Respostas automaticas.
- Envio do link do cardapio.
- Consulta de status do pedido.
- Notificacao para Kardiele/Ryan.

## 5. Arquitetura da Fase 1

```text
Cliente
  -> delivery-web-menu
    -> Dados estaticos do cardapio
    -> Carrinho local
    -> Gerador de mensagem
    -> WhatsApp de atendimento
```

Decisao arquitetural:

- Sem backend na Fase 1 para entregar valor rapido.
- Produtos ficam tipados no frontend, em arquivo de dados.
- A estrutura de pastas ja separa dominio, dados, servicos e feature para facilitar migracao futura para API.

## 6. Estrutura geral do repositorio

```text
.
├── docs/                       Documentacao de produto, arquitetura e fases
│   ├── assets/                 Conceitos visuais e artefatos gerados
│   └── references/             Materiais originais usados como referencia
│       ├── initial-documentation/
│       └── menu-images/
├── public/                     Assets publicos usados pela aplicacao
└── src/                        Codigo-fonte Angular
```

Materiais originais:

- PDF recebido inicialmente: `docs/references/initial-documentation/Documentação Inicial do Projeto Delivery.pdf`
- Imagens recebidas do cardapio: `docs/references/menu-images/`
- Copia operacional usada pelo frontend: `public/menu-images/`

## 7. Estrutura de pastas da Fase 1

```text
public/
  menu-images/
src/
  app/
    core/
      config/
      models/
      services/
    data/
    features/
      menu/
    shared/
      pipes/
    app.ts
    app.html
    app.scss
```

## 8. Modelo de dominio inicial

Categoria:

- `id`
- `name`
- `description`
- `sortOrder`

Produto:

- `id`
- `categoryId`
- `name`
- `description`
- `price`
- `imageUrl`
- `active`
- `highlight`
- `tags`

Item do carrinho:

- `product`
- `quantity`

Cliente no checkout local:

- `name`
- `phone`
- `orderType`
- `address`
- `neighborhood`
- `paymentMethod`
- `changeFor`
- `notes`

## 9. Fluxo de pedido da Fase 1

1. Cliente abre o link do cardapio.
2. Escolhe produtos e quantidades.
3. Preenche nome, telefone, tipo de pedido, endereco/bairro se for entrega, forma de pagamento e observacao.
4. Clica em `Enviar pedido no WhatsApp`.
5. O sistema monta uma mensagem padronizada.
6. O WhatsApp abre com a mensagem pronta.
7. Kardiele ou Ryan continuam o atendimento humano.
8. Pagamento e confirmado manualmente pela rotina atual.
9. Pedido e repassado verbalmente para Leandro.

## 10. Padrao da mensagem para WhatsApp

```text
Ola! Quero fazer um pedido no Sport Clube Lanches:

Itens:
- 2x Espanha - R$ 20,00
- 1x Guarana 350ml - R$ 5,00

Total: R$ 25,00

Nome: Diego
Telefone: (84) 99999-9999
Tipo de pedido: Entrega
Endereco: Rua X, numero Y
Bairro: Sport Clube III
Taxa de entrega: gratis para Sport Clube 3/4.
Forma de pagamento: Dinheiro
Troco para: R$ 50,00
Observacao: Sem cebola
```

## 11. Boas praticas adotadas

- TypeScript com modelos explicitos.
- Componentes standalone.
- Servicos dedicados para carrinho e WhatsApp.
- Dados iniciais isolados para futura troca por API.
- Estado local simples com Signals.
- CSS responsivo mobile-first.
- Sem regra de negocio espalhada no template.
- Sem acoplamento da interface com provedor de pagamento.

## 12. Criterios de pronto da Fase 1

- Aplicacao abre em desktop e celular.
- Produtos aparecem agrupados por categoria.
- Promocoes aparecem em destaque.
- Carrinho permite adicionar, remover e alterar quantidade.
- Total e calculado corretamente.
- Botao de WhatsApp so fica util quando ha item no carrinho.
- Mensagem gerada contem itens, total, cliente, telefone, tipo de pedido, endereco/bairro quando for entrega, forma de pagamento, troco quando for dinheiro e observacao.
- Build de producao executa sem erro.

## 13. Riscos e decisoes pendentes

- Precificar entrega: Fase 1 usa taxa gratis para Sport Clube 3/4; demais localidades devem consultar taxa.
- Disponibilidade diaria: alguns produtos podem acabar; na Fase 1 isso exige alteracao no codigo.
- Imagens: as artes atuais funcionam, mas no app sera melhor ter fotos/cards individuais por produto no futuro.
- Pagamento: manter manual ate existir necessidade real de automatizacao.
- WhatsApp: evitar automacao nao oficial no inicio para nao arriscar bloqueio de numero.
