-- Atualiza imagens especificas do cardapio depois da entrada de novas fotos.
update public.products
set
  image_url = '/menu-images/hot-dogao.jpeg',
  updated_at = now()
where slug in (
  'hotdog-andorra',
  'hotdog-reino-unido',
  'hotdog-estados-unidos'
);

-- Usa a mesma foto base de pastel em todos os sabores.
update public.products
set
  image_url = '/menu-images/pastel.jpeg',
  updated_at = now()
where slug in (
  'pastel-belgica',
  'pastel-russia',
  'pastel-franca',
  'pastel-suica',
  'pastel-brasil',
  'pastel-austria',
  'pastel-mexico'
);

-- Aplica a foto nova do petisco de frango.
update public.products
set
  image_url = '/menu-images/frango-a-passarinho-com-fritas.jpeg',
  updated_at = now()
where slug = 'petisco-frango';
