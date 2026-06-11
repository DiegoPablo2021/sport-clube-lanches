import { Injectable } from '@angular/core';
import QRCode from 'qrcode';
import { businessConfig } from '../config/business.config';

@Injectable({ providedIn: 'root' })
export class PixService {
  generatePayload(amount: number): string {
    const pixConfig = businessConfig.pix;
    const merchantAccountInfo = [
      this.field('00', 'br.gov.bcb.pix'),
      this.field('01', pixConfig.key),
      this.field('02', businessConfig.name),
    ].join('');

    const txid = this.normalize(`${pixConfig.txidPrefix}${Date.now()}`).slice(0, 25);
    const additionalData = this.field('05', txid);

    const payload = [
      this.field('00', '01'),
      this.field('26', merchantAccountInfo),
      this.field('52', '0000'),
      this.field('53', '986'),
      amount > 0 ? this.field('54', amount.toFixed(2)) : '',
      this.field('58', 'BR'),
      this.field('59', this.normalize(pixConfig.receiverName).slice(0, 25)),
      this.field('60', this.normalize(pixConfig.city).slice(0, 15)),
      this.field('62', additionalData),
      '6304',
    ].join('');

    return `${payload}${this.crc16(payload)}`;
  }

  async generateQrCodeDataUrl(amount: number): Promise<string> {
    return QRCode.toDataURL(this.generatePayload(amount), {
      errorCorrectionLevel: 'M',
      margin: 1,
      scale: 6,
      color: {
        dark: '#111111',
        light: '#ffffff',
      },
    });
  }

  private field(id: string, value: string): string {
    const normalizedValue = value.trim();
    return `${id}${normalizedValue.length.toString().padStart(2, '0')}${normalizedValue}`;
  }

  private normalize(value: string): string {
    return value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-zA-Z0-9 ]/g, '')
      .trim()
      .toUpperCase();
  }

  private crc16(payload: string): string {
    let crc = 0xffff;

    for (let index = 0; index < payload.length; index += 1) {
      crc ^= payload.charCodeAt(index) << 8;

      for (let bit = 0; bit < 8; bit += 1) {
        crc = (crc & 0x8000) !== 0 ? (crc << 1) ^ 0x1021 : crc << 1;
        crc &= 0xffff;
      }
    }

    return crc.toString(16).toUpperCase().padStart(4, '0');
  }
}
