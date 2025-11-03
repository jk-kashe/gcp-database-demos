from fastapi import FastAPI
from database import fts_query, like_query, semantic_query, semantic_query_ann, compliance_query, graph_dtls_query
from datatypes import AssetSearch, AssetSearchType, AssetSearchResults, SemanticSearch, SemanticSearchType, SemanticSearchResults, ExposureQuery, ExposureResults, GraphResults

app = FastAPI()

@app.post("/asset_search", name="Perform asset search")
def post_asset_search(query: AssetSearch) -> AssetSearchResults:
    if query.type == AssetSearchType.FTS:
        return fts_query(query)
    
    if query.type == AssetSearchType.Precise:
        return like_query(query)

@app.post("/semantic_search", name="Perform semantic search")
def post_semantic_search(query: SemanticSearch) -> SemanticSearchResults:
    if query.type == SemanticSearchType.KNN:
        return semantic_query(query)
    
    if query.type == SemanticSearchType.ANN:
        return semantic_query_ann(query)

@app.post("/exposure_check", name="Perform exposure check")
def post_exposure_check(query: ExposureQuery) -> ExposureResults:
    return compliance_query(query)

@app.get("/graph", name="Get graph details")
def get_graph() -> GraphResults:
    return graph_dtls_query()

@app.get("/health", name="Health check")
def get_health():
    return "OK"