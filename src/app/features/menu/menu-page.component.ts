import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CheckoutInfo } from '../../core/models/menu.models';
import { businessConfig } from '../../core/config/business.config';
import { CartService } from '../../core/services/cart.service';
import { DeliveryFeeService } from '../../core/services/delivery-fee.service';
import { WhatsappService } from '../../core/services/whatsapp.service';
import { categories, products } from '../../data/menu.data';
import { BrlCurrencyPipe } from '../../shared/pipes/brl-currency.pipe';

@Component({
  selector: 'app-menu-page',
  standalone: true,
  imports: [CommonModule, FormsModule, BrlCurrencyPipe],
  templateUrl: './menu-page.component.html',
  styleUrl: './menu-page.component.scss',
})
export class MenuPageComponent {
  private readonly whatsappService = inject(WhatsappService);
  private readonly deliveryFeeService = inject(DeliveryFeeService);
  readonly cart = inject(CartService);
  readonly business = businessConfig;
  readonly categories = categories;
  readonly selectedCategoryId = signal(categories[0].id);
  readonly checkout: CheckoutInfo = {
    name: '',
    phone: '',
    orderType: 'Entrega',
    address: '',
    neighborhood: '',
    paymentMethod: '',
    changeFor: '',
    notes: '',
  };

  readonly highlightedProducts = computed(() =>
    products.filter((product) => product.active && product.highlight),
  );

  readonly visibleProducts = computed(() =>
    products.filter(
      (product) =>
        product.active && product.categoryId === this.selectedCategoryId(),
    ),
  );

  readonly selectedCategory = computed(() =>
    categories.find((category) => category.id === this.selectedCategoryId()),
  );

  selectCategory(categoryId: string): void {
    this.selectedCategoryId.set(categoryId);
  }

  onPaymentMethodChange(): void {
    if (this.checkout.paymentMethod !== 'Dinheiro') {
      this.checkout.changeFor = '';
    }
  }

  onOrderTypeChange(): void {
    if (this.checkout.orderType === 'Retirada') {
      this.checkout.address = '';
      this.checkout.neighborhood = '';
    }
  }

  createWhatsappUrl(): string {
    return this.whatsappService.buildOrderUrl(this.cart.items(), this.checkout);
  }

  getDeliveryFeeNotice(): string {
    return this.deliveryFeeService.getDeliveryFeeNotice(this.checkout.neighborhood);
  }

  trackById(_: number, item: { id: string }): string {
    return item.id;
  }
}
