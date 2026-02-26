SET SERVEROUTPUT ON;

DECLARE
    -- Cursor to find active customers
    CURSOR c_customers IS 
        SELECT customer_id, balance FROM customers WHERE status = 'ACTIVE';
        
    v_cust_id      NUMBER;
    v_cust_balance VARCHAR2(100); -- BUG 1: Why is this a string for a math operation?
    v_bonus_amount NUMBER;
BEGIN
    OPEN c_customers;
    
    LOOP
        FETCH c_customers INTO v_cust_id, v_cust_balance;
        
        -- Calculate 5% bonus
        v_bonus_amount := v_cust_balance * 0.05;

        UPDATE customers 
        SET balance = balance + v_bonus_amount
        WHERE customer_id = v_cust_id;

        -- BUG 2: Where is the exit condition?
        DBMS_OUTPUT.PUT_LINE('Processed ID: ' || v_cust_id);
    END LOOP;

    CLOSE c_customers;
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        IF c_customers%ISOPEN THEN
            CLOSE c_customers;
        END IF;
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/