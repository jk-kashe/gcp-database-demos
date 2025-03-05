CREATE SEARCH INDEX
  category_Tokens_IDX
ON
  EU_MutualFunds(category_Tokens);
CREATE SEARCH INDEX
  fund_benchmark_Tokens_IDX
ON
  EU_MutualFunds(fund_benchmark_Tokens);
CREATE SEARCH INDEX
  fund_name_Tokens_IDX
ON
  EU_MutualFunds(fund_name_Tokens);
CREATE SEARCH INDEX
  investment_managers_Tokens_IDX
ON
  EU_MutualFunds(investment_managers_Tokens);
CREATE SEARCH INDEX
  investment_strategy_Tokens_IDX
ON
  EU_MutualFunds(investment_strategy_Tokens);
CREATE SEARCH INDEX
  morningstar_benchmark_Tokens_IDX
ON
  EU_MutualFunds(morningstar_benchmark_Tokens);
CREATE SEARCH INDEX
  top5_holdings_Tokens_IDX
ON
  EU_MutualFunds(top5_holdings_Tokens);
CREATE SEARCH INDEX
  top5_regions_Tokens_IDX
ON
  EU_MutualFunds(top5_regions_Tokens);
CREATE SEARCH INDEX
  investment_managers_Substring_Tokens_IDX
ON
  EU_MutualFunds(investment_managers_Substring_Tokens);
CREATE SEARCH INDEX
  investment_managers_Substring_investment_Strategy_Tokens_Combo_IDX
ON
  EU_MutualFunds(investment_managers_Substring_Tokens,
    investment_strategy_Tokens);
CREATE SEARCH INDEX
  investment_managers_Substring_NgRAM_investment_Strategy_Tokens_Combo_IDX
ON
  EU_MutualFunds(investment_strategy_Tokens,
    investment_managers_Substring_Tokens_NGRAM);
CREATE VECTOR INDEX
  InvestmentStrategyEmbeddingIndex
ON
  EU_MutualFunds(investment_strategy_Embedding_vector)
WHERE
  investment_strategy_Embedding_vector IS NOT NULL OPTIONS ( tree_depth = 2,
    num_leaves = 40,
    distance_type = 'EUCLIDEAN' );
CREATE SEARCH INDEX
  investment_managers_Substring_Tokens_with_vectors_NGRAM_IDX
ON
  EU_MutualFunds(investment_managers_Substring_Tokens_NGRAM) STORING (investment_strategy_Embedding_vector);
CREATE OR REPLACE PROPERTY GRAPH FundGraph NODE TABLES( Companies AS Company DEFAULT LABEL PROPERTIES ALL COLUMNS,
    EU_MutualFunds AS Fund DEFAULT LABEL PROPERTIES ALL COLUMNS EXCEPT (_Injected_SearchUid,
      _Injected_VectorIndex_InvestmentStrategyEmbeddingIndex_FP8,
      _Injected_VectorIndex_InvestmentStrategyEmbeddingIndex_LeafId),
    Sectors AS Sector DEFAULT LABEL PROPERTIES ALL COLUMNS ) EDGE TABLES( FundHoldsCompany SOURCE KEY(NewMFSequence)
  REFERENCES
    Fund(NewMFSequence) DESTINATION KEY(CompanySeq)
  REFERENCES
    Company(CompanySeq) LABEL Holds PROPERTIES ALL COLUMNS,
    CompanyBelongsSector SOURCE KEY(CompanySeq)
  REFERENCES
    Company(CompanySeq) DESTINATION KEY(SectorSeq)
  REFERENCES
    Sector(SectorSeq) LABEL Belongs_To PROPERTIES ALL COLUMNS );