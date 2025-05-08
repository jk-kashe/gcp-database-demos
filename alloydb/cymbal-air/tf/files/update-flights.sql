UPDATE your_table_name
SET
    arrival_time = MAKE_TIMESTAMP(
        EXTRACT(YEAR FROM CURRENT_TIMESTAMP)::integer,
        EXTRACT(MONTH FROM arrival_time)::integer,
        EXTRACT(DAY FROM arrival_time)::integer,
        EXTRACT(HOUR FROM arrival_time)::integer,
        EXTRACT(MINUTE FROM arrival_time)::integer,
        EXTRACT(SECOND FROM arrival_time)
    ),
    departure_time = MAKE_TIMESTAMP(
        EXTRACT(YEAR FROM CURRENT_TIMESTAMP)::integer,
        EXTRACT(MONTH FROM departure_time)::integer,
        EXTRACT(DAY FROM departure_time)::integer,
        EXTRACT(HOUR FROM departure_time)::integer,
        EXTRACT(MINUTE FROM departure_time)::integer,
        EXTRACT(SECOND FROM departure_time)
    );