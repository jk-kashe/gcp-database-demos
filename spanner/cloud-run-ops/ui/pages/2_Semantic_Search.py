"""This module is the page for Semantic Search feature"""

# pylint: disable=line-too-long,import-error,invalid-name

from database import display_spanner_query
from api import semantic_search
from datatypes import SemanticSearch, SemanticSearchType
from home import table_columns_layout_setup
from itables.streamlit import interactive_table
import streamlit as st
import pandas as pd

st.logo(
    "https://storage.googleapis.com/github-repo/generative-ai/sample-apps/finance-advisor-spanner/images/investments.png"
)


with st.sidebar:
    with st.form("Asset Semantic Search"):
        st.subheader("Search Criteria")
        annVsKNN = st.radio("", ["ANN", "KNN"], horizontal=True)
        investment_strategy = st.text_area(
            "Search for me",
            value="Invest in companies which also subscribe to my ideas around climate change, doing good for the planet",
        )
        investment_manager = st.text_input("Investment Manager", value="Maarten")
        asset_semantic_search_submitted = st.form_submit_button("Submit")
if asset_semantic_search_submitted:
    st.header("FinVest Fund Advisor")
    st.subheader("Semantic Search")
    query = SemanticSearch(
        type=SemanticSearchType(annVsKNN),
        investment_strategy=investment_strategy,
        investment_manager=investment_manager,
    )

    with st.spinner("Querying Spanner..."):
        results = semantic_search(query)
        semantic_queries = results.query
        data = pd.DataFrame([r.model_dump() for r in results.data])
        display_spanner_query(str(semantic_queries))

    interactive_table(data, caption="", **table_columns_layout_setup())
