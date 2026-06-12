-- Atualiza as imagens dos sucos individuais no cardapio publicado pelo Supabase.
update public.products
set
  image_url = case slug
    when 'suco-manga-goiaba' then '/menu-images/suco-manga.jpeg'
    when 'suco-uva' then '/menu-images/suco-uva.jpeg'
    when 'suco-caja' then '/menu-images/suco-caja.jpeg'
    when 'suco-acerola' then '/menu-images/suco-acerola.jpeg'
    else image_url
  end,
  updated_at = now()
where slug in (
  'suco-manga-goiaba',
  'suco-uva',
  'suco-caja',
  'suco-acerola'
);
