"""This module is the page for Exposure Check Search feature"""

# pylint: disable=line-too-long,import-error,invalid-name

from database import display_spanner_query
from api import exposure_check
from datatypes import ExposureQuery
from home import table_columns_layout_setup
from itables.streamlit import interactive_table
import streamlit as st
import pandas as pd

st.logo(
    "https://storage.googleapis.com/github-repo/generative-ai/sample-apps/finance-advisor-spanner/images/investments.png"
)


with st.sidebar:
    with st.form("Compliance Search"):
        st.subheader("Search Criteria")
        sectorOption = st.selectbox(
            "Which sector would you want to focus on?",
            ("Technology", "Pharma", "Semiconductors"),
            index=None,
            placeholder="Select sector ...",
        )
        exposurePercentage = st.select_slider(
            "How much exposure to this sector would you prefer",
            options=["10%", "20%", "30%", "40%", "50%", "60%", "70%"],
        )
        exposurePercentage = exposurePercentage[:2]
        compliance_search_submitted = st.form_submit_button("Submit")
if compliance_search_submitted:
    st.header("FinVest Fund Advisor")
    st.subheader("Exposure Check")

    query = ExposureQuery(
        sector=sectorOption, exposure=int(exposurePercentage)
    )

    with st.spinner("Querying Spanner..."):
        results = exposure_check(query)
        compliance_queries = results.query
        data = pd.DataFrame([r.model_dump() for r in results.data])
        display_spanner_query(str(compliance_queries))

    interactive_table(data, caption="", **table_columns_layout_setup())
