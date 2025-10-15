--CREATE EXTENSION google_ml_integration;
CREATE EXTENSION alloydb_ai_nl cascade;

--To use AlloyDB AI natural language, make sure that the Vertex AI endpoint is configured. 
--Then you create a configuration and register a schema. 
--g_alloydb_ai_nl.g_create_configuration creates the model.
SELECT alloydb_ai_nl.g_create_configuration( 'pagila_demo_cfg' );


SELECT alloydb_ai_nl.g_manage_configuration(
    operation => 'register_table_view',
    configuration_id_in => 'pagila_demo_cfg',
    table_views_in=>'{actor, address, category, city, country, customer, film, film_actor, film_category, inventory, language, payment, rental, staff, store, actor_info, customer_list, film_list, nicer_but_slower_film_list, sales_by_film_category, sales_by_store, staff_list, rental_by_category}'
);

--To provide accurate answers to natural language questions, 
--AlloyDB AI natural language API creates context about tables, 
--views, and columns. You can use the automated context generation 
--feature of the AlloyDB AI natural language API to produce context 
--from tables and columns, and apply the context as COMMENTS attached to tables, 
--views, and columns.

--1. generate schema context
SELECT alloydb_ai_nl.generate_schema_context(
  'pagila_demo_cfg',
  TRUE
);

--some general pagila context
SELECT alloydb_ai_nl.g_manage_configuration(
  'add_general_context',
  'pagila_demo_cfg',
  general_context_in => ARRAY[
    'A rental event, recorded in the rental table, is associated with a specific film in a store''s inventory.',
    'If you are missing views, you are allowed to create CTE'
  ]
);
