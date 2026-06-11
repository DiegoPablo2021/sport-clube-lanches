# Impressora de pedidos

## Contexto

Leandro tera uma impressora de pedidos USB/Bluetooth para receber as comandas da cozinha.

Arquivo de referencia:

```text
docs/references/printer/impressora-pedidos-usb-bluetooth.mp4
```

## Decisao arquitetural

A aplicacao publicada na Vercel nao deve depender de impressao USB/Bluetooth direta pelo navegador.

Motivos:

- Navegadores limitam acesso a USB e Bluetooth por seguranca.
- WebUSB e Web Bluetooth variam por dispositivo, sistema operacional e navegador.
- Em celular, a impressao termica via Bluetooth costuma depender de aplicativo/driver do fabricante.
- A cozinha precisa de confiabilidade: pedido salvo, recebido e impresso sem depender de permissao manual toda hora.

## Caminho recomendado

Criar um agente local de impressao na Fase 3.

Fluxo:

```text
Cliente faz pedido
  -> frontend salva no Supabase
  -> pedido fica com status "new" ou "paid"
  -> agente local consulta novos pedidos
  -> agente imprime a comanda
  -> agente marca evento "order.printed"
```

## Opcoes tecnicas

### Opcao A - Agente local em Windows

Indicada se a impressora ficar ligada em um notebook/PC por USB.

Stack possivel:

- Node.js
- `node-thermal-printer`
- ESC/POS
- Supabase Realtime ou polling a cada poucos segundos

Vantagens:

- Mais estavel para USB.
- Melhor controle da impressora.
- Permite reimpressao.

Riscos:

- Precisa manter o computador ligado.
- Precisa configurar driver/porta da impressora.

### Opcao B - App Android/local via Bluetooth

Indicada se a impressora ficar pareada com celular.

Vantagens:

- Mais proximo da rotina atual com celular.
- Nao exige computador ligado.

Riscos:

- Desenvolvimento mobile ou app ponte.
- Bluetooth pode desconectar.
- Menos simples de manter.

### Opcao C - Impressao manual temporaria

Enquanto a Fase 3 nao estiver pronta:

- Kardiele/Ryan recebem o pedido no WhatsApp.
- Confirmam pagamento.
- Imprimem pelo aplicativo da impressora ou passam verbalmente para Leandro.

## Modelo de comanda

Conteudo minimo:

- Numero do pedido.
- Horario.
- Nome do cliente.
- Tipo: entrega ou retirada.
- Bairro/endereco quando entrega.
- Itens e quantidades.
- Observacao.
- Forma de pagamento.
- Troco, quando dinheiro.
- Total.

## Proximo passo tecnico

Identificar:

- Marca e modelo exato da impressora.
- Largura do papel: 58mm ou 80mm.
- Protocolo: ESC/POS ou driver proprietario.
- Onde ela sera usada: celular, notebook ou ambos.
- Se o Bluetooth aparece como porta serial.
