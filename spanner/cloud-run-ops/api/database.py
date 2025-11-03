from google.api_core.client_options import ClientOptions
from google.cloud import spanner
from config import settings
from datatypes import AssetSearch, AssetSearchType, AssetSearchResults, SemanticSearch, SemanticSearchType, SemanticSearchResults, ExposureQuery, ExposureResults, GraphResults

options = ClientOptions(api_endpoint=settings.spanner_api_endpoint)
spanner_client = spanner.Client(client_options=options)

instance = spanner_client.instance(settings.spanner_instance_id)
database = instance.database(settings.spanner_database_id)


def spanner_read_data(query: str, *vector_input: list) -> list: # pd.DataFrame:
    """This function helps read data from Spanner"""
    with database.snapshot() as snapshot:
        if len(vector_input) != 0:
            results = snapshot.execute_sql(
                query,
                params={"vector": vector_input[0]},
            )
        else:
            results = snapshot.execute_sql(query)

        rows = list(results)
        cols = [x.name for x in results.fields]

        results_list = []

        for row in rows:
            row_dict = {}

            for i, col in enumerate(cols):
                row_dict[col] = row[i]
            
            results_list.append(row_dict)

        return results_list


def fts_query(query: AssetSearch) -> AssetSearchResults:
    """This function runs Full Text Search Query"""
    if query.investment_manager == None:
        fts_query_str = (
            "SELECT DISTINCT fund_name,investment_strategy,investment_managers,fund_trailing_return_ytd,top5_holdings FROM EU_MutualFunds WHERE SEARCH(investment_strategy_Tokens, '"
            + query.investment_strategy[0]
            + "') order by fund_name;"
        )
    else:
        fts_query_str = (
            "SELECT DISTINCT fund_name, investment_managers, investment_strategy, score FROM (SELECT fund_name , investment_managers, investment_strategy, SCORE_NGRAMS(investment_managers_Substring_Tokens_NGRAM, '"
            + query.investment_manager
            + "') AS score FROM EU_MutualFunds WHERE SEARCH_NGRAMS(investment_managers_Substring_Tokens_NGRAM, '"
            + query.investment_manager
            + "', min_ngrams=>1) AND SEARCH(investment_strategy_Tokens, '"
            + query.investment_strategy[0]
            + "') ) ORDER BY score DESC;"
        )

    return AssetSearchResults(query=fts_query_str, data=spanner_read_data(fts_query_str))


def semantic_query(query: SemanticSearch) -> SemanticSearchResults:
    """This function runs Semantic Text Search Query"""
    if query.investment_manager != None:
        semantic_query_string = (
            "SELECT fund_name, investment_strategy,investment_managers, COSINE_DISTANCE( investment_strategy_Embedding, (SELECT embeddings. VALUES FROM ML.PREDICT( MODEL EmbeddingsModel, (SELECT '"
            + query.investment_strategy
            + "' AS content) ) ) ) AS distance FROM EU_MutualFunds WHERE investment_strategy_Embedding is not NULL  AND  search_substring(investment_managers_substring_tokens, '"
            + query.investment_manager
            + "')ORDER BY distance LIMIT 10;"
        )
    else:
        semantic_query_string = (
            "SELECT fund_name, investment_strategy,investment_managers, COSINE_DISTANCE( investment_strategy_Embedding, (SELECT embeddings. VALUES FROM ML.PREDICT( MODEL EmbeddingsModel, (SELECT '"
            + query.investment_strategy
            + "' AS content) ) ) ) AS distance FROM EU_MutualFunds WHERE investment_strategy_Embedding is not NULL  ORDER BY distance LIMIT 10;"
        )

    return SemanticSearchResults(query=semantic_query_string, data=spanner_read_data(semantic_query_string))

def semantic_query_ann(query: SemanticSearch) -> SemanticSearchResults:
    """This function runs Semantic Text Search ANN Query"""

    embedding_query = (
        'SELECT embeddings. VALUES as vector FROM ML.PREDICT( MODEL EmbeddingsModel, (SELECT "'
        + query.investment_strategy
        + '" AS content) ) ;'
    )

    vector_input = spanner_read_data(embedding_query)

    if query.investment_manager != None:
        ann_query = (
            "SELECT funds.fund_name, funds.investment_strategy, funds.investment_managers FROM (SELECT NewMFSequence, APPROX_EUCLIDEAN_DISTANCE(investment_strategy_Embedding_vector, @vector, options => JSON '{\"num_leaves_to_search\": 10}') AS distance FROM EU_MutualFunds @{force_index = InvestmentStrategyEmbeddingIndex} WHERE investment_strategy_Embedding_vector IS NOT NULL ORDER BY distance LIMIT 500 ) AS ann JOIN EU_MutualFunds AS funds ON ann.NewMFSequence = funds.NewMFSequence WHERE SEARCH_NGRAMS(funds.investment_managers_Substring_Tokens_NGRAM, '"
            + query.investment_manager
            + "',min_ngrams=>1)  ORDER BY SCORE_NGRAMS(funds.investment_managers_Substring_Tokens_NGRAM, '"
            + query.investment_manager
            + "') desc;"
        )
    else:
        ann_query = "SELECT fund_name, investment_strategy, investment_managers, APPROX_EUCLIDEAN_DISTANCE(investment_strategy_Embedding_vector, @vector, options => JSON '{\"num_leaves_to_search\": 10}') AS distance FROM EU_MutualFunds @{force_index = InvestmentStrategyEmbeddingIndex} WHERE investment_strategy_Embedding_vector IS NOT NULL ORDER BY distance LIMIT 100;"

    return SemanticSearchResults(query=ann_query, data=spanner_read_data(ann_query, vector_input[0]["vector"]))


def like_query(query: AssetSearch) -> AssetSearchResults:
    """This function runs Precise Text Search Query"""

    investment_strategy_subquery = [
        " investment_strategy LIKE ('%"
        + investment_strategy
        + "%') "
        for investment_strategy in query.investment_strategy
    ]

    precise_query = (
        " SELECT DISTINCT fund_name, investment_managers, investment_strategy FROM EU_MutualFunds WHERE investment_managers LIKE ('%"
        + query.investment_manager
        + "%') AND ("
        + query.investment_strategy_comparator.join(investment_strategy_subquery)
        + ") ORDER BY fund_name;"
    )

    return AssetSearchResults(query=precise_query, data=spanner_read_data(precise_query))


def compliance_query(query: ExposureQuery) -> ExposureResults:
    """This function runs Compliance Graph  Search Query"""
    graph_compliance_query = (
        "GRAPH FundGraph MATCH (sector:Sector {sector_name: '"
        + query.sector
        + "'})<-[:BELONGS_TO]-(company:Company)<-[h:HOLDS]-(fund:Fund) RETURN fund.fund_name, SUM(h.percentage) AS total_holdings GROUP BY fund.fund_name NEXT FILTER total_holdings > "
        + str(query.exposure)
        + " RETURN fund_name, total_holdings"
    )

    return ExposureResults(query=graph_compliance_query, data=spanner_read_data(graph_compliance_query))

def graph_dtls_query() -> GraphResults:
    """This function runs Graph Details Query"""
    return GraphResults(
        companies=spanner_read_data("select CompanySeq, name from Companies;"),
        sectors=spanner_read_data("select * from Sectors;"),
        managers=spanner_read_data("select * from Managers LIMIT 100;"),
        company_sector_relations=spanner_read_data("select * from CompanyBelongsSector;"),
        manager_fund_relations=spanner_read_data("SELECT mgrs.NewMFSequence,fund_name,ManagerSeq from ManagerManagesFund mgrs JOIN EU_MutualFunds funds ON mgrs.NewMFSequence =  funds.NewMFSequence where ManagerSeq in (select ManagerSeq from Managers LIMIT 100);"),
        funds=spanner_read_data("select fund_name, NewMFSequence from EU_MutualFunds where NewMFSequence in (SELECT NewMFSequence FROM FundHoldsCompany);"),
        funds_holds_companies_relations=spanner_read_data("select * from FundHoldsCompany;")
    )