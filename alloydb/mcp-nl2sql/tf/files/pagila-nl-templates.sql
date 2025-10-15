-- This file contains a single, complete 'blueprint' template.
-- It's designed to teach the model how to solve a highly complex,
-- multi-step analytical query that it cannot compose on its own.
-- By providing this parameterized template, the model can learn the
-- overall pattern and apply it to similar questions with different parameters.

SELECT alloydb_ai_nl.add_template(
  nl_config_id => 'pagila_demo_cfg',
  intent => 'For store 1, what are the top 2 film categories by revenue, and who is the most frequent actor in each?',
  sql => E'WITH CategoryRevenue AS (
             SELECT
                 i.store_id,
                 fc.category_id,
                 c.name as category_name,
                 SUM(p.amount) AS total_category_revenue,
                 ROW_NUMBER() OVER(PARTITION BY i.store_id ORDER BY SUM(p.amount) DESC) as category_rank
             FROM payment p
             JOIN rental r ON p.rental_id = r.rental_id
             JOIN inventory i ON r.inventory_id = i.inventory_id
             JOIN film_category fc ON i.film_id = fc.film_id
             JOIN category c ON fc.category_id = c.category_id
             WHERE i.store_id = 1
             GROUP BY i.store_id, fc.category_id, c.name
         ), TopCategories AS (
             SELECT store_id, category_id, category_name FROM CategoryRevenue WHERE category_rank <= 2
         ), ActorFilmCounts AS (
             SELECT
                 tc.store_id,
                 tc.category_id,
                 fa.actor_id,
                 ROW_NUMBER() OVER(PARTITION BY tc.store_id, tc.category_id ORDER BY COUNT(fa.film_id) DESC, fa.actor_id) as actor_rank
             FROM TopCategories tc
             JOIN film_category fc ON tc.category_id = fc.category_id
             JOIN film_actor fa ON fc.film_id = fa.film_id
             GROUP BY tc.store_id, tc.category_id, fa.actor_id
         )
       SELECT
           afc.store_id,
           tc.category_name,
           a.first_name,
           a.last_name
       FROM ActorFilmCounts afc
       JOIN TopCategories tc ON afc.store_id = tc.store_id AND afc.category_id = tc.category_id
       JOIN actor a ON afc.actor_id = a.actor_id
       WHERE afc.actor_rank = 1;',
  parameterized_sql => E'WITH CategoryRevenue AS (
       SELECT
           i.store_id,
           fc.category_id,
           c.name as category_name,
           SUM(p.amount) AS total_category_revenue,
           ROW_NUMBER() OVER(PARTITION BY i.store_id ORDER BY SUM(p.amount) DESC) as category_rank
       FROM payment p
       JOIN rental r ON p.rental_id = r.rental_id
       JOIN inventory i ON r.inventory_id = i.inventory_id
       JOIN film_category fc ON i.film_id = fc.film_id
       JOIN category c ON fc.category_id = c.category_id
       WHERE i.store_id = $1
       GROUP BY i.store_id, fc.category_id, c.name
   ), TopCategories AS (
       SELECT store_id, category_id, category_name FROM CategoryRevenue WHERE category_rank <= $2
   ), ActorFilmCounts AS (
       SELECT
           tc.store_id,
           tc.category_id,
           fa.actor_id,
           ROW_NUMBER() OVER(PARTITION BY tc.store_id, tc.category_id ORDER BY COUNT(fa.film_id) DESC, fa.actor_id) as actor_rank
       FROM TopCategories tc
       JOIN film_category fc ON tc.category_id = fc.category_id
       JOIN film_actor fa ON fc.film_id = fa.film_id
       GROUP BY tc.store_id, tc.category_id, fa.actor_id
   )
   SELECT
       afc.store_id,
       tc.category_name,
       a.first_name,
       a.last_name
   FROM ActorFilmCounts afc
   JOIN TopCategories tc ON afc.store_id = tc.store_id AND afc.category_id = tc.category_id
   JOIN actor a ON afc.actor_id = a.actor_id
   WHERE afc.actor_rank = 1;',
  parameterized_intent => 'For store $1, what are the top $2 film categories by revenue, and who is the most frequent actor in each?'
);

