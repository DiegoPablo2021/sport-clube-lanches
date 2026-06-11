import { Injectable } from '@angular/core';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';
import { CartItem, CheckoutInfo } from '../models/menu.models';
import { DeliveryFeeService } from './delivery-fee.service';

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

  constructor(private readonly deliveryFeeService: DeliveryFeeService) {}

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
      delivery_fee_label:
        checkout.orderType === 'Entrega'
          ? this.deliveryFeeService.getDeliveryFeeNotice(checkout.neighborhood)
          : null,
      payment_method: checkout.paymentMethod || 'A combinar',
      change_for: checkout.paymentMethod === 'Dinheiro' ? checkout.changeFor : null,
      notes: checkout.notes,
      items: items.map((item) => ({
        product_slug: item.product.id,
        quantity: item.quantity,
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
