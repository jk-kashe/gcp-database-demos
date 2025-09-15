--CREATE EXTENSION google_ml_integration;
CREATE EXTENSION alloydb_ai_nl cascade;

--To use AlloyDB AI natural language, make sure that the Vertex AI endpoint is configured. 
--Then you create a configuration and register a schema. 
--g_alloydb_ai_nl.g_create_configuration creates the model.
SELECT alloydb_ai_nl.g_create_configuration( 'agentspace_demo_cfg' );


SELECT alloydb_ai_nl.g_manage_configuration(
    operation => 'register_table_view',
    configuration_id_in => 'agentspace_demo_cfg',
    table_views_in=>'{airports, flights,  amenities, tickets, policies}'
);

--To provide accurate answers to natural language questions, 
--AlloyDB AI natural language API creates context about tables, 
--views, and columns. You can use the automated context generation 
--feature of the AlloyDB AI natural language API to produce context 
--from tables and columns, and apply the context as COMMENTS attached to tables, 
--views, and columns.

--1. generate schema context
SELECT alloydb_ai_nl.generate_schema_context(
  'agentspace_demo_cfg',
  TRUE
);

--add some examples
SELECT alloydb_ai_nl.add_example(
 'Where can I find coffee?',
 'SELECT name,description,location,terminal from amenities
order by embedding <=> embedding(''text-embedding-005'',''Where can I find coffee?'')::vector asc
limit 5;',
 'agentspace_demo_cfg');


SELECT alloydb_ai_nl.add_example(
'May I change my ticket?',
'SELECT content from policies
order by embedding <=> embedding(''text-embedding-005'',''May I change my ticket?'')::vector asc
limit 5;',
'agentspace_demo_cfg');

SELECT alloydb_ai_nl.add_example(
 'flight B6 415 on September 15 2025',
 'select * from flights where airline=''B6'' and flight_number=''415'' and DATE("departure_time") = ''2025-09-15'';',
 'agentspace_demo_cfg');

--Create agentspace user
CREATE ROLE Agent WITH LOGIN PASSWORD 'agent-777';
GRANT SELECT ON TABLE public.airports to Agent;
GRANT SELECT ON TABLE public.amenities to Agent;
GRANT SELECT ON TABLE public.flights to Agent;
GRANT SELECT ON TABLE public.policies to Agent;
