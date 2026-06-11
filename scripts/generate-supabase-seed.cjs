const fs = require('fs');
const path = require('path');
const vm = require('vm');
const ts = require('typescript');

const projectRoot = path.resolve(__dirname, '..');
const sourcePath = path.join(projectRoot, 'src/app/data/menu.data.ts');
let source = fs.readFileSync(sourcePath, 'utf8');
source = source.replace(/^import .*$/gm, '');

const js = ts.transpileModule(source, {
  compilerOptions: {
    module: ts.ModuleKind.CommonJS,
    target: ts.ScriptTarget.ES2022,
  },
}).outputText;

const sandbox = { exports: {}, require };
vm.createContext(sandbox);
vm.runInContext(js, sandbox);

const { categories, products } = sandbox.exports;

const quote = (value) =>
  value == null ? 'null' : `'${String(value).replaceAll("'", "''")}'`;
const bool = (value) => (value ? 'true' : 'false');

const categoryValues = categories
  .map(
    (category) =>
      `  (${quote(category.id)}, ${quote(category.name)}, ${quote(category.description)}, true, ${category.sortOrder})`,
  )
  .join(',\n');

const productValues = products
  .map(
    (product) =>
      `  (${quote(product.id)}, ${quote(product.categoryId)}, ${quote(product.name)}, ${quote(product.description)}, ${product.price.toFixed(2)}, ${quote(product.imageUrl)}, ${bool(product.active)}, ${bool(product.highlight)})`,
  )
  .join(',\n');

const sql = `-- Seed completo gerado a partir de src/app/data/menu.data.ts.
-- Regerar sempre que o cardapio estatico mudar.

with category_seed(slug, name, description, active, sort_order) as (
  values
${categoryValues}
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
${productValues}
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
`;

fs.writeFileSync(path.join(projectRoot, 'supabase/seed.sql'), sql, 'utf8');
console.log(
  `Generated supabase/seed.sql with ${categories.length} categories and ${products.length} products.`,
);
