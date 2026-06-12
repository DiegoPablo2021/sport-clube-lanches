-- Usa uma imagem padrao para todos os hamburgueres enquanto as fotos individuais nao forem produzidas.
update public.products
set
  image_url = '/menu-images/hamburguer-padrao.png',
  updated_at = now()
where slug in (
  'hamburguer-suecia',
  'hamburguer-espanha',
  'hamburguer-alemanha',
  'hamburguer-polonia',
  'hamburguer-finlandia',
  'hamburguer-inglaterra'
);
