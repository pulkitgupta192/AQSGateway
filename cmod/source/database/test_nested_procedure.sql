-- ==========================================
-- SAMPLE NESTED PROCEDURE TEST SCRIPT
-- ==========================================

SET SERVEROUTPUT ON
PROMPT Starting Nested Procedure Test...

-- ==========================================
-- 1. DROP TABLE IF EXISTS
-- ==========================================

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE orders_test';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

-- ==========================================
-- 2. CREATE TABLE
-- ==========================================

CREATE TABLE orders_test (
    order_id     NUMBER PRIMARY KEY,
    customer     VARCHAR2(100),
    amount       NUMBER(10,2),
    status       VARCHAR2(20),
    created_date DATE DEFAULT SYSDATE
);

-- ==========================================
-- 3. INSERT SAMPLE DATA
-- ==========================================

INSERT INTO orders_test VALUES (101, 'Pulkit', 15000, 'NEW', SYSDATE);
INSERT INTO orders_test VALUES (102, 'Anita', 8000,  'NEW', SYSDATE);
INSERT INTO orders_test VALUES (103, 'Rahul', 20000, 'NEW', SYSDATE);

COMMIT;

-- ==========================================
-- 4. CHILD PROCEDURE (CALCULATE DISCOUNT)
-- ==========================================

CREATE OR REPLACE PROCEDURE apply_discount (
    p_order_id IN NUMBER
)
IS
BEGIN
   UPDATE orders_test
   SET amount = amount * 0.90
   WHERE order_id = p_order_id;

   DBMS_OUTPUT.PUT_LINE('Discount applied to Order ID: ' || p_order_id);
END;
/

-- ==========================================
-- 5. MAIN PROCEDURE (CALLS CHILD PROCEDURE)
-- ==========================================

CREATE OR REPLACE PROCEDURE process_order (
    p_order_id IN NUMBER
)
IS
   v_amount orders_test.amount%TYPE;
BEGIN
   -- Get current amount
   SELECT amount INTO v_amount
   FROM orders_test
   WHERE order_id = p_order_id;

   -- If order > 10000 apply discount
   IF v_amount > 10000 THEN
      apply_discount(p_order_id);
   END IF;

   -- Update status
   UPDATE orders_test
   SET status = 'PROCESSED'
   WHERE order_id = p_order_id;

   COMMIT;

   DBMS_OUTPUT.PUT_LINE('Order processed successfully.');

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Order not found.');
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- ==========================================
-- 6. TEST EXECUTION
-- ==========================================

BEGIN
   process_order(101);
   process_order(102);
END;
/

-- ==========================================
-- 7. VERIFY RESULTS
-- ==========================================

SELECT * FROM orders_test;

PROMPT Nested Procedure Test Completed.