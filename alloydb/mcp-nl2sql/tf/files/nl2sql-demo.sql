--1. Show the generated SQL, copy paste it and execute it manually
SELECT
  alloydb_ai_nl.get_sql(
      'pagila_demo_cfg',
      'Show me our top 10 most-rented action movies from last month'
  ) ->> 'sql';

--execute it directly
SELECT
alloydb_ai_nl.execute_nl_query(
   'pagila_demo_cfg',
   'Show me our top 10 most-rented action movies from last month'
);

--2. Customers by city
SELECT
  alloydb_ai_nl.get_sql(
      'pagila_demo_cfg',
      'How many customers do we have by city'
) ->> 'sql';

SELECT
alloydb_ai_nl.execute_nl_query(
   'pagila_demo_cfg',
   'How many customers do we have by city'
);

--3. Complex query
--   For this to work, we will need to add a template to help the model!
SELECT
  alloydb_ai_nl.get_sql(
      'pagila_demo_cfg',
      'For each store, identify the top 10 film categories that have generated the most rental revenue. Within each of those top categories, find the single actor who has appeared in the most films. Finally, for that specific actor, calculate their total rental revenue within that category and store, and express this as a percentage of the category total revenue for that store.'
  ) ->> 'sql';

SELECT
alloydb_ai_nl.execute_nl_query(
   'pagila_demo_cfg',
   'For each store, identify the top 10 film categories that have generated the most rental revenue. Within each of those top categories, find the single actor who has appeared in the most films. Finally, for that specific actor, calculate their total rental revenue within that category and store, and express this as a percentage of the category total revenue for that store.'
);
