-- ==========================================
-- SAMPLE SQL TEST PROGRAM
-- ==========================================

SET SERVEROUTPUT ON
PROMPT Starting Test Script...

-- ==========================================
-- 1. DROP OBJECTS IF EXIST (IGNORE ERRORS)
-- ==========================================

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE employees_test';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- ==========================================
-- 2. CREATE TABLE
-- ==========================================

CREATE TABLE employees_test (
    emp_id        NUMBER PRIMARY KEY,
    emp_name      VARCHAR2(100),
    salary        NUMBER(10,2),
    created_date  DATE DEFAULT SYSDATE
);

-- ==========================================
-- 3. INSERT SAMPLE DATA
-- ==========================================

INSERT INTO employees_test VALUES (1, 'Pulkit', 50000, SYSDATE);
INSERT INTO employees_test VALUES (2, 'Anita', 60000, SYSDATE);
INSERT INTO employees_test VALUES (3, 'Rahul', 45000, SYSDATE);

COMMIT;

-- ==========================================
-- 4. CREATE FUNCTION (BONUS CALCULATION)
-- ==========================================

CREATE OR REPLACE FUNCTION calculate_bonus (
    p_salary NUMBER
) RETURN NUMBER
IS
BEGIN
    RETURN p_salary * 0.10;
END;
/

-- ==========================================
-- 5. CREATE PROCEDURE (UPDATE SALARY)
-- ==========================================

CREATE OR REPLACE PROCEDURE increase_salary (
    p_emp_id   NUMBER,
    p_percent  NUMBER
)
IS
BEGIN
    UPDATE employees_test
    SET salary = salary + (salary * p_percent / 100)
    WHERE emp_id = p_emp_id;

    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Salary updated successfully.');
END;
/

-- ==========================================
-- 6. CREATE TRIGGER (AUDIT MESSAGE)
-- ==========================================

CREATE OR REPLACE TRIGGER trg_salary_update
BEFORE UPDATE OF salary ON employees_test
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Salary changed from ' || :OLD.salary || 
        ' to ' || :NEW.salary
    );
END;
/

-- ==========================================
-- 7. TEST EXECUTION BLOCK
-- ==========================================

BEGIN
   increase_salary(1, 5);
   
   DBMS_OUTPUT.PUT_LINE(
      'Bonus for Emp 1: ' || calculate_bonus(52500)
   );
END;
/

-- ==========================================
-- 8. VERIFY DATA
-- ==========================================

SELECT * FROM employees_test;

PROMPT Test Script Completed.