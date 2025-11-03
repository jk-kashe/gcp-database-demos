"""This module is the page for Graph Viz Data Search feature"""

# pylint: disable=import-error, line-too-long, unused-variable

from api import get_graph
from pyvis.network import Network


def generate_graph() -> None:
    """This function is for generating the Graph Visualization"""

    graph = Network("900px", "900px", notebook=True, heading="")
    results = get_graph()

    for company in results.companies:  # type: ignore[union-attr]  # might ignore other potential errors
        graph.add_node(
            str(company.CompanySeq),
            label=company.name,
            title=company.name,
            shape="triangle",
        )

    for sector in results.sectors:  # type: ignore[union-attr]  # might ignore other potential errors
        graph.add_node(
            str(sector.SectorSeq),
            label=sector.sector_name,
            shape="square",
            color="red",
            title=sector.sector_name,
        )

    for fund in results.funds:  # type: ignore[union-attr]  # might ignore other potential errors
        graph.add_node(
            str(fund.NewMFSequence),
            label=fund.fund_name,
            color="green",
            title=fund.fund_name,
        )

    for relation in results.company_sector_relations:  # type: ignore[union-attr]  # might ignore other potential errors
        graph.add_edge(str(relation.CompanySeq), str(relation.SectorSeq), title="BELONGS")

    for relation in results.funds_holds_companies_relations:  # type: ignore[union-attr]  # might ignore other potential errors
        graph.add_edge(str(relation.NewMFSequence), str(relation.CompanySeq), title="HOLDS")

    graph.show("graph_viz.html")
