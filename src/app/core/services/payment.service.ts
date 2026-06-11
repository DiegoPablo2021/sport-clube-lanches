import { Injectable } from '@angular/core';
import { PaymentMethod } from '../models/menu.models';

export interface PaymentOption {
  method: PaymentMethod;
  label: string;
  fee: number;
  helper: string;
}

@Injectable({ providedIn: 'root' })
export class PaymentService {
  readonly options: PaymentOption[] = [
    {
      method: 'Pix',
      label: 'Pix',
      fee: 0,
      helper: 'QR Code aparece no fechamento.',
    },
    {
      method: 'Credito na entrega',
      label: 'Crédito na entrega',
      fee: 2.5,
      helper: 'Taxa da maquininha: R$ 2,50.',
    },
    {
      method: 'Debito na entrega',
      label: 'Débito na entrega',
      fee: 1.5,
      helper: 'Taxa da maquininha: R$ 1,50.',
    },
    {
      method: 'Dinheiro',
      label: 'Dinheiro',
      fee: 0,
      helper: 'Informe se precisa de troco.',
    },
  ];

  calculateFee(methods: PaymentMethod[]): number {
    return methods.reduce((total, method) => total + this.getOption(method).fee, 0);
  }

  formatMethods(methods: PaymentMethod[]): string {
    const selected: PaymentMethod[] = methods.length > 0 ? methods : ['Pix'];
    return selected.map((method) => this.getOption(method).label).join(' + ');
  }

  hasMethod(methods: PaymentMethod[], method: PaymentMethod): boolean {
    return methods.includes(method);
  }

  getOption(method: PaymentMethod): PaymentOption {
    return this.options.find((option) => option.method === method) ?? this.options[0];
  }
}
