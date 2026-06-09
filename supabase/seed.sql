insert into public.categories (name, description, sort_order)
values
  ('Promocoes', 'Combos e ofertas para pedir rapido.', 1),
  ('Hamburgueres', 'Sanduiches da casa com nomes de selecoes.', 2),
  ('Bebidas', 'Refrigerantes e sucos.', 9)
on conflict do nothing;

-- Seed minimo para validar a base.
-- O cardapio completo deve ser migrado de src/app/data/menu.data.ts na Fase 2.
