import { Injectable } from '@angular/core';
import { businessConfig } from '../config/business.config';

export interface DeliveryFeeResult {
  amount: number | null;
  label: string;
}

@Injectable({ providedIn: 'root' })
export class DeliveryFeeService {
  getDeliveryFee(neighborhood: string): DeliveryFeeResult {
    if (this.isFreeDeliveryNeighborhood(neighborhood)) {
      return {
        amount: 0,
        label: 'Taxa de entrega: gratis para Sport Clube 3/4.',
      };
    }

    return {
      amount: null,
      label: 'Taxa de entrega: demais localidades consultar taxa.',
    };
  }

  getDeliveryFeeNotice(neighborhood: string): string {
    if (!neighborhood.trim()) {
      return 'Taxa de entrega: gratis para Sport Clube 3/4; demais localidades consultar taxa.';
    }

    return this.getDeliveryFee(neighborhood).label;
  }

  private isFreeDeliveryNeighborhood(neighborhood: string): boolean {
    const normalized = this.normalize(neighborhood);

    return [
      'sport clube 3',
      'sport clube iii',
      'sport club 3',
      'sport club iii',
      'sport clube 4',
      'sport clube iv',
      'sport club 4',
      'sport club iv',
    ].some((freeNeighborhood) => normalized.includes(freeNeighborhood));
  }

  private normalize(value: string): string {
    return value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .trim();
  }

}
