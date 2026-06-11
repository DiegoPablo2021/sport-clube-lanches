-- Atualiza a categoria Bebidas com Pepsi lata e sucos individuais.
with bebida_category as (
  select id
  from public.categories
  where slug = 'bebidas'
),
product_seed(slug, name, description, price, image_url, active, highlight) as (
  values
  ('bebida-pepsi-350', 'Pepsi 350ml', 'Refrigerante Pepsi lata.', 5.50, '/menu-images/img11.jpeg', true, false),
  ('suco-uva', 'Suco de uva 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/img11.jpeg', true, false),
  ('suco-caja', 'Suco de cajá 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/img11.jpeg', true, false),
  ('suco-acerola', 'Suco de acerola 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/img11.jpeg', true, false)
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

-- Desativa o item antigo que foi substituido por sucos individuais.
update public.products
set
  active = false,
  updated_at = now()
where slug = 'suco-uva-caja-acerola';
