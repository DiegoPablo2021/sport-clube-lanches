import os
from datetime import date

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


def money(value: float) -> str:
    return f"R$ {value:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


@st.cache_data(ttl=300)
def load_frame(query: str) -> pd.DataFrame:
    with engine.connect() as connection:
        return pd.read_sql(text(query), connection)


daily_sales = load_frame("select * from public.vw_daily_sales order by order_date desc")
period_sales = load_frame("select * from public.vw_period_sales order by period_start desc")
weekday_sales = load_frame("select * from public.vw_weekday_sales")
product_sales = load_frame("select * from public.vw_product_sales limit 10")
neighborhood_sales = load_frame("select * from public.vw_neighborhood_sales limit 10")
payment_methods = load_frame("select * from public.vw_payment_methods")
order_type_sales = load_frame("select * from public.vw_order_type_sales")
hourly_sales = load_frame("select * from public.vw_hourly_sales")
customer_recurrence = load_frame("select * from public.vw_customer_recurrence limit 20")
promotion_candidates = load_frame("select * from public.vw_customer_promotion_candidates limit 20")
favorite_products = load_frame("select * from public.vw_customer_favorite_products")

if daily_sales.empty:
    st.info("Ainda nao ha pedidos registrados.")
    st.stop()

min_date = pd.to_datetime(daily_sales["order_date"]).min().date()
max_date = pd.to_datetime(daily_sales["order_date"]).max().date()
date_range = st.sidebar.date_input(
    "Periodo",
    value=(min_date, max_date),
    min_value=min_date,
    max_value=max_date,
)

if isinstance(date_range, tuple) and len(date_range) == 2:
    start_date, end_date = date_range
else:
    start_date, end_date = min_date, max_date

daily_sales["order_date"] = pd.to_datetime(daily_sales["order_date"]).dt.date
filtered_daily = daily_sales[
    (daily_sales["order_date"] >= start_date) & (daily_sales["order_date"] <= end_date)
]

total_orders = int(filtered_daily["total_orders"].sum())
gross_revenue = float(filtered_daily["gross_revenue"].sum())
average_ticket = gross_revenue / total_orders if total_orders else 0
cancelled_orders = int(filtered_daily["cancelled_orders"].sum())

metric_columns = st.columns(4)
metric_columns[0].metric("Pedidos", total_orders)
metric_columns[1].metric("Faturamento", money(gross_revenue))
metric_columns[2].metric("Ticket medio", money(average_ticket))
metric_columns[3].metric("Cancelados", cancelled_orders)

overview_tab, products_tab, customers_tab, geography_tab, periods_tab = st.tabs(
    ["Visao geral", "Produtos", "Clientes", "Bairros e horarios", "Periodos"]
)

with overview_tab:
    st.subheader("Ganho por dia")
    st.plotly_chart(
        px.line(filtered_daily.sort_values("order_date"), x="order_date", y="gross_revenue", markers=True),
        use_container_width=True,
    )

    left, right = st.columns(2)
    with left:
        st.subheader("Formas de pagamento")
        st.plotly_chart(
            px.pie(payment_methods, names="payment_method", values="total_orders"),
            use_container_width=True,
        )
    with right:
        st.subheader("Entrega vs retirada")
        st.plotly_chart(
            px.pie(order_type_sales, names="order_type", values="total_orders"),
            use_container_width=True,
        )

with products_tab:
    st.subheader("Top produtos")
    st.plotly_chart(
        px.bar(product_sales, x="gross_revenue", y="product_name", orientation="h"),
        use_container_width=True,
    )
    st.dataframe(product_sales, use_container_width=True, hide_index=True)

with customers_tab:
    st.subheader("Clientes que mais compram")
    st.dataframe(customer_recurrence, use_container_width=True, hide_index=True)

    st.subheader("Candidatos a promocao/fidelidade")
    st.dataframe(promotion_candidates, use_container_width=True, hide_index=True)

    st.subheader("Produtos favoritos por cliente")
    st.dataframe(favorite_products, use_container_width=True, hide_index=True)

with geography_tab:
    st.subheader("Bairros")
    st.plotly_chart(
        px.bar(neighborhood_sales, x="total_orders", y="neighborhood", orientation="h"),
        use_container_width=True,
    )

    st.subheader("Horario de pico")
    st.plotly_chart(
        px.bar(hourly_sales, x="order_hour", y="total_orders"),
        use_container_width=True,
    )

    st.subheader("Dias que mais vendem")
    st.plotly_chart(
        px.bar(weekday_sales, x="weekday_name", y="gross_revenue"),
        use_container_width=True,
    )

with periods_tab:
    period_label = st.selectbox(
        "Agrupar por",
        options=["day", "week", "month", "quarter", "semester", "year"],
        format_func={
            "day": "Dia",
            "week": "Semana",
            "month": "Mes",
            "quarter": "Trimestre",
            "semester": "Semestre",
            "year": "Ano",
        }.get,
    )
    selected_period = period_sales[period_sales["period_type"] == period_label].sort_values("period_start")
    st.plotly_chart(
        px.bar(selected_period, x="period_start", y="gross_revenue"),
        use_container_width=True,
    )
    st.dataframe(selected_period, use_container_width=True, hide_index=True)
