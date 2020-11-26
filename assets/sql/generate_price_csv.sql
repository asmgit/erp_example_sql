SET @@cte_max_recursion_depth = 999999
;
WITH RECURSIVE p(n) AS (
    SELECT 5000 n
    UNION ALL
    SELECT n + 1 n FROM p WHERE n + 1 <= 55000
)
SELECT CONCAT('Товар ', n) name
, CONCAT('Производитель ', FLOOR(1 + (RAND() * (12 - 1 + 1)))) manufacturer
, ROUND(RAND() * 10000, 2) price
, CASE FLOOR(RAND() * 3) WHEN 0 THEN 'Р' WHEN 1 THEN '$' WHEN 2 THEN 'Е' END currency
FROM p
