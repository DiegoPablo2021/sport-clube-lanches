-- Seed completo gerado a partir de src/app/data/menu.data.ts.
-- Regerar sempre que o cardapio estatico mudar.

with category_seed(slug, name, description, active, sort_order) as (
  values
  ('promocoes', 'Promocoes', 'Combos e ofertas para pedir rapido.', true, 1),
  ('hamburgueres', 'Hamburgueres', 'Sanduiches da casa com nomes de selecoes.', true, 2),
  ('baguetes', 'Baguetes', 'Baguetes recheadas para matar a fome.', true, 3),
  ('hot-dogao', 'Hot Dogao', 'Hot dogs completos e caprichados.', true, 4),
  ('pasteis', 'Pasteis', 'Pasteis tradicionais e especiais.', true, 5),
  ('cuscuz', 'Cuscuz', 'Cuscuz recheado feito na hora.', true, 6),
  ('tapiocas', 'Tapiocas', 'Tapiocas salgadas da casa.', true, 7),
  ('petiscos', 'Petiscos', 'Porcoes e petiscos para compartilhar.', true, 8),
  ('bebidas', 'Bebidas', 'Refrigerantes e sucos.', true, 9)
)
insert into public.categories (slug, name, description, active, sort_order)
select slug, name, description, active, sort_order
from category_seed
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  active = excluded.active,
  sort_order = excluded.sort_order,
  updated_at = now();

with product_seed(slug, category_slug, name, description, price, image_url, active, highlight) as (
  values
  ('combo-completo', 'promocoes', 'Combo Completo', '3 hot dogao Andorra, 2 hamburgueres Suecia, porcao de batata com cheddar e refrigerante 1 litro.', 59.99, '/menu-images/combo-completo-semana.jpeg', true, true),
  ('combo-suecia', 'promocoes', 'Combo Suecia', '3 sanduiches, batata e refrigerante 1 litro.', 39.90, '/menu-images/img01.jpeg', true, true),
  ('promocao-andorra', 'promocoes', 'Promocao 3 Andorra', '3 hot dogao Andorra.', 15.00, '/menu-images/img03.jpeg', true, true),
  ('promocao-espanha', 'promocoes', 'Espanha com fritas', '1 hamburguer Espanha com meia porcao de fritas.', 16.00, '/menu-images/img04.jpeg', true, true),
  ('hamburguer-suecia', 'hamburgueres', 'Suecia', 'Pao, hamburguer, ovo, presunto, requeijao cheddar, alface e tomate.', 8.00, '/menu-images/hamburguer-suecia.png', true, false),
  ('hamburguer-espanha', 'hamburgueres', 'Espanha', 'Pao, hamburguer, mussarela, salsicha, ovo, alface, tomate e molho.', 10.00, '/menu-images/img06.jpeg', true, false),
  ('hamburguer-alemanha', 'hamburgueres', 'Alemanha', 'Pao, hamburguer, frango, ovo, alface, tomate e mussarela.', 12.00, '/menu-images/img06.jpeg', true, false),
  ('hamburguer-polonia', 'hamburgueres', 'Polonia', 'Pao, hamburguer, camarao com catupiry, mussarela, alface e tomate.', 16.00, '/menu-images/img06.jpeg', true, false),
  ('hamburguer-finlandia', 'hamburgueres', 'Finlandia', 'Pao, hamburguer, bacon, ovo, mussarela, presunto, alface, tomate e molho.', 14.00, '/menu-images/img06.jpeg', true, false),
  ('hamburguer-inglaterra', 'hamburgueres', 'Inglaterra', 'Pao de hamburguer, carne de sol desfiada, cebola grelhada, queijo coalho e mussarela.', 14.00, '/menu-images/img06.jpeg', true, false),
  ('baguete-italia', 'baguetes', 'Italia', 'Pao baguete, frango desfiado, cebola grelhada, mussarela, alface, tomate e molho.', 12.00, '/menu-images/baguete-italia.png', true, false),
  ('baguete-monaco', 'baguetes', 'Monaco', 'Pao baguete, frango com catupiry, alface e tomate.', 13.00, '/menu-images/img06.jpeg', true, false),
  ('baguete-portugal', 'baguetes', 'Portugal', 'Pao baguete, salsicha, ovo, mussarela, alface, tomate e molho.', 12.00, '/menu-images/img06.jpeg', true, false),
  ('baguete-croacia', 'baguetes', 'Croacia', 'Pao baguete, calabresa, mussarela, alface, tomate, cebola grelhada e barbecue.', 12.00, '/menu-images/img06.jpeg', true, false),
  ('baguete-prime', 'baguetes', 'Prime', 'Pao baguete, carne de sol na nata, alface e tomate.', 14.00, '/menu-images/baguete-prime.png', true, false),
  ('hotdog-andorra', 'hot-dogao', 'Andorra', 'Frango, carne moida, salsicha, vinagrete, batata palha e queijo ralado.', 7.00, '/menu-images/img07.jpeg', true, false),
  ('hotdog-reino-unido', 'hot-dogao', 'Reino Unido', 'Salsicha, carne de sol na nata, vinagrete e queijo ralado.', 9.00, '/menu-images/img07.jpeg', true, false),
  ('hotdog-estados-unidos', 'hot-dogao', 'Estados Unidos', 'Frango com catupiry, salsicha, vinagrete, batata palha e queijo ralado.', 9.00, '/menu-images/img07.jpeg', true, false),
  ('pastel-belgica', 'pasteis', 'Belgica', 'Carne de sol na nata.', 12.00, '/menu-images/img07.jpeg', true, false),
  ('pastel-russia', 'pasteis', 'Russia', 'Carne moida com mussarela.', 8.00, '/menu-images/img07.jpeg', true, false),
  ('pastel-franca', 'pasteis', 'Franca', 'Frango desfiado com catupiry.', 8.00, '/menu-images/img07.jpeg', true, false),
  ('pastel-suica', 'pasteis', 'Suica', 'Camarao com catupiry.', 12.00, '/menu-images/img07.jpeg', true, false),
  ('pastel-brasil', 'pasteis', 'Brasil', 'Queijo, presunto e oregano.', 5.00, '/menu-images/img07.jpeg', true, false),
  ('pastel-austria', 'pasteis', 'Austria', 'Calabresa, cebola, mussarela e oregano.', 8.00, '/menu-images/img07.jpeg', true, false),
  ('pastel-mexico', 'pasteis', 'Mexico', 'Frango desfiado, mussarela e oregano.', 8.00, '/menu-images/img07.jpeg', true, false),
  ('cuscuz-opcao-1', 'cuscuz', 'Opcao 1', 'Carne de sol na nata com fatias de mussarela.', 15.00, '/menu-images/img08.jpeg', true, false),
  ('cuscuz-opcao-2', 'cuscuz', 'Opcao 2', 'Frango desfiado com requeijao.', 12.00, '/menu-images/img08.jpeg', true, false),
  ('cuscuz-opcao-3', 'cuscuz', 'Opcao 3', 'Calabresa com fatias de mussarela.', 10.00, '/menu-images/img08.jpeg', true, false),
  ('cuscuz-opcao-4', 'cuscuz', 'Opcao 4', 'Salsicha ao molho de tomate.', 10.00, '/menu-images/img08.jpeg', true, false),
  ('tapioca-carne-sol', 'tapiocas', 'Carne de sol na nata', 'Tapioca recheada com carne de sol na nata.', 10.00, '/menu-images/img09.jpeg', true, false),
  ('tapioca-calabresa', 'tapiocas', 'Calabresa com mussarela', 'Tapioca recheada com calabresa e mussarela.', 7.00, '/menu-images/img09.jpeg', true, false),
  ('tapioca-frango', 'tapiocas', 'Frango desfiado com mussarela', 'Tapioca recheada com frango desfiado e mussarela.', 7.00, '/menu-images/img09.jpeg', true, false),
  ('tapioca-queijo-presunto', 'tapiocas', 'Queijo mussarela e presunto', 'Tapioca recheada com queijo mussarela e presunto.', 6.00, '/menu-images/img09.jpeg', true, false),
  ('petisco-camarao', 'petiscos', 'Camarao ao alho e oleo com fritas', 'Petisco com camarao e fritas.', 30.00, '/menu-images/petisco-camarao.png', true, false),
  ('petisco-frango', 'petiscos', 'Frango a passarinho com fritas', 'Petisco de frango com fritas.', 25.00, '/menu-images/img10.jpeg', true, false),
  ('petisco-carne-sol', 'petiscos', 'Carne de sol sertanejo com queijo coalho', 'Petisco de carne de sol com queijo coalho.', 30.00, '/menu-images/petisco-carne-sol.png', true, false),
  ('porcao-macaxeira', 'petiscos', 'Macaxeira 450g', 'Porcao de macaxeira.', 12.00, '/menu-images/porcao-macaxeira.png', true, false),
  ('porcao-fritas', 'petiscos', 'Fritas 450g', 'Porcao de batata frita.', 12.00, '/menu-images/porcao-fritas.png', true, false),
  ('porcao-fritas-cheddar', 'petiscos', 'Fritas com requeijao cheddar 450g', 'Porcao de fritas com cheddar.', 15.00, '/menu-images/porcao-fritas-cheddar.png', true, false),
  ('bebida-guarana-1l', 'bebidas', 'Guarana 1 litro', 'Refrigerante Guarana 1L.', 8.50, '/menu-images/img11.jpeg', true, false),
  ('bebida-pepsi-1l', 'bebidas', 'Pepsi 1 litro', 'Refrigerante Pepsi 1L.', 8.50, '/menu-images/img11.jpeg', true, false),
  ('bebida-coca-350', 'bebidas', 'Coca Cola 350ml', 'Refrigerante Coca Cola lata.', 5.50, '/menu-images/img11.jpeg', true, false),
  ('bebida-guarana-350', 'bebidas', 'Guarana 350ml', 'Refrigerante Guarana lata.', 5.00, '/menu-images/img11.jpeg', true, false),
  ('bebida-fanta-uva-350', 'bebidas', 'Fanta Uva 350ml', 'Refrigerante Fanta Uva lata.', 5.00, '/menu-images/img11.jpeg', true, false),
  ('suco-manga-goiaba', 'bebidas', 'Suco de manga e goiaba 300ml', 'Adicionar leite custa R$ 2,00.', 4.50, '/menu-images/img11.jpeg', true, false),
  ('suco-uva-caja-acerola', 'bebidas', 'Suco de uva, caja e acerola 300ml', 'Adicionar leite custa R$ 2,00.', 5.50, '/menu-images/img11.jpeg', true, false)
)
insert into public.products (slug, category_id, name, description, price, image_url, active, highlight)
select
  product_seed.slug,
  categories.id,
  product_seed.name,
  product_seed.description,
  product_seed.price,
  product_seed.image_url,
  product_seed.active,
  product_seed.highlight
from product_seed
join public.categories on categories.slug = product_seed.category_slug
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  price = excluded.price,
  image_url = excluded.image_url,
  active = excluded.active,
  highlight = excluded.highlight,
  updated_at = now();
