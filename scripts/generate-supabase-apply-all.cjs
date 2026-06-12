const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');
const outputPath = path.join(projectRoot, 'supabase/apply-all.sql');
const inputs = [
  'supabase/migrations/0001_core_schema.sql',
  'supabase/migrations/0002_analytics_views.sql',
  'supabase/migrations/0003_public_order_rpc.sql',
  'supabase/migrations/0004_printing_rpc.sql',
  'supabase/migrations/0005_advanced_kpi_views.sql',
  'supabase/migrations/0006_api_view_grants.sql',
  'supabase/migrations/0007_order_fee_amounts.sql',
  'supabase/migrations/0008_menu_beverages_update.sql',
  'supabase/migrations/0009_menu_product_images.sql',
  'supabase/migrations/0010_juice_product_images.sql',
  'supabase/migrations/0011_split_manga_goiaba_and_soda_images.sql',
  'supabase/seed.sql',
];

const content = inputs
  .map((file) => {
    const absolutePath = path.join(projectRoot, file);
    return [
      `-- ============================================================`,
      `-- ${file}`,
      `-- ============================================================`,
      fs.readFileSync(absolutePath, 'utf8').trim(),
      '',
    ].join('\n');
  })
  .join('\n');

fs.writeFileSync(outputPath, content, 'utf8');
console.log(`Generated ${path.relative(projectRoot, outputPath)} from ${inputs.length} files.`);
