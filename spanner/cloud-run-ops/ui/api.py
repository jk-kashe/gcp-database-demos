from config import settings
from datatypes import AssetSearch, AssetSearchResults, SemanticSearch, SemanticSearchResults, ExposureQuery, ExposureResults, GraphResults
import google.oauth2.id_token
import google.auth.transport.requests
import google.auth
import httpx
import re

if re.search(".run.app$", httpx.URL(settings.api_base_url).host) == None:
    client = httpx.Client(timeout=30.0)
else:
    request = google.auth.transport.requests.Request()
    id_token = google.oauth2.id_token.fetch_id_token(request, settings.api_base_url)

    def google_auth(request):
        request.headers["Authorization"] = f"Bearer {id_token}"

        return request

    client = httpx.Client(http2=True, timeout=30.0, auth=google_auth)

def asset_search(query: AssetSearch) -> AssetSearchResults:
    response = client.post(f"{settings.api_base_url}/asset_search", json=query.dict())


    if response.status_code != 200:
        return response.text
    
    return AssetSearchResults.model_validate(response.json())

def semantic_search(query: SemanticSearch) -> SemanticSearchResults:
    response = client.post(f"{settings.api_base_url}/semantic_search", json=query.dict())

    if response.status_code != 200:
        return response.text

    return SemanticSearchResults.model_validate(response.json())

def exposure_check(query: ExposureQuery) -> ExposureResults:
    response = client.post(f"{settings.api_base_url}/exposure_check", json=query.dict())

    if response.status_code != 200:
        return response.text
    
    return ExposureResults.model_validate(response.json())

def get_graph() -> GraphResults:
    response = client.get(f"{settings.api_base_url}/graph")

    if response.status_code != 200:
        return response.text

    return GraphResults.model_validate(response.json())

def get_health():
    response = client.get(f"{settings.api_base_url}/health")

    return response.text