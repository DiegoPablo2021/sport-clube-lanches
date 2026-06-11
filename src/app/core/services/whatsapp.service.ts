import { Injectable } from '@angular/core';
import { businessConfig } from '../config/business.config';
import { CartItem, CheckoutInfo } from '../models/menu.models';
import { DeliveryFeeService } from './delivery-fee.service';

@Injectable({ providedIn: 'root' })
export class WhatsappService {
  constructor(private readonly deliveryFeeService: DeliveryFeeService) {}

  buildOrderMessage(items: CartItem[], checkout: CheckoutInfo): string {
    const products = items
      .map((item) => {
        const subtotal = this.formatCurrency(item.product.price * item.quantity);
        return `- ${item.quantity}x ${item.product.name} - ${subtotal}`;
      })
      .join('\n');

    const total = items.reduce(
      (amount, item) => amount + item.product.price * item.quantity,
      0,
    );

    const changeInfo =
      checkout.paymentMethod === 'Dinheiro'
        ? [`Troco para: ${checkout.changeFor || 'Nao informado'}`]
        : [];
    const pixInfo =
      checkout.paymentMethod === 'Pix'
        ? [`Chave Pix: ${businessConfig.pix.key}`, `Titular Pix: ${businessConfig.pix.receiverName}`]
        : [];

    const deliveryInfo =
      checkout.orderType === 'Entrega'
        ? [
            `Endereco: ${checkout.address || 'A informar'}`,
            `Bairro: ${checkout.neighborhood || 'A informar'}`,
            this.deliveryFeeService.getDeliveryFeeNotice(checkout.neighborhood),
          ]
        : [`Retirada no local: ${businessConfig.address}`];

    return [
      `Ola! Quero fazer um pedido no ${businessConfig.name}:`,
      '',
      'Itens:',
      products,
      '',
      `Total: ${this.formatCurrency(total)}`,
      '',
      `Nome: ${checkout.name || 'A informar'}`,
      `Telefone: ${checkout.phone || 'A informar'}`,
      `Tipo de pedido: ${checkout.orderType}`,
      ...deliveryInfo,
      `Forma de pagamento: ${checkout.paymentMethod || 'A combinar'}`,
      ...pixInfo,
      ...changeInfo,
      `Observacao: ${checkout.notes || 'Nenhuma'}`,
    ].join('\n');
  }

  buildOrderUrl(items: CartItem[], checkout: CheckoutInfo): string {
    const message = this.buildOrderMessage(items, checkout);
    return `https://wa.me/${businessConfig.whatsappNumber}?text=${encodeURIComponent(message)}`;
  }

  private formatCurrency(value: number): string {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value);
  }
}
