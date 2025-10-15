--Update rental dates to current timeframe.
DO $$
DECLARE
    delta_interval interval;
BEGIN
    -- Calculate the delta ONCE, before any updates are made
    SELECT (CURRENT_DATE - INTERVAL '1 day') - MAX(return_date)
    INTO delta_interval
    FROM rental;

    -- Now, apply the same calculated delta to both tables
    RAISE NOTICE 'Applying offset: %', delta_interval;

    UPDATE rental
    SET rental_date = rental_date + delta_interval,
        return_date = return_date + delta_interval;
    
    --we need default partition for new dates
    CREATE TABLE payment_default PARTITION OF payment DEFAULT;

    UPDATE payment
    SET payment_date = payment_date + delta_interval;
END $$;
