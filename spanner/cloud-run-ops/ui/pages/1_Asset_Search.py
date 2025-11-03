"""This module is the page for Asset Search feature"""

# pylint: disable=line-too-long,import-error,invalid-name

from database import display_spanner_query
from api import asset_search
from datatypes import AssetSearch, AssetSearchType, AssetSearchComparator
from home import table_columns_layout_setup
from itables.streamlit import interactive_table
import streamlit as st
import pandas as pd

st.logo(
    "https://storage.googleapis.com/github-repo/generative-ai/sample-apps/finance-advisor-spanner/images/investments.png"
)

with st.sidebar:
    with st.form("Asset Search"):
        st.subheader("Search Criteria")
        precise_vs_text = st.radio("", ["Full-Text", "Precise"], horizontal=True)
        precise_search = False
        with st.expander("Asset Strategy", expanded=True):
            investment_strategy_pt1 = st.text_input("", value="Europe")
            and_or_exclude = st.radio("", ["AND", "OR", "EXCLUDE"], horizontal=True)
            investment_strategy_pt2 = st.text_input("", value="Asia")
        investment_manager = st.text_input("Investment Manager", value="James")
        investment_strategy = ""
        if precise_vs_text == "Full-Text":
            if and_or_exclude == "EXCLUDE":
                investment_strategy = (
                    investment_strategy_pt1 + " -" + investment_strategy_pt2
                )
            else:
                investment_strategy = (
                    investment_strategy_pt1
                    + " "
                    + and_or_exclude
                    + " "
                    + investment_strategy_pt2
                )
        else:
            precise_search = True
        asset_search_submitted = st.form_submit_button("Submit")
if asset_search_submitted:
    if precise_search:
        query = AssetSearch(
            type=AssetSearchType.Precise,
            investment_strategy=[investment_strategy_pt1, investment_strategy_pt2],
            investment_strategy_comparator=AssetSearchComparator(and_or_exclude),
            investment_manager=investment_manager
        )
    else:
        query = AssetSearch(
            type=AssetSearchType.FTS,
            investment_strategy=[investment_strategy],
            investment_manager=investment_manager
        )

    st.header("FinVest Fund Advisor")
    st.subheader("Asset Search")

    with st.spinner("Querying Spanner..."):
        results = asset_search(query)
        data = pd.DataFrame([r.model_dump() for r in results.data])
        display_spanner_query(results.query)
    
    interactive_table(data, caption="", **table_columns_layout_setup())