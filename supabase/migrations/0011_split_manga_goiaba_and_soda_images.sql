-- Atualiza refrigerantes com imagens individuais e separa manga/goiaba em dois sucos.
with bebida_category as (
  select id
  from public.categories
  where slug = 'bebidas'
),
product_seed(slug, name, description, price, image_url, active, highlight) as (
  values
  ('bebida-guarana-1l', 'Guaraná 1 litro', 'Refrigerante Guaraná 1L.', 8.50, '/menu-images/bebida-guarana-1l.jpeg', true, false),
  ('bebida-pepsi-1l', 'Pepsi 1 litro', 'Refrigerante Pepsi 1L.', 8.50, '/menu-images/bebida-pepsi-1l.jpeg', true, false),
  ('bebida-coca-350', 'Coca Cola sem açúcar 350ml', 'Refrigerante Coca Cola sem açúcar lata.', 5.50, '/menu-images/bebida-coca-cola-sem-acucar-350.jpeg', true, false),
  ('bebida-pepsi-350', 'Pepsi 350ml', 'Refrigerante Pepsi lata.', 5.50, '/menu-images/bebida-pepsi-350.jpeg', true, false),
  ('bebida-guarana-350', 'Guaraná 350ml', 'Refrigerante Guaraná lata.', 5.00, '/menu-images/bebida-guarana-350.jpeg', true, false),
  ('bebida-fanta-uva-350', 'Fanta Uva 350ml', 'Refrigerante Fanta Uva lata.', 5.00, '/menu-images/bebida-fanta-uva-350.jpeg', true, false),
  ('suco-manga', 'Suco de manga 300ml', 'Adicionar leite custa R$ 2,00.', 4.50, '/menu-images/suco-manga.jpeg', true, false),
  ('suco-goiaba', 'Suco de goiaba 300ml', 'Adicionar leite custa R$ 2,00.', 4.50, '/menu-images/suco-goiaba.jpeg', true, false)
)
insert into public.products (slug, category_id, name, description, price, image_url, active, highlight)
select
  product_seed.slug,
  bebida_category.id,
  product_seed.name,
  product_seed.description,
  product_seed.price,
  product_seed.image_url,
  product_seed.active,
  product_seed.highlight
from product_seed
cross join bebida_category
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  price = excluded.price,
  image_url = excluded.image_url,
  active = excluded.active,
  highlight = excluded.highlight,
  updated_at = now();

-- O antigo item combinado deixa de aparecer no cardápio.
update public.products
set
  active = false,
  updated_at = now()
where slug = 'suco-manga-goiaba';
