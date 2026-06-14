import base64
import os
import re
from datetime import date, datetime, timedelta
from pathlib import Path

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

GREEN = "#36f16a"
YELLOW = "#ffcc4d"
PINK = "#ff4f8b"
BG = "#0a0a0a"
SURFACE = "#151515"
TEXT = "#f7f7f7"
MUTED = "#a5a5a5"
APP_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = APP_DIR.parents[1]
LOGO_PATH = PROJECT_ROOT / "public" / "Logo-Marca.jpeg"

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
        padding-top: 3.25rem;
      }}
      .dashboard-title {{
        color: {TEXT};
        font-size: 2.1rem;
        font-weight: 900;
        line-height: 1.14;
        margin: 0 0 .35rem;
        padding-top: .25rem;
      }}
      .dashboard-subtitle {{
        color: {MUTED};
        margin-bottom: 1.25rem;
      }}
      .sidebar-brand {{
        align-items: center;
        display: flex;
        gap: .65rem;
        margin: .25rem 0 1.35rem;
      }}
      .sidebar-brand img {{
        border-radius: 999px;
        height: 56px;
        object-fit: cover;
        object-position: center;
        width: 56px;
      }}
      .sidebar-brand span {{
        color: {TEXT};
        font-size: 1.05rem;
        font-weight: 900;
        line-height: 1.08;
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

def get_secret(name: str) -> str | None:
    value = os.getenv(name)

    if value:
        return value

    try:
        return st.secrets.get(name)
    except Exception:
        return None


def logo_data_url() -> str | None:
    if not LOGO_PATH.exists():
        return None

    encoded = base64.b64encode(LOGO_PATH.read_bytes()).decode("ascii")
    return f"data:image/jpeg;base64,{encoded}"


supabase_url = get_secret("SUPABASE_URL")
supabase_key = get_secret("SUPABASE_KEY")

if not supabase_url or not supabase_key:
    st.warning(
        "Configure SUPABASE_URL e SUPABASE_KEY no arquivo analytics/streamlit/.env "
        "ou nos Secrets do Streamlit Community Cloud para carregar dados reais."
    )
    st.stop()

client = create_client(supabase_url, supabase_key)

try:
    client.table("vw_kpi_snapshot").select("*").limit(1).execute()
except Exception as exc:
    st.error(
        "Nao foi possivel conectar no Supabase. Confira SUPABASE_URL e SUPABASE_KEY em "
        "`analytics/streamlit/.env` ou nos Secrets do Streamlit Community Cloud."
    )
    st.code(str(exc), language="text")
    st.stop()


def money(value: float) -> str:
    return f"R$ {float(value or 0):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


def date_label(value: object) -> str:
    return pd.to_datetime(value).strftime("%d/%m/%Y")


def hour_label(value: object) -> str:
    return f"{int(value):02d}h"


def normalize_neighborhood(value: object) -> str:
    raw_value = str(value or "").strip()

    if not raw_value:
        return "Retirada"

    clean_value = " ".join(
        "".join(char.lower() if char.isalnum() else " " for char in raw_value).split()
    )
    clean_value = re.sub(r"(?<=[a-z])(?=\d)", " ", clean_value)
    clean_value = re.sub(r"(?<=\d)(?=[a-z])", " ", clean_value)
    sport_clube_prefix = clean_value.startswith("sport club ") or clean_value.startswith("sport clube ")

    if sport_clube_prefix and clean_value.split()[-1] in {"3", "iii", "4", "iv"}:
        return "Sport Clube 3/4"

    if sport_clube_prefix and clean_value.split()[-1] in {"1", "i", "2", "ii", "5", "v", "6", "vi"}:
        number_map = {"i": "1", "ii": "2", "v": "5", "vi": "6"}
        neighborhood_number = number_map.get(clean_value.split()[-1], clean_value.split()[-1])
        return f"Sport Clube {neighborhood_number}"

    if sport_clube_prefix and clean_value.endswith("natureza"):
        return "Sport Clube Natureza"

    return raw_value.title()


def add_local_datetime(source: pd.DataFrame) -> pd.DataFrame:
    if source.empty or "created_at" not in source.columns:
        return source

    data = source.copy()
    data["local_created_at"] = pd.to_datetime(data["created_at"], utc=True, errors="coerce").dt.tz_convert(
        "America/Sao_Paulo"
    )
    return data


def format_period_label(row: pd.Series) -> str:
    period_start = pd.to_datetime(row["period_start"])
    period_type = row["period_type"]

    if period_type == "day":
        return period_start.strftime("%d/%m/%Y")

    if period_type == "week":
        return f"Semana de {period_start.strftime('%d/%m/%Y')}"

    if period_type == "month":
        return period_start.strftime("%m/%Y")

    if period_type == "quarter":
        quarter = ((period_start.month - 1) // 3) + 1
        return f"{quarter}o tri/{period_start.year}"

    if period_type == "semester":
        semester = 1 if period_start.month <= 6 else 2
        return f"{semester}o sem/{period_start.year}"

    return str(period_start.year)


def get_date_filter_bounds(source: pd.DataFrame) -> tuple[date, date, str]:
    today = date.today()

    if source.empty:
        return today, today, "Dia"

    source_dates = pd.to_datetime(source["order_date"]).dt.date
    min_value = source_dates.min()
    max_value = source_dates.max()

    if min_value == max_value:
        return min_value, max_value, "Dia"

    return min_value, max_value, "Periodo"


def empty_frame(columns: list[str]) -> pd.DataFrame:
    return pd.DataFrame(columns=columns)


@st.cache_data(ttl=30)
def load_frame(
    table_name: str,
    columns: tuple[str, ...],
    order_by: str | None = None,
    ascending: bool = True,
    limit: int | None = None,
) -> pd.DataFrame:
    query = client.table(table_name).select("*")

    if order_by:
        query = query.order(order_by, desc=not ascending)

    if limit:
        query = query.limit(limit)

    response = query.execute()
    data = response.data or []
    return pd.DataFrame(data, columns=list(columns))


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
    "vw_daily_sales",
    ("order_date", "total_orders", "cancelled_orders", "gross_revenue", "average_ticket"),
    order_by="order_date",
    ascending=False,
)
period_sales = load_frame(
    "vw_period_sales",
    ("period_type", "period_start", "total_orders", "gross_revenue", "average_ticket"),
    order_by="period_start",
    ascending=False,
)
weekday_sales = load_frame(
    "vw_weekday_sales",
    ("weekday_number", "weekday_name", "total_orders", "gross_revenue", "average_ticket"),
)
product_sales = load_frame(
    "vw_product_sales",
    ("product_id", "product_name", "quantity_sold", "gross_revenue", "orders_count"),
    limit=15,
)
category_sales = load_frame(
    "vw_category_sales",
    ("category_id", "category_name", "quantity_sold", "gross_revenue", "orders_count"),
)
orders_base = load_frame(
    "vw_orders_base",
    ("id", "created_at", "neighborhood", "order_status", "total_amount"),
)
neighborhood_sales = load_frame(
    "vw_neighborhood_sales",
    ("neighborhood", "total_orders", "gross_revenue", "average_ticket"),
    limit=15,
)
payment_methods = load_frame(
    "vw_payment_methods",
    ("payment_method", "total_orders", "gross_revenue"),
)
hourly_sales = load_frame(
    "vw_hourly_sales",
    ("order_hour", "total_orders", "gross_revenue"),
)
heatmap = load_frame(
    "vw_hour_weekday_heatmap",
    ("weekday_number", "weekday_name", "order_hour", "total_orders", "gross_revenue"),
)
customer_recurrence = load_frame(
    "vw_customer_recurrence",
    ("customer_id", "customer_name", "customer_phone", "total_orders", "gross_revenue", "first_order_at", "last_order_at"),
    limit=20,
)
promotion_candidates = load_frame(
    "vw_customer_promotion_candidates",
    ("customer_id", "customer_name", "customer_phone", "orders_last_30_days", "revenue_last_30_days", "last_order_at", "suggested_action"),
    limit=20,
)
lifecycle = load_frame(
    "vw_customer_lifecycle",
    ("customer_id", "customer_name", "customer_phone", "total_orders", "gross_revenue", "last_order_at", "days_since_last_order", "lifecycle_status"),
    limit=50,
)
basket_summary = load_frame(
    "vw_basket_summary",
    ("order_id", "order_number", "created_at", "total_amount", "distinct_products", "total_items", "basket_size_label"),
    limit=100,
)
product_pairs = load_frame(
    "vw_product_pair_sales",
    ("product_a", "product_b", "orders_together", "related_revenue"),
    limit=10,
)
operational = load_frame(
    "vw_daily_operational_summary",
    ("reference_date", "orders_today", "revenue_today", "average_ticket_today", "open_orders_today", "unique_customers_today"),
)

valid_orders_base = add_local_datetime(orders_base)
if not valid_orders_base.empty:
    valid_orders_base = valid_orders_base[valid_orders_base["order_status"] != "cancelled"].copy()

if not valid_orders_base.empty:
    valid_orders_base["normalized_neighborhood"] = valid_orders_base["neighborhood"].apply(normalize_neighborhood)
    valid_orders_base["order_hour"] = valid_orders_base["local_created_at"].dt.hour
    valid_orders_base["total_amount"] = pd.to_numeric(valid_orders_base["total_amount"], errors="coerce").fillna(0)

    neighborhood_sales = (
        valid_orders_base.groupby("normalized_neighborhood", as_index=False)
        .agg(
            total_orders=("id", "count"),
            gross_revenue=("total_amount", "sum"),
            average_ticket=("total_amount", "mean"),
        )
        .rename(columns={"normalized_neighborhood": "neighborhood"})
        .sort_values(["total_orders", "gross_revenue"], ascending=False)
    )

    hourly_sales = (
        valid_orders_base.groupby("order_hour", as_index=False)
        .agg(total_orders=("id", "count"), gross_revenue=("total_amount", "sum"))
        .sort_values("order_hour")
    )

logo_url = logo_data_url()
if logo_url:
    st.sidebar.markdown(
        f"""
        <div class="sidebar-brand">
          <img src="{logo_url}" alt="Sport Clube Lanches">
          <span>Sport Clube<br>Lanches</span>
        </div>
        """,
        unsafe_allow_html=True,
    )

if st.sidebar.button("Atualizar dados", use_container_width=True):
    st.cache_data.clear()
    st.rerun()

st.markdown('<div class="dashboard-title">Sport Clube Lanches</div>', unsafe_allow_html=True)
st.markdown(
    '<div class="dashboard-subtitle">Painel simples para acompanhar vendas, clientes, produtos e horarios de maior movimento.</div>',
    unsafe_allow_html=True,
)

has_orders = not daily_sales.empty

if daily_sales.empty:
    st.info("Ainda nao ha pedidos registrados. Depois do primeiro pedido salvo no Supabase, os graficos passam a mostrar historico real.")
    daily_sales = pd.DataFrame(
        [
            {
                "order_date": date.today(),
                "total_orders": 0,
                "cancelled_orders": 0,
                "gross_revenue": 0,
                "average_ticket": 0,
            }
        ]
    )

daily_sales["order_date"] = pd.to_datetime(daily_sales["order_date"]).dt.date
min_date, max_date, default_filter_mode = get_date_filter_bounds(
    daily_sales if has_orders else pd.DataFrame()
)

st.sidebar.markdown("### Filtros")
filter_mode = st.sidebar.radio(
    "Filtrar por",
    options=["Dia", "Mes", "Ano", "Periodo"],
    index=["Dia", "Mes", "Ano", "Periodo"].index(default_filter_mode),
)

if filter_mode == "Dia":
    selected_day = st.sidebar.date_input(
        "Data",
        value=max_date,
        min_value=min_date,
        max_value=max_date,
    )
    start_date = selected_day
    end_date = selected_day
elif filter_mode == "Mes":
    available_months = (
        pd.to_datetime(daily_sales["order_date"])
        .dt.to_period("M")
        .drop_duplicates()
        .sort_values(ascending=False)
    )
    selected_month = st.sidebar.selectbox(
        "Mes",
        options=available_months.astype(str).tolist(),
        format_func=lambda value: datetime.strptime(value, "%Y-%m").strftime("%m/%Y"),
    )
    month_start = pd.Period(selected_month, freq="M").start_time.date()
    month_end = pd.Period(selected_month, freq="M").end_time.date()
    start_date = max(month_start, min_date)
    end_date = min(month_end, max_date)
elif filter_mode == "Ano":
    available_years = sorted({item.year for item in daily_sales["order_date"]}, reverse=True)
    selected_year = st.sidebar.selectbox("Ano", options=available_years)
    start_date = max(date(selected_year, 1, 1), min_date)
    end_date = min(date(selected_year, 12, 31), max_date)
else:
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

st.sidebar.caption(f"Selecionado: {start_date.strftime('%d/%m/%Y')} a {end_date.strftime('%d/%m/%Y')}")

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
    if has_orders and gross_revenue > 0:
        overview_daily = filtered_daily.sort_values("order_date").copy()
        overview_daily["order_date_label"] = overview_daily["order_date"].apply(date_label)
        fig = px.line(
            overview_daily,
            x="order_date_label",
            y="gross_revenue",
            markers=True,
            labels={"order_date_label": "Data", "gross_revenue": "Faturamento"},
            color_discrete_sequence=[GREEN],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)
    else:
        st.info("Sem vendas no filtro selecionado. Assim que houver pedidos, o grafico de faturamento aparece aqui.")

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
        hourly_chart = hourly_sales.copy()
        hourly_chart["hour_label"] = (
            hourly_chart["order_hour"].apply(hour_label)
            if not hourly_chart.empty
            else pd.Series(dtype=str)
        )

        fig = px.bar(
            hourly_chart,
            x="hour_label",
            y="total_orders",
            labels={"hour_label": "Hora", "total_orders": "Pedidos"},
            color_discrete_sequence=[GREEN],
        )
        st.plotly_chart(chart_layout(fig), use_container_width=True)
    with col_b:
        st.markdown('<span class="section-caption">Perfil dos pedidos</span>', unsafe_allow_html=True)
        basket_counts = basket_summary.copy()
        if not basket_counts.empty:
            basket_counts["basket_size_label"] = basket_counts["basket_size_label"].replace(
                {"Pedido medio": "Pedido médio"}
            )
        basket_counts = basket_counts.groupby("basket_size_label", as_index=False).size()
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
    selected_period_type = st.selectbox(
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
    selected_period = period_sales[period_sales["period_type"] == selected_period_type].sort_values("period_start").copy()
    if not selected_period.empty:
        selected_period["period_label"] = selected_period.apply(format_period_label, axis=1)
    else:
        selected_period["period_label"] = pd.Series(dtype=str)

    fig = px.bar(
        selected_period,
        x="period_label",
        y="gross_revenue",
        labels={"period_label": "Periodo", "gross_revenue": "Faturamento"},
        color_discrete_sequence=[GREEN],
    )
    st.plotly_chart(chart_layout(fig), use_container_width=True)
    st.dataframe(selected_period, use_container_width=True, hide_index=True)
