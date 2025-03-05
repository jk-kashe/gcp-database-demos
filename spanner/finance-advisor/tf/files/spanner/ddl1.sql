ALTER MODEL EmbeddingsModel SET OPTIONS (
endpoint = '//aiplatform.googleapis.com/projects/${project}/locations/${location}/publishers/google/models/text-embedding-004'
)
;
ALTER TABLE EU_MutualFunds ADD COLUMN  fund_name_Tokens TOKENLIST AS (TOKENIZE_FULLTEXT(fund_name)) HIDDEN;
ALTER TABLE EU_MutualFunds ADD COLUMN  category_Tokens TOKENLIST AS (TOKENIZE_FULLTEXT(category)) HIDDEN;
ALTER TABLE EU_MutualFunds ADD COLUMN  investment_strategy_Tokens TOKENLIST AS (TOKENIZE_FULLTEXT(investment_strategy)) HIDDEN;
ALTER TABLE EU_MutualFunds ADD COLUMN  investment_managers_Tokens TOKENLIST AS (TOKENIZE_FULLTEXT(investment_managers)) HIDDEN;
ALTER TABLE EU_MutualFunds ADD COLUMN  fund_benchmark_Tokens TOKENLIST AS (TOKENIZE_FULLTEXT(fund_benchmark)) HIDDEN;
ALTER TABLE EU_MutualFunds ADD COLUMN  morningstar_benchmark_Tokens TOKENLIST AS (TOKENIZE_FULLTEXT(morningstar_benchmark)) HIDDEN;
ALTER TABLE EU_MutualFunds ADD COLUMN  top5_regions_Tokens TOKENLIST AS (TOKENIZE_FULLTEXT(top5_regions)) HIDDEN;
ALTER TABLE EU_MutualFunds ADD COLUMN  top5_holdings_Tokens TOKENLIST AS (TOKENIZE_FULLTEXT(top5_holdings)) HIDDEN;
ALTER TABLE EU_MutualFunds ADD COLUMN  investment_managers_Substring_Tokens  TOKENLIST AS (TOKENIZE_SUBSTRING(investment_managers)) HIDDEN;
ALTER TABLE
  EU_MutualFunds ADD COLUMN investment_managers_Substring_Tokens_NGRAM TOKENLIST AS ( TOKENIZE_SUBSTRING(investment_managers,
      ngram_size_min=>2,
      ngram_size_max=>3,
      relative_search_types=>["word_prefix",
      "word_suffix"])) HIDDEN;