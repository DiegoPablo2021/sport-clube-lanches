import os
from datetime import date, timedelta

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

GREEN = "#36f16a"
YELLOW = "#ffcc4d"
PINK = "#ff4f8b"
BG = "#0a0a0a"
SURFACE = "#151515"
TEXT = "#f7f7f7"
MUTED = "#a5a5a5"

st.set_page_config(
    page_title="Sport Clube Lanches - Dashboard",
    page_icon="🍔",
    layout="wide",
)

st.markdown(
    f"""
    <style>
      .stApp {{
        background: {BG};
        color: {TEXT};
      }}
      [data-testid="stSidebar"] {{
        background: #111;
      }}
      .block-container {{
        padding-top: 2rem;
      }}
      .dashboard-title {{
        color: {TEXT};
        font-size: 2.4rem;
        font-weight: 900;
        line-height: 1;
        margin-bottom: .25rem;
      }}
      .dashboard-subtitle {{
        color: {MUTED};
        margin-bottom: 1.25rem;
      }}
      div[data-testid="stMetric"] {{
        background: {SURFACE};
        border: 1px solid #2a2a2a;
        border-radius: 8px;
        padding: 14px 16px;
      }}
      div[data-testid="stMetricLabel"] p {{
        color: {MUTED};
        font-weight: 700;
      }}
      div[data-testid="stMetricValue"] {{
        color: {GREEN};
      }}
      .section-caption {{
        color: {YELLOW};
        font-weight: 800;
        text-transform: uppercase;
        font-size: .78rem;
      }}
    </style>
    """,
    unsafe_allow_html=True,
)

database_url = os.getenv("SUPABASE_DB_URL")

if not database_url:
    st.warning("Configure SUPABASE_DB_URL no arquivo analytics/streamlit/.env para carregar dados reais.")
    st.stop()

engine = create_engine(database_url, pool_pre_ping=True)


def money(value: float) -> str:
    return f"R$ {float(value or 0):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


def empty_frame(columns: list[str]) -> pd.DataFrame:
    return pd.DataFrame(columns=columns)


@st.cache_data(ttl=300)
def load_frame(query: str, columns: tuple[str, ...]) -> pd.DataFrame:
    try:
        with engine.connect() as connection:
            return pd.read_sql(text(query), connection)
    except Exception as exc:
        st.error(f"Erro ao carregar dados: {exc}")
        return empty_frame(list(columns))


def chart_layout(fig: go.Figure) -> go.Figure:
    fig.update_layout(
        paper_bgcolor=BG,
        plot_bgcolor=BG,
        font_color=TEXT,
        margin=dict(l=10, r=10, t=36, b=10),
        legend=dict(bgcolor="rgba(0,0,0,0)"),
    )
    fig.update_xaxes(gridcolor="#242424", zerolinecolor="#242424")
    fig.update_yaxes(gridcolor="#242424", zerolinecolor="#242424")
    return fig


daily_sales = load_frame(
    "select * from public.vw_daily_sales order by order_date desc",
    ("order_date", "total_orders", "cancelled_orders", "gross_revenue", "average_ticket"),
)
period_sales = load_frame(
    "select * from public.vw_period_sales order by period_start desc",
    ("period_type", "period_start", "total_orders", "gross_revenue", "average_ticket"),
)
weekday_sales = load_frame(
    "select * from public.vw_weekday_sales",
    ("weekday_number", "weekday_name", "total_orders", "gross_revenue", "average_ticket"),
)
product_sales = load_frame(
    "select * from public.vw_product_sales limit 15",
    ("product_id", "product_name", "quantity_sold", "gross_revenue", "orders_count"),
)
category_sales = load_frame(
    "select * from public.vw_category_sales",
    ("category_id", "category_name", "quantity_sold", "gross_revenue", "orders_count"),
)
neighborhood_sales = load_frame(
    "select * from public.vw_neighborhood_sales limit 15",
    ("neighborhood", "total_orders", "gross_revenue", "average_ticket"),
)
payment_methods = load_frame(
    "select * from public.vw_payment_methods",
    ("payment_method", "total_orders", "gross_revenue"),
)
hourly_sales = load_frame(
    "select * from public.vw_hourly_sales",
    ("order_hour", "total_orders", "gross_revenue"),
)
heatmap = load_frame(
    "select * from public.vw_hour_weekday_heatmap",
    ("weekday_number", "weekday_name", "order_hour", "total_orders", "gross_revenue"),
)
customer_recurrence = load_frame(
    "select * from public.vw_customer_recurrence limit 20",
    ("customer_id", "customer_name", "customer_phone", "total_orders", "gross_revenue", "first_order_at", "last_order_at"),
)
promotion_candidates = load_frame(
    "select * from public.vw_customer_promotion_candidates limit 20",
    ("customer_id", "customer_name", "customer_phone", "orders_last_30_days", "revenue_last_30_days", "last_order_at", "suggested_action"),
)
lifecycle = load_frame(
    "select * from public.vw_customer_lifecycle limit 50",
    ("customer_id", "customer_name", "customer_phone", "total_orders", "gross_revenue", "last_order_at", "days_since_last_order", "lifecycle_status"),
)
basket_summary = load_frame(
    "select * from public.vw_basket_summary limit 100",
    ("order_id", "order_number", "created_at", "total_amount", "distinct_products", "total_items", "basket_size_label"),
)
product_pairs = load_frame(
    "select * from public.vw_product_pair_sales limit 10",
    ("product_a", "product_b", "orders_together", "related_revenue"),
)
operational = load_frame(
    "select * from public.vw_daily_operational_summary",
    ("reference_date", "orders_today", "revenue_today", "average_ticket_today", "open_orders_today", "unique_customers_today"),
)

st.markdown('<div class="dashboard-title">Sport Clube Lanches</div>', unsafe_allow_html=True)
st.markdown(
    '<div class="dashboard-subtitle">Painel simples para acompanhar vendas, clientes, produtos e horarios de maior movimento.</div>',
    unsafe_allow_html=True,
)

if daily_sales.empty:
    st.info("Ainda nao ha pedidos registrados. Depois do primeiro pedido salvo no Supabase, os KPIs aparecem aqui.")
    st.stop()

daily_sales["order_date"] = pd.to_datetime(daily_sales["order_date"]).dt.date
min_date = daily_sales["order_date"].min()
max_date = daily_sales["order_date"].max()

default_start = max(min_date, max_date - timedelta(days=30))
date_range = st.sidebar.date_input(
    "Periodo",
    value=(default_start, max_date),
    min_value=min_date,
    max_value=max_date,
)

if isinstance(date_range, tuple) and len(date_range) == 2:
    start_date, end_date = date_range
else:
    start_date, end_date = min_date, max_date

filtered_daily = daily_sales[
    (daily_sales["order_date"] >= start_date) & (daily_sales["order_date"] <= end_date)
]

total_orders = int(filtered_daily["total_orders"].sum())
gross_revenue = float(filtered_daily["gross_revenue"].sum())
average_ticket = gross_revenue / total_orders if total_orders else 0
cancelled_orders = int(filtered_daily["cancelled_orders"].sum())

today_data = operational.iloc[0] if not operational.empty else {}

metrics = st.columns(6)
metrics[0].metric("Pedidos", total_orders)
metrics[1].metric("Faturamento", money(gross_revenue))
metrics[2].metric("Ticket medio", money(average_ticket))
metrics[3].metric("Hoje", money(today_data.get("revenue_today", 0)))
metrics[4].metric("Pedidos abertos", int(today_data.get("open_orders_today", 0) or 0))
metrics[5].metric("Cancelados", cancelled_orders)

overview_tab, menu_tab, customer_tab, operation_tab, period_tab = st.tabs(
    ["Visao geral", "Cardapio", "Clientes", "Operacao", "Periodos"]
)

with overview_tab:
    st.markdown('<span class="section-caption">Resultado geral</span>', unsafe_allow_html=True)
    fig = px.line(
        filtered_daily.sort_values("order_date"),
        x="order_date",
        y="gross_revenue",
        markers=True,
        labels={"order_date": "Data", "gross_revenue": "Faturamento"},
        color_discrete_sequence=[GREEN],
    )
    st.plotly_chart(chart_layout(fig), use_container_width=True)

    col_a, col_b, col_c = st.columns(3)
    with col_a:
        fig = px.pie(
            payment_methods,
            names="payment_method",
            values="total_orders",
            hole=.55,
            color_discrete_sequence=[GREEN, YELLOW, PINK, "#54a3ff"],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)
    with col_b:
        fig = px.bar(
            weekday_sales,
            x="weekday_name",
            y="gross_revenue",
            labels={"weekday_name": "Dia", "gross_revenue": "Faturamento"},
            color_discrete_sequence=[YELLOW],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)
    with col_c:
        fig = px.bar(
            neighborhood_sales.head(8),
            x="total_orders",
            y="neighborhood",
            orientation="h",
            labels={"total_orders": "Pedidos", "neighborhood": "Bairro"},
            color_discrete_sequence=[PINK],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)

with menu_tab:
    left, right = st.columns([1.3, 1])
    with left:
        st.markdown('<span class="section-caption">Produtos que mais vendem</span>', unsafe_allow_html=True)
        fig = px.bar(
            product_sales.sort_values("quantity_sold"),
            x="quantity_sold",
            y="product_name",
            orientation="h",
            labels={"quantity_sold": "Quantidade", "product_name": "Produto"},
            color_discrete_sequence=[GREEN],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)
    with right:
        st.markdown('<span class="section-caption">Categorias fortes</span>', unsafe_allow_html=True)
        fig = px.bar(
            category_sales,
            x="category_name",
            y="gross_revenue",
            labels={"category_name": "Categoria", "gross_revenue": "Faturamento"},
            color_discrete_sequence=[YELLOW],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)

    st.markdown('<span class="section-caption">Produtos que saem juntos</span>', unsafe_allow_html=True)
    st.dataframe(product_pairs, use_container_width=True, hide_index=True)

with customer_tab:
    st.markdown('<span class="section-caption">Clientes que mais compram</span>', unsafe_allow_html=True)
    st.dataframe(customer_recurrence, use_container_width=True, hide_index=True)

    col_a, col_b = st.columns(2)
    with col_a:
        st.markdown('<span class="section-caption">Candidatos a promocao</span>', unsafe_allow_html=True)
        st.dataframe(promotion_candidates, use_container_width=True, hide_index=True)
    with col_b:
        st.markdown('<span class="section-caption">Ciclo de vida dos clientes</span>', unsafe_allow_html=True)
        st.dataframe(lifecycle, use_container_width=True, hide_index=True)

with operation_tab:
    col_a, col_b = st.columns([1, 1])
    with col_a:
        st.markdown('<span class="section-caption">Horario de pico</span>', unsafe_allow_html=True)
        fig = px.bar(
            hourly_sales,
            x="order_hour",
            y="total_orders",
            labels={"order_hour": "Hora", "total_orders": "Pedidos"},
            color_discrete_sequence=[GREEN],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)
    with col_b:
        st.markdown('<span class="section-caption">Tamanho dos pedidos</span>', unsafe_allow_html=True)
        basket_counts = basket_summary.groupby("basket_size_label", as_index=False).size()
        fig = px.pie(
            basket_counts,
            names="basket_size_label",
            values="size",
            hole=.45,
            color_discrete_sequence=[GREEN, YELLOW, PINK],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)

    if not heatmap.empty:
        pivot = heatmap.pivot(index="weekday_name", columns="order_hour", values="total_orders").fillna(0)
        fig = px.imshow(
            pivot,
            color_continuous_scale=["#151515", YELLOW, GREEN],
            labels=dict(x="Hora", y="Dia", color="Pedidos"),
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)

with period_tab:
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
    fig = px.bar(
        selected_period,
        x="period_start",
        y="gross_revenue",
        labels={"period_start": "Periodo", "gross_revenue": "Faturamento"},
        color_discrete_sequence=[GREEN],
    )
    st.plotly_chart(chart_layout(fig), use_container_width=True)
    st.dataframe(selected_period, use_container_width=True, hide_index=True)
