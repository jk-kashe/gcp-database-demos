--Create agentspace user
DO $$
BEGIN
   IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'agent') THEN
      RAISE NOTICE 'Role ''agent'' already exists. Dropping it.';
      DROP ROLE "agent";
   END IF;
END
$$;
CREATE ROLE agent WITH LOGIN PASSWORD '${agent_password}';
GRANT SELECT ON TABLE public.actor to agent;
GRANT SELECT ON TABLE public.address to agent;
GRANT SELECT ON TABLE public.category to agent;
GRANT SELECT ON TABLE public.city to agent;
GRANT SELECT ON TABLE public.country to agent;
GRANT SELECT ON TABLE public.customer to agent;
GRANT SELECT ON TABLE public.film to agent;
GRANT SELECT ON TABLE public.film_actor to agent;
GRANT SELECT ON TABLE public.film_category to agent;
GRANT SELECT ON TABLE public.inventory to agent;
GRANT SELECT ON TABLE public.language to agent;
GRANT SELECT ON TABLE public.payment to agent;
GRANT SELECT ON TABLE public.rental to agent;
GRANT SELECT ON TABLE public.staff to agent;
GRANT SELECT ON TABLE public.store to agent;
GRANT SELECT ON TABLE public.actor_info to agent;
GRANT SELECT ON TABLE public.customer_list to agent;
GRANT SELECT ON TABLE public.film_list to agent;
GRANT SELECT ON TABLE public.nicer_but_slower_film_list to agent;
GRANT SELECT ON TABLE public.sales_by_film_category to agent;
GRANT SELECT ON TABLE public.sales_by_store to agent;
GRANT SELECT ON TABLE public.staff_list to agent;
GRANT SELECT ON TABLE public.rental_by_category to agent;
