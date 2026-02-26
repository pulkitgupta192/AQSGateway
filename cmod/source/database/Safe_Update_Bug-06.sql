SET SERVEROUTPUT ON;

DECLARE
    v_cutoff_date DATE := ADD_MONTHS(SYSDATE, -12); -- Orders older than 1 year
    v_order_count NUMBER := 0;
BEGIN
    -- Step 1: Count how many we are moving
    SELECT COUNT(*) INTO v_order_count 
    FROM orders 
    WHERE order_date < v_cutoff_date;

    DBMS_OUTPUT.PUT_LINE('Archiving ' || v_order_count || ' orders...');

    -- Step 2: Move data to history table
    INSERT INTO orders_history
    SELECT * FROM orders WHERE order_date < v_cutoff_date;

    -- BUG 1: The Parent-Child Trap
    -- We are deleting from the Parent table without checking the Child table (order_items)
    DELETE FROM orders 
    WHERE order_date < v_cutoff_date;

    -- BUG 2: The "Divide by Zero" Logic
    -- This will crash if v_order_count is 0 because we didn't check it first
    DBMS_OUTPUT.PUT_LINE('Average archive batch size: ' || (v_order_count / v_order_count));

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Archive successful.');

EXCEPTION
    WHEN OTHERS THEN
        -- BUG 3: The "Silent Failure"
        -- We are printing the error, but did we ROLLBACK? 
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
        -- ROLLBACK; -- Missing!
END;
/