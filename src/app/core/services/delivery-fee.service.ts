import { Injectable } from '@angular/core';
export interface DeliveryFeeResult {
  amount: number;
  label: string;
}

@Injectable({ providedIn: 'root' })
export class DeliveryFeeService {
  getDeliveryFee(neighborhood: string): DeliveryFeeResult {
    if (this.isFreeDeliveryNeighborhood(neighborhood)) {
      return {
        amount: 0,
        label: 'Taxa de entrega: grátis para Sport Clube 3/4.',
      };
    }

    if (this.isReducedDeliveryNeighborhood(neighborhood)) {
      return {
        amount: 3,
        label: 'Taxa de entrega: R$ 3,00 para Sport Clube 1, 2, 5, 6 e Sport Clube Natureza.',
      };
    }

    return {
      amount: 5,
      label: 'Taxa de entrega: R$ 5,00 para demais localidades.',
    };
  }

  getDeliveryFeeNotice(neighborhood: string): string {
    if (!neighborhood.trim()) {
      return 'Taxa de entrega: Sport Clube 3/4 grátis; Sport Clube 1, 2, 5, 6 e Natureza R$ 3,00; demais localidades R$ 5,00.';
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

  private isReducedDeliveryNeighborhood(neighborhood: string): boolean {
    const normalized = this.normalize(neighborhood);

    return [
      'sport clube 1',
      'sport clube i',
      'sport club 1',
      'sport club i',
      'sport clube 2',
      'sport clube ii',
      'sport club 2',
      'sport club ii',
      'sport clube 5',
      'sport clube v',
      'sport club 5',
      'sport club v',
      'sport clube 6',
      'sport clube vi',
      'sport club 6',
      'sport club vi',
      'sport clube natureza',
      'sport club natureza',
    ].some((reducedNeighborhood) => normalized.includes(reducedNeighborhood));
  }

  private normalize(value: string): string {
    return value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .trim();
  }
}
