-- Permite que a API REST do Supabase leia objetos do schema public.
grant usage on schema public to anon, authenticated;

-- Libera leitura das views de analytics para o Streamlit e futuros dashboards.
grant select on
  public.vw_orders_base,
  public.vw_daily_sales,
  public.vw_weekday_sales,
  public.vw_period_sales,
  public.vw_product_sales,
  public.vw_category_sales,
  public.vw_payment_methods,
  public.vw_neighborhood_sales,
  public.vw_order_type_sales,
  public.vw_hourly_sales,
  public.vw_customer_recurrence,
  public.vw_customer_promotion_candidates,
  public.vw_customer_favorite_products,
  public.vw_kpi_snapshot,
  public.vw_order_status_summary,
  public.vw_product_daily_sales,
  public.vw_hour_weekday_heatmap,
  public.vw_basket_summary,
  public.vw_product_pair_sales,
  public.vw_customer_lifecycle,
  public.vw_daily_operational_summary
to anon, authenticated;
