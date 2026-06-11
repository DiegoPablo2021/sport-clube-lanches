import { Injectable } from '@angular/core';
import { businessConfig } from '../config/business.config';
import { CartItem, CheckoutInfo } from '../models/menu.models';
import { DeliveryFeeService } from './delivery-fee.service';
import { PaymentService } from './payment.service';

@Injectable({ providedIn: 'root' })
export class WhatsappService {
  constructor(
    private readonly deliveryFeeService: DeliveryFeeService,
    private readonly paymentService: PaymentService,
  ) {}

  buildOrderMessage(items: CartItem[], checkout: CheckoutInfo): string {
    const products = items
      .map((item) => {
        const subtotal = this.formatCurrency(item.product.price * item.quantity);
        return `- *${item.quantity}x ${item.product.name}* - ${subtotal}`;
      })
      .join('\n');

    const subtotal = items.reduce(
      (amount, item) => amount + item.product.price * item.quantity,
      0,
    );
    const deliveryFee =
      checkout.orderType === 'Entrega'
        ? this.deliveryFeeService.getDeliveryFee(checkout.neighborhood).amount
        : 0;
    const paymentFee = this.paymentService.calculateFee(checkout.paymentMethods);
    const total = subtotal + deliveryFee + paymentFee;

    const changeInfo =
      this.paymentService.hasMethod(checkout.paymentMethods, 'Dinheiro')
        ? [`*Troco para:* ${checkout.changeFor || 'Não informado'}`]
        : [];
    const pixInfo =
      this.paymentService.hasMethod(checkout.paymentMethods, 'Pix')
        ? [`*Chave Pix:* ${businessConfig.pix.key}`, `*Titular Pix:* ${businessConfig.pix.receiverName}`]
        : [];
    const deliveryFeeNotice = this.deliveryFeeService
      .getDeliveryFeeNotice(checkout.neighborhood)
      .replace('Taxa de entrega:', '*Taxa de entrega:*');

    const deliveryInfo =
      checkout.orderType === 'Entrega'
        ? [
            `*Endereço:* ${checkout.address || 'A informar'}`,
            `*Bairro:* ${checkout.neighborhood || 'A informar'}`,
            deliveryFeeNotice,
          ]
        : [`*Retirada no local:* ${businessConfig.address}`];

    return [
      `Olá! Quero fazer um pedido no *${businessConfig.name}*:`,
      '',
      '*Item(ns):*',
      products,
      '',
      `*Subtotal:* ${this.formatCurrency(subtotal)}`,
      `*Taxa de entrega:* ${this.formatCurrency(deliveryFee)}`,
      `*Taxa de cartão:* ${this.formatCurrency(paymentFee)}`,
      `*Total:* ${this.formatCurrency(total)}`,
      '',
      `*Nome:* ${checkout.name || 'A informar'}`,
      `*Telefone:* ${checkout.phone || 'A informar'}`,
      `*Tipo de pedido:* ${checkout.orderType}`,
      ...deliveryInfo,
      `*Forma de pagamento:* ${this.paymentService.formatMethods(checkout.paymentMethods)}`,
      ...pixInfo,
      ...changeInfo,
      `*Observação:* ${checkout.notes || 'Nenhuma'}`,
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
