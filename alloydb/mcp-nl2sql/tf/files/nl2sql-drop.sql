DO $$
DECLARE
    template_id_to_drop BIGINT;
    example_id_to_drop BIGINT;
BEGIN
    -- Step 1: Drop all associated templates
    RAISE NOTICE 'Dropping templates for pagila_demo_cfg...';
    FOR template_id_to_drop IN
        SELECT id FROM alloydb_ai_nl.template_store_view WHERE config = 'pagila_demo_cfg'
    LOOP
        RAISE NOTICE '  -> Dropping template ID: %', template_id_to_drop;
        PERFORM alloydb_ai_nl.drop_template(template_id_to_drop);
    END LOOP;

    -- Step 2: Drop all associated examples
    RAISE NOTICE 'Dropping examples for pagila_demo_cfg...';
    FOR example_id_to_drop IN
        SELECT example_id FROM alloydb_ai_nl.g_example_store WHERE example_context = 'pagila_demo_cfg'
    LOOP
        RAISE NOTICE '  -> Dropping example ID: %', example_id_to_drop;
        PERFORM alloydb_ai_nl.drop_example(example_id_to_drop);
    END LOOP;

    -- Step 3: Drop the main configuration itself
    RAISE NOTICE 'Dropping main configuration: pagila_demo_cfg...';
    PERFORM alloydb_ai_nl.g_manage_configuration('drop_configuration', 'pagila_demo_cfg');

    RAISE NOTICE 'Cleanup for pagila_demo_cfg is complete.';
END $$;
