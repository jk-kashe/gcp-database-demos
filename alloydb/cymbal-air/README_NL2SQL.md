# Extending the demo with AlloyDB Natural Language 2 SQL

## Enabling AlloyDB AI and Natural Language

### 1. Enabling AlloyDB AI NL Flag

In the GCP Console:
- Navigate to AlloyDB
- Find your cluster primary instance and click "Edit"
- Scroll down to "Advanced configuration Options"
- Under Flags section, click "Add a database flag"
- Find "alloydb_ai_nl.enabled" and enable it
- Restart your cluster for the changes to take effect

### 2. Create alloydb_ai_nl extensions
In the AlloyDB studio, login to your instance and run

```
--CREATE EXTENSION google_ml_integration;
CREATE EXTENSION alloydb_ai_nl cascade;
```
Note: google_ml_integration is already enabled in this deployment, we only include it for reference

## Configuring AlloyDB NL2SQL

### 1. Create a configuration

To use AlloyDB AI natural language, make sure that the Vertex AI endpoint is configured.
Then you create a configuration and register a schema. g_alloydb_ai_nl.g_create_configuration creates the model.


```
SELECT alloydb_ai_nl.g_create_configuration( 'cymbal_air_demo_cfg' );


SELECT alloydb_ai_nl.g_manage_configuration(
    operation => 'register_table_view',
    configuration_id_in => 'cymbal_air_demo_cfg',
    table_views_in=>'{airports, flights,  amenities, tickets, policies}'
);

```

### 2. Create and apply context for tables and columns

To provide accurate answers to natural language questions, AlloyDB AI natural language API creates context 
about tables, views, and columns. You can use the automated context generation feature of the AlloyDB AI 
natural language API to produce context from tables and columns, and apply the context as COMMENTS attached
to tables, views, and columns.

```

--1. generate schema context
SELECT alloydb_ai_nl.generate_schema_context(
  'cymbal_air_demo_cfg',
  TRUE
);

--2. To verify the generated context for the nla_demo.products table, run the following query
SELECT object_context
FROM alloydb_ai_nl.generated_schema_context_view
WHERE schema_object = 'public.flights';

--3. To verify the produced context for a column, such as nla_demo.products.name, run the following
SELECT object_context
FROM alloydb_ai_nl.generated_schema_context_view
WHERE schema_object = 'public.flights.departure_time';

--add some examples
SELECT alloydb_ai_nl.add_example(
 'Where can I find coffee?',
 'SELECT name,description,location,terminal from amenities
order by embedding <=> embedding(''text-embedding-005'',''Where can I find coffee?'')::vector asc
limit 5;',
 'cymbal_air_demo_cfg');


SELECT alloydb_ai_nl.add_example(
'May I change my ticket?',
'SELECT content from policies
order by embedding <=> embedding(''text-embedding-005'',''May I change my ticket?'')::vector asc
limit 5;',
'cymbal_air_demo_cfg');

SELECT alloydb_ai_nl.add_example(
 'flight B6 415 on September 15 2025',
 'select * from flights where airline=''B6'' and flight_number=''415'' and DATE("departure_time") = ''2025-09-15'';',
 'cymbal_air_demo_cfg');
```

### 3. Generate SQL results from natural language questions

```
--1. Show the generated SQL, copy paste it and execute it manually
SELECT
  alloydb_ai_nl.get_sql(
      'cymbal_air_demo_cfg',
      'Which flights are available from JFK to SFO on May 22 2025'
  ) ->> 'sql';


--execute it directly
SELECT
alloydb_ai_nl.execute_nl_query(
   'Which flights are available from JFK to SFO on May 22 2025',
   'cymbal_air_demo_cfg'
);

```

