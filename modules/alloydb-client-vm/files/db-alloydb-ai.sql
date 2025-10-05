CREATE EXTENSION google_ml_integration; 
CREATE EXTENSION IF NOT EXISTS vector;

GRANT EXECUTE ON FUNCTION embedding TO postgres;
GRANT EXECUTE ON FUNCTION ml_predict_row TO postgres;

CREATE EXTENSION IF NOT EXISTS google_ml_integration CASCADE;
