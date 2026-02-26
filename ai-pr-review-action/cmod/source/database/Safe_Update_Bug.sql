SET SERVEROUTPUT ON;

DECLARE
    v_update_count NUMBER := 0;
    v_threshold    NUMBER := 5000; -- High-value customer threshold
BEGIN
    -- This block updates customers to 'VIP' status if they spent over 5000
    UPDATE customers c
    SET c.status = 'VIP'
    WHERE c.customer_id IN (
        SELECT o.customer_id 
        FROM orders o 
        GROUP BY o.customer_id 
        HAVING SUM(o.total_amount) > v_threshold
    )

    v_update_count := SQL%ROWCOUNT;
    
    DBMS_OUTPUT.PUT_LINE('Correction complete. Rows updated: ' || v_update_count);
    
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error detected: ' || SQLERRM);
END;
/