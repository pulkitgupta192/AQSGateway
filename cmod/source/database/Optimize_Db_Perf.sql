-- Create a dummy sales table
CREATE TABLE perf_test (
    id SERIAL PRIMARY KEY,
    user_id INT,
    amount DECIMAL(10,2),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Generate 100,000 rows of random data
INSERT INTO perf_test (user_id, amount, transaction_date)
SELECT 
    floor(random() * 10000 + 1)::int, 
    (random() * 500)::decimal(10,2),
    now() - (random() * interval '365 days')
FROM generate_series(1, 100000);