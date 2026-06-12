import { computed, Injectable, signal } from '@angular/core';
import { CartItem, Product } from '../models/menu.models';

export const MILK_ADDITIONAL_AMOUNT = 2;

@Injectable({ providedIn: 'root' })
export class CartService {
  private readonly itemsState = signal<CartItem[]>([]);

  readonly items = this.itemsState.asReadonly();
  readonly totalItems = computed(() =>
    this.itemsState().reduce((total, item) => total + item.quantity, 0),
  );
  readonly totalAmount = computed(() =>
    this.itemsState().reduce(
      (total, item) => total + this.getItemSubtotal(item),
      0,
    ),
  );

  add(product: Product): void {
    this.itemsState.update((items) => {
      const existing = items.find((item) => item.product.id === product.id);

      if (!existing) {
        return [...items, { product, quantity: 1 }];
      }

      return items.map((item) =>
        item.product.id === product.id
          ? { ...item, quantity: item.quantity + 1 }
          : item,
      );
    });
  }

  decrease(productId: string): void {
    this.itemsState.update((items) =>
      items
        .map((item) =>
          item.product.id === productId
            ? { ...item, quantity: item.quantity - 1 }
            : item,
        )
        .filter((item) => item.quantity > 0),
    );
  }

  toggleMilk(productId: string, withMilk: boolean): void {
    this.itemsState.update((items) =>
      items.map((item) =>
        item.product.id === productId
          ? { ...item, options: { ...item.options, withMilk } }
          : item,
      ),
    );
  }

  getItemUnitPrice(item: CartItem): number {
    return item.product.price + (item.options?.withMilk ? MILK_ADDITIONAL_AMOUNT : 0);
  }

  getItemSubtotal(item: CartItem): number {
    return this.getItemUnitPrice(item) * item.quantity;
  }

  remove(productId: string): void {
    this.itemsState.update((items) =>
      items.filter((item) => item.product.id !== productId),
    );
  }

  clear(): void {
    this.itemsState.set([]);
  }
}
