"""This file is for database operations done by the application"""

# pylint: disable=line-too-long
import streamlit as st
from streamlit_extras.stylable_container import stylable_container

def display_spanner_query(spanner_query: str) -> None:
    """This function runs Graph Details  Query"""
    with st.expander("Spanner Query"):
        with stylable_container(
            "codeblock",
            """
            code {
                white-space: pre-wrap !important;
            }
            """,
        ):
            st.code(spanner_query, language="sql", line_numbers=False)