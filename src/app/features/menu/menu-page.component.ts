import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CheckoutInfo, PaymentMethod, Product } from '../../core/models/menu.models';
import { businessConfig } from '../../core/config/business.config';
import { CartService } from '../../core/services/cart.service';
import { DeliveryFeeService } from '../../core/services/delivery-fee.service';
import { OrderPersistenceService } from '../../core/services/order-persistence.service';
import { PaymentService } from '../../core/services/payment.service';
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
  private readonly paymentService = inject(PaymentService);
  private readonly pixService = inject(PixService);
  readonly cart = inject(CartService);
  readonly business = businessConfig;
  readonly categories = categories;
  readonly paymentOptions = this.paymentService.options;
  readonly selectedCategoryId = signal(categories[0].id);
  readonly savingOrder = signal(false);
  readonly cartExpanded = signal(false);
  readonly pixQrCodeDataUrl = signal('');
  readonly pixCopyPaste = signal('');
  readonly pixCopyStatus = signal('');
  readonly checkout: CheckoutInfo = {
    name: '',
    phone: '',
    orderType: 'Entrega',
    address: '',
    neighborhood: '',
    paymentMethods: ['Pix'],
    paymentSplit: '',
    pixAmount: '',
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

  readonly shouldShowProductSection = computed(
    () => this.selectedCategoryId() !== 'promocoes',
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

  openCheckout(): void {
    if (this.cart.totalItems() > 0) {
      this.cartExpanded.set(true);
    }
  }

  closeCheckout(): void {
    this.cartExpanded.set(false);
  }

  togglePaymentMethod(method: PaymentMethod, checked: boolean): void {
    if (checked && !this.checkout.paymentMethods.includes(method)) {
      this.checkout.paymentMethods = [...this.checkout.paymentMethods, method];
    }

    if (!checked) {
      this.checkout.paymentMethods = this.checkout.paymentMethods.filter(
        (paymentMethod) => paymentMethod !== method,
      );
    }

    if (!this.hasPaymentMethod('Dinheiro')) {
      this.checkout.changeFor = '';
    }

    void this.refreshPixPayment();
  }

  hasPaymentMethod(method: PaymentMethod): boolean {
    return this.paymentService.hasMethod(this.checkout.paymentMethods, method);
  }

  hasMultiplePaymentMethods(): boolean {
    return this.checkout.paymentMethods.length > 1;
  }

  onOrderTypeChange(): void {
    if (this.checkout.orderType === 'Retirada') {
      this.checkout.address = '';
      this.checkout.neighborhood = '';
    }

    void this.refreshPixPayment();
  }

  async sendOrderToWhatsapp(): Promise<void> {
    if (!this.canSendOrder()) {
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

  getDeliveryFeeAmount(): number {
    return this.checkout.orderType === 'Entrega'
      ? this.deliveryFeeService.getDeliveryFee(this.checkout.neighborhood).amount
      : 0;
  }

  getPaymentFeeAmount(): number {
    return this.paymentService.calculateFee(this.checkout.paymentMethods);
  }

  getOrderTotalAmount(): number {
    if (this.cart.totalItems() === 0) {
      return 0;
    }

    return this.cart.totalAmount() + this.getDeliveryFeeAmount() + this.getPaymentFeeAmount();
  }

  getPixChargeAmount(): number {
    if (!this.hasMultiplePaymentMethods()) {
      return this.getOrderTotalAmount();
    }

    const parsedAmount = this.parseMoney(this.checkout.pixAmount);
    return parsedAmount > 0
      ? Math.min(parsedAmount, this.getOrderTotalAmount())
      : this.getOrderTotalAmount();
  }

  canSendOrder(): boolean {
    return (
      this.cart.totalItems() > 0 &&
      this.checkout.paymentMethods.length > 0 &&
      !this.savingOrder()
    );
  }

  getPaymentFeeNotice(): string {
    if (this.getPaymentFeeAmount() === 0) {
      return 'Sem taxa adicional para Pix ou dinheiro.';
    }

    return `Taxa de cartão: ${this.formatCurrency(this.getPaymentFeeAmount())}.`;
  }

  async copyPixPayload(): Promise<void> {
    if (!this.pixCopyPaste()) {
      return;
    }

    await navigator.clipboard.writeText(this.pixCopyPaste());
    this.pixCopyStatus.set('Código Pix copiado.');
    window.setTimeout(() => this.pixCopyStatus.set(''), 2500);
  }

  async refreshPixPayment(): Promise<void> {
    if (!this.hasPaymentMethod('Pix') || this.cart.totalItems() === 0) {
      this.pixQrCodeDataUrl.set('');
      this.pixCopyPaste.set('');
      return;
    }

    const payload = this.pixService.generatePayload(this.getPixChargeAmount());
    this.pixCopyPaste.set(payload);
    this.pixQrCodeDataUrl.set(
      await this.pixService.generateQrCodeDataUrl(this.getPixChargeAmount()),
    );
  }

  private formatCurrency(value: number): string {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value);
  }

  private parseMoney(value: string): number {
    const normalized = value.replace(/\./g, '').replace(',', '.').replace(/[^\d.]/g, '');
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  trackById(_: number, item: { id: string }): string {
    return item.id;
  }
}
