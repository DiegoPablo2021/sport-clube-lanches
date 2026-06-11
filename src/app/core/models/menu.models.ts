export interface Category {
  id: string;
  name: string;
  description: string;
  sortOrder: number;
}

export interface Product {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string;
  active: boolean;
  highlight?: boolean;
  tags?: string[];
}

export interface CartItem {
  product: Product;
  quantity: number;
}

export type PaymentMethod = 'Pix' | 'Credito na entrega' | 'Debito na entrega' | 'Dinheiro';

export interface CheckoutInfo {
  name: string;
  phone: string;
  orderType: 'Entrega' | 'Retirada';
  address: string;
  neighborhood: string;
  paymentMethods: PaymentMethod[];
  paymentSplit: string;
  changeFor: string;
  notes: string;
}
