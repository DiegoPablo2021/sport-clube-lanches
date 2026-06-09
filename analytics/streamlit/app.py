import os

import pandas as pd
import plotly.express as px
import streamlit as st
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

st.set_page_config(page_title="Sport Clube Lanches - KPIs", layout="wide")
st.title("Sport Clube Lanches - KPIs")

database_url = os.getenv("SUPABASE_DB_URL")

if not database_url:
    st.warning("Configure SUPABASE_DB_URL no arquivo .env para carregar dados reais.")
    st.stop()

engine = create_engine(database_url, pool_pre_ping=True)


@st.cache_data(ttl=300)
def load_frame(query: str) -> pd.DataFrame:
    with engine.connect() as connection:
        return pd.read_sql(text(query), connection)


daily_sales = load_frame("select * from public.vw_daily_sales order by order_date desc")
product_sales = load_frame("select * from public.vw_product_sales limit 10")
neighborhood_sales = load_frame("select * from public.vw_neighborhood_sales limit 10")
payment_methods = load_frame("select * from public.vw_payment_methods")
order_type_sales = load_frame("select * from public.vw_order_type_sales")

if daily_sales.empty:
    st.info("Ainda nao ha pedidos registrados.")
    st.stop()

total_orders = int(daily_sales["total_orders"].sum())
gross_revenue = float(daily_sales["gross_revenue"].sum())
average_ticket = gross_revenue / total_orders if total_orders else 0
cancelled_orders = int(daily_sales["cancelled_orders"].sum())

metric_columns = st.columns(4)
metric_columns[0].metric("Pedidos", total_orders)
metric_columns[1].metric("Faturamento", f"R$ {gross_revenue:,.2f}".replace(",", "X").replace(".", ",").replace("X", "."))
metric_columns[2].metric("Ticket medio", f"R$ {average_ticket:,.2f}".replace(",", "X").replace(".", ",").replace("X", "."))
metric_columns[3].metric("Cancelados", cancelled_orders)

st.subheader("Faturamento diario")
st.plotly_chart(
    px.line(daily_sales.sort_values("order_date"), x="order_date", y="gross_revenue", markers=True),
    use_container_width=True,
)

left, right = st.columns(2)

with left:
    st.subheader("Top produtos")
    st.plotly_chart(
        px.bar(product_sales, x="gross_revenue", y="product_name", orientation="h"),
        use_container_width=True,
    )

    st.subheader("Formas de pagamento")
    st.plotly_chart(
        px.pie(payment_methods, names="payment_method", values="total_orders"),
        use_container_width=True,
    )

with right:
    st.subheader("Bairros")
    st.plotly_chart(
        px.bar(neighborhood_sales, x="total_orders", y="neighborhood", orientation="h"),
        use_container_width=True,
    )

    st.subheader("Entrega vs retirada")
    st.plotly_chart(
        px.pie(order_type_sales, names="order_type", values="total_orders"),
        use_container_width=True,
    )
