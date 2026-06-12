-- Adiciona novo combo da categoria Promocoes.
-- Combo: 3 hamburgueres Suecia, 2 pasteis Brasil, batata com cheddar e refrigerante 1 litro.
insert into public.products (
  slug,
  category_id,
  name,
  description,
  price,
  image_url,
  active,
  highlight
)
select
  'combo-completo-especial',
  c.id,
  'Combo Completo Especial',
  '3 hamburgueres Suecia, 2 pasteis Brasil, porcao de batata com cheddar e refrigerante 1 litro.',
  52.99,
  '/menu-images/combo-completo-especial.jpeg',
  true,
  true
from public.categories c
where c.slug = 'promocoes'
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  price = excluded.price,
  image_url = excluded.image_url,
  active = excluded.active,
  highlight = excluded.highlight,
  updated_at = now();
