SET SERVEROUTPUT ON;

DECLARE
    v_rows_affected NUMBER := 0;
    v_error_msg     VARCHAR2(4000);
BEGIN
    -- 1. Perform the correction
    UPDATE employees 
    SET salary = salary * 1.10
    WHERE department_id = 10 
      AND commission_pct IS NULL;

    -- 2. Capture the count
    v_rows_affected := SQL%ROWCOUNT;

    -- 3. Validation Logic (Optional)
    IF v_rows_affected = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Warning: No rows met the criteria for correction.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Success: ' || v_rows_affected || ' rows updated.');
        -- COMMIT only if we are happy with the results
        COMMIT; 
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- 4. Safety Net
        ROLLBACK;
        v_error_msg := SQLERRM;
        DBMS_OUTPUT.PUT_LINE('Correction Failed. Rolling back changes.');
        DBMS_OUTPUT.PUT_LINE('Error: ' || v_error_msg);
END;
/