SET SERVEROUTPUT ON;

DECLARE
    -- We want to delete sessions older than 30 days
    last_login_date DATE := SYSDATE - 30; 
    v_deleted_count NUMBER := 0;
BEGIN
    
    DELETE FROM user_sessions
    -- BUG IS HERE: Look at the column name vs the variable name
    WHERE last_login_date <= last_login_date; 

    v_deleted_count := SQL%ROWCOUNT;

    DBMS_OUTPUT.PUT_LINE('Cleanup complete. Deleted ' || v_deleted_count || ' sessions.');
    
    -- Safety check: If we deleted more than 1000, maybe something is wrong?
    IF v_deleted_count > 1000 THEN
        DBMS_OUTPUT.PUT_LINE('Validation failed: Too many rows affected. Rolling back.');
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/