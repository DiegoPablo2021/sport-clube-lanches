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

export interface CheckoutInfo {
  name: string;
  phone: string;
  orderType: 'Entrega' | 'Retirada';
  address: string;
  neighborhood: string;
  paymentMethod: string;
  changeFor: string;
  notes: string;
}
