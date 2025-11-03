
from enum import Enum
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class AssetSearchType(str, Enum):
    Precise = "PRECISE"
    FTS = "FTS"

class AssetSearchComparator(str, Enum):
    Or = "OR"
    And = "AND"

class AssetSearch(BaseModel):
    type: AssetSearchType
    investment_strategy: list[str]
    investment_strategy_comparator: Optional[AssetSearchComparator] = None
    investment_manager: Optional[str] = None

class AssetSearchResult(BaseModel):
    fund_name: str
    investment_strategy: str
    investment_managers: str
    score: Optional[float] = None

class AssetSearchResults(BaseModel):
    query: str
    data: list[AssetSearchResult]

class SemanticSearchType(str, Enum):
    ANN = "ANN"
    KNN = "KNN"

class SemanticSearch(BaseModel):
    type: SemanticSearchType
    investment_strategy: str
    investment_manager: Optional[str] = None

class SemanticSearchResult(BaseModel):
    fund_name: str
    investment_strategy: str
    investment_managers: str
    distance: Optional[float] = None

class SemanticSearchResults(BaseModel):
    query: str
    data: list[SemanticSearchResult]

class GraphCompany(BaseModel):
    name: str
    CompanySeq: int

class GraphSector(BaseModel):
    sector_name: Optional[str] = None
    SectorSeq: int

class GraphManager(BaseModel):
    name: str
    ManagerSeq: int

class GraphCompanySectorRelation(BaseModel):
    CompanySeq: int
    SectorSeq: int

class GraphManagerFundRelation(BaseModel):
    fund_name: str
    ManagerSeq: int
    NewMFSequence: int

class GraphFund(BaseModel):
    fund_name: str
    NewMFSequence: int

class GraphFundsHoldsCompaniesRelations(BaseModel):
    NewMFSequence: int
    CompanySeq: int
    percentage: float
    create_time: Optional[datetime] = None

class GraphResults(BaseModel):
    companies: list[GraphCompany]
    sectors: list[GraphSector]
    managers: list[GraphManager]
    company_sector_relations: list[GraphCompanySectorRelation]
    manager_fund_relations: list[GraphManagerFundRelation]
    funds: list[GraphFund]
    funds_holds_companies_relations: list[GraphFundsHoldsCompaniesRelations]

class ExposureQuery(BaseModel):
    sector: str
    exposure: int

class ExposureResult(BaseModel):
    fund_name: str
    total_holdings: float

class ExposureResults(BaseModel):
    query: str
    data: list[ExposureResult]