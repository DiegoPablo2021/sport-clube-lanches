import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CheckoutInfo, Product } from '../../core/models/menu.models';
import { businessConfig } from '../../core/config/business.config';
import { CartService } from '../../core/services/cart.service';
import { DeliveryFeeService } from '../../core/services/delivery-fee.service';
import { OrderPersistenceService } from '../../core/services/order-persistence.service';
import { PixService } from '../../core/services/pix.service';
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
  private readonly orderPersistenceService = inject(OrderPersistenceService);
  private readonly pixService = inject(PixService);
  readonly cart = inject(CartService);
  readonly business = businessConfig;
  readonly categories = categories;
  readonly selectedCategoryId = signal(categories[0].id);
  readonly savingOrder = signal(false);
  readonly pixQrCodeDataUrl = signal('');
  readonly pixCopyPaste = signal('');
  readonly pixCopyStatus = signal('');
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

  addProduct(product: Product): void {
    this.cart.add(product);
    void this.refreshPixPayment();
  }

  decreaseProduct(productId: string): void {
    this.cart.decrease(productId);
    void this.refreshPixPayment();
  }

  onPaymentMethodChange(): void {
    if (this.checkout.paymentMethod !== 'Dinheiro') {
      this.checkout.changeFor = '';
    }

    void this.refreshPixPayment();
  }

  onOrderTypeChange(): void {
    if (this.checkout.orderType === 'Retirada') {
      this.checkout.address = '';
      this.checkout.neighborhood = '';
    }
  }

  async sendOrderToWhatsapp(): Promise<void> {
    if (this.cart.totalItems() === 0 || this.savingOrder()) {
      return;
    }

    this.savingOrder.set(true);

    try {
      const persistedOrder = await this.orderPersistenceService.createOrder(
        this.cart.items(),
        this.checkout,
      );
      const checkout =
        persistedOrder === null
          ? this.checkout
          : {
              ...this.checkout,
              notes: [
                `Pedido #${persistedOrder.order_number} registrado no sistema.`,
                this.checkout.notes,
              ]
                .filter(Boolean)
                .join(' '),
            };
      const url = this.whatsappService.buildOrderUrl(this.cart.items(), checkout);

      window.location.href = url;
    } finally {
      this.savingOrder.set(false);
    }
  }

  getDeliveryFeeNotice(): string {
    return this.deliveryFeeService.getDeliveryFeeNotice(this.checkout.neighborhood);
  }

  async copyPixPayload(): Promise<void> {
    if (!this.pixCopyPaste()) {
      return;
    }

    await navigator.clipboard.writeText(this.pixCopyPaste());
    this.pixCopyStatus.set('Codigo Pix copiado.');
    window.setTimeout(() => this.pixCopyStatus.set(''), 2500);
  }

  private async refreshPixPayment(): Promise<void> {
    if (this.checkout.paymentMethod !== 'Pix' || this.cart.totalItems() === 0) {
      this.pixQrCodeDataUrl.set('');
      this.pixCopyPaste.set('');
      return;
    }

    const payload = this.pixService.generatePayload(this.cart.totalAmount());
    this.pixCopyPaste.set(payload);
    this.pixQrCodeDataUrl.set(await this.pixService.generateQrCodeDataUrl(this.cart.totalAmount()));
  }

  trackById(_: number, item: { id: string }): string {
    return item.id;
  }
}
