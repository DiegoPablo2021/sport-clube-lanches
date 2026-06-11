const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFile } = require('child_process');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const printMode = process.env.PRINT_MODE || 'file';
const pollIntervalMs = Number(process.env.POLL_INTERVAL_MS || 5000);
const printerName = process.env.WINDOWS_PRINTER_NAME || '';
const paperColumns = Number(process.env.PAPER_COLUMNS || 32);
const runOnce = process.argv.includes('--once');

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Configure SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY em printer-agent/.env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

function money(value) {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(Number(value || 0));
}

function line(char = '-') {
  return char.repeat(paperColumns);
}

function center(text) {
  const clean = String(text).slice(0, paperColumns);
  const left = Math.max(Math.floor((paperColumns - clean.length) / 2), 0);
  return `${' '.repeat(left)}${clean}`;
}

function formatTicket(order) {
  const createdAt = new Date(order.created_at).toLocaleString('pt-BR');
  const items = Array.isArray(order.items) ? order.items : [];

  return [
    center('SPORT CLUBE LANCHES'),
    center(`PEDIDO #${order.order_number}`),
    line('='),
    `Data: ${createdAt}`,
    `Cliente: ${order.customer_name || 'A informar'}`,
    `Telefone: ${order.customer_phone || 'A informar'}`,
    `Tipo: ${order.order_type}`,
    order.order_type === 'Entrega' ? `Endereco: ${order.address || 'A informar'}` : 'Retirada no local',
    order.order_type === 'Entrega' ? `Bairro: ${order.neighborhood || 'A informar'}` : '',
    order.delivery_fee_label || '',
    line(),
    'ITENS',
    ...items.map((item) => {
      const subtotal = money(item.subtotal);
      return `${item.quantity}x ${item.product_name}\n   ${subtotal}`;
    }),
    line(),
    `Pagamento: ${order.payment_method || 'A combinar'}`,
    order.change_for ? `Troco: ${order.change_for}` : '',
    `Total: ${money(order.total_amount)}`,
    order.notes ? `Obs: ${order.notes}` : '',
    line('='),
    center('BOM TRABALHO, LEANDRO!'),
    '\n\n\n',
  ]
    .filter(Boolean)
    .join(os.EOL);
}

function writeTicketFile(order, ticket) {
  const outDir = path.join(__dirname, '..', 'out');
  fs.mkdirSync(outDir, { recursive: true });
  const filePath = path.join(outDir, `pedido-${order.order_number}.txt`);
  fs.writeFileSync(filePath, ticket, 'utf8');
  return filePath;
}

function printOnWindows(filePath) {
  return new Promise((resolve, reject) => {
    const command = printerName
      ? `Start-Process -FilePath notepad.exe -ArgumentList '/pt', '${filePath}', '${printerName}' -WindowStyle Hidden -Wait`
      : `Start-Process -FilePath notepad.exe -ArgumentList '/p', '${filePath}' -WindowStyle Hidden -Wait`;

    execFile('powershell.exe', ['-NoProfile', '-Command', command], (error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });
}

async function printOrder(order) {
  const ticket = formatTicket(order);
  const filePath = writeTicketFile(order, ticket);

  if (printMode === 'console') {
    console.log(ticket);
  }

  if (printMode === 'file') {
    console.log(`Comanda salva: ${filePath}`);
  }

  if (printMode === 'windows') {
    await printOnWindows(filePath);
    console.log(`Comanda enviada para impressao: pedido #${order.order_number}`);
  }

  const { error } = await supabase.rpc('mark_order_printed', {
    target_order_id: order.order_id,
    printer_name: printerName || printMode,
  });

  if (error) {
    throw error;
  }
}

async function poll() {
  const { data, error } = await supabase.rpc('get_pending_print_orders', {
    limit_count: 10,
  });

  if (error) {
    console.error('Erro ao buscar pedidos pendentes:', error.message);
    return;
  }

  if (!data || data.length === 0) {
    console.log('Nenhum pedido pendente para impressao.');
    return;
  }

  for (const order of data) {
    try {
      await printOrder(order);
    } catch (error) {
      console.error(`Erro ao imprimir pedido #${order.order_number}:`, error.message);
    }
  }
}

async function main() {
  console.log(`Printer agent iniciado em modo "${printMode}".`);
  await poll();

  if (!runOnce) {
    setInterval(poll, pollIntervalMs);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
