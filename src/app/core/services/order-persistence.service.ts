import { Injectable } from '@angular/core';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';
import { CartItem, CheckoutInfo } from '../models/menu.models';
import { CartService, MILK_ADDITIONAL_AMOUNT } from './cart.service';
import { DeliveryFeeService } from './delivery-fee.service';
import { PaymentService } from './payment.service';

interface CreateOrderResult {
  order_id: string;
  order_number: number;
  total_amount: number;
}

@Injectable({ providedIn: 'root' })
export class OrderPersistenceService {
  private readonly client: SupabaseClient | null =
    environment.persistOrders && environment.supabaseUrl && environment.supabaseAnonKey
      ? createClient(environment.supabaseUrl, environment.supabaseAnonKey)
      : null;

  constructor(
    private readonly cartService: CartService,
    private readonly deliveryFeeService: DeliveryFeeService,
    private readonly paymentService: PaymentService,
  ) {}

  get enabled(): boolean {
    return this.client !== null;
  }

  async createOrder(
    items: CartItem[],
    checkout: CheckoutInfo,
  ): Promise<CreateOrderResult | null> {
    if (!this.client) {
      return null;
    }

    const payload = {
      customer_name: checkout.name,
      customer_phone: checkout.phone,
      order_type: checkout.orderType,
      address: checkout.orderType === 'Entrega' ? checkout.address : null,
      neighborhood: checkout.orderType === 'Entrega' ? checkout.neighborhood : null,
      delivery_fee_amount:
        checkout.orderType === 'Entrega'
          ? this.deliveryFeeService.getDeliveryFee(checkout.neighborhood).amount
          : 0,
      delivery_fee_label:
        checkout.orderType === 'Entrega'
          ? this.deliveryFeeService.getDeliveryFeeNotice(checkout.neighborhood)
          : null,
      payment_fee_amount: this.paymentService.calculateFee(checkout.paymentMethods),
      payment_method: this.paymentService.formatMethods(checkout.paymentMethods),
      change_for: this.paymentService.hasMethod(checkout.paymentMethods, 'Dinheiro')
        ? checkout.changeFor
        : null,
      notes: [
        checkout.paymentMethods.length > 1
          ? `Divisão do pagamento: ${checkout.paymentSplit || 'Combinar na confirmação'}`
          : '',
        checkout.paymentMethods.length > 1 && this.paymentService.hasMethod(checkout.paymentMethods, 'Pix')
          ? `Valor no Pix: ${checkout.pixAmount || 'Combinar na confirmação'}`
          : '',
        checkout.notes,
      ]
        .filter(Boolean)
        .join(' | '),
      items: items.map((item) => ({
        product_slug: item.product.id,
        quantity: item.quantity,
        options_label: item.options?.withMilk ? 'com leite' : null,
        unit_additional_amount: item.options?.withMilk ? MILK_ADDITIONAL_AMOUNT : 0,
        expected_unit_price: this.cartService.getItemUnitPrice(item),
      })),
    };

    const { data, error } = await this.client.rpc('create_public_order', {
      payload,
    });

    if (error) {
      console.error('Erro ao salvar pedido no Supabase', error);
      return null;
    }

    return Array.isArray(data) && data.length > 0 ? data[0] : null;
  }
}
