SET @@cte_max_recursion_depth = 999999
;
SET @exchange_rate_days = 1500
-- кол-во дней для прайсов
, @price_days = 200
;
SET FOREIGN_KEY_CHECKS = 0, SQL_LOG_BIN = 0, UNIQUE_CHECKS = 0
;

TRUNCATE TABLE client_price
;
TRUNCATE TABLE promo_discounts
;
TRUNCATE TABLE prices
;
TRUNCATE TABLE exchange_rate
;
TRUNCATE TABLE currency
;
TRUNCATE TABLE price_types
;
INSERT price_types (id, name)
VALUES (1, 'Себестоимость')
, (2, 'Оптовый')
, (3, 'Розничный')
, (4, 'Прайс Поставщика 1')
;
INSERT currency (id, name, abbr)
VALUES (1, 'Рубль', 'Р')
, (2, 'Доллар', '$')
, (3, 'Евро', 'Е')
;
INSERT exchange_rate (currency_id, date, value)
WITH RECURSIVE p(n) AS (
    SELECT 1 n
    UNION ALL
    SELECT n + 1 n FROM p WHERE n + 1 <= @exchange_rate_days
)
, c AS (
    SELECT c.*, IF(c.abbr = '$', 70, 80) base_value
    FROM currency c
    WHERE id IN (2, 3)
)
SELECT c.id, DATE(NOW()) - INTERVAL p.n + 1 DAY date, c.base_value + RAND() * 20 value
FROM c
CROSS JOIN p
;
-- заполним прайсы
DROP TEMPORARY TABLE IF EXISTS tmp_prices
;
CREATE TEMPORARY TABLE tmp_prices
WITH RECURSIVE p(n) AS (
    SELECT @price_days n
    UNION ALL
    SELECT n - 1 n FROM p WHERE n - 1 >= 1
)
SELECT DATE(NOW()) - INTERVAL IF(p.n = @price_days, p.n + 2000, p.n) DAY date
, pt.id price_type_id
, m.id material_id
, CASE
    -- на первую дату заполним всегда
    WHEN p.n = @price_days
     -- Для прайса Себестоимость цена меняется часто
     OR pt.id = 1 AND RAND() < 0.5
     -- Для остальных прайсов цена меняется редко
     OR pt.id != 1 AND RAND() < 0.01
    THEN RAND() * 10000
  END price
, CASE
    WHEN pt.id = 1 THEN 1
    ELSE FLOOR(1 + (RAND() * 3))
  END currency_id
FROM p
CROSS JOIN price_types pt
CROSS JOIN materials m
;
INSERT prices (date, price_type_id, material_id, price, currency_id)
SELECT *
FROM tmp_prices
WHERE price IS NOT NULL
;
DROP TEMPORARY TABLE IF EXISTS tmp_prices
;
INSERT promo_discounts (material_id, beg_date, end_date, price_type_id, coefficient)
SELECT id
, DATE(NOW()) - INTERVAL FLOOR(300 + (RAND() * 300)) DAY beg_date
, DATE(NOW()) - INTERVAL 299 DAY end_date
, 1 price_type_id
, 0.5 coefficient
FROM materials
ORDER BY RAND()
LIMIT 10000
;
INSERT promo_discounts (material_id, beg_date, end_date, price_type_id, coefficient)
SELECT id
, DATE(NOW()) - INTERVAL FLOOR(1 + (RAND() * 299)) DAY beg_date
, NULL end_date
, 1 price_type_id
, 0.5 coefficient
FROM materials
ORDER BY RAND()
LIMIT 10000
;
SELECT MIN(id), MAX(id)
INTO @min_manufacturer_id, @max_manufacturer_id
FROM organizations
WHERE type = 'manufacturer'
;
SET @materials_count = (SELECT COUNT(*) FROM materials)
;
INSERT client_price (organization_id, price_type_id, organization_id_manufacturer, material_id, coefficient)
WITH RECURSIVE p(n, type) AS (
    SELECT 1 n, CAST('main_price' AS CHAR(50)) type
    UNION ALL
    SELECT n + 1 n
    , CASE
        WHEN n + 1 BETWEEN 2 AND 4 THEN 'manufacturer_price'
        WHEN n + 1 > 4 THEN 'material_price'
      END type
    FROM p
    WHERE n + 1 <= 20
)
, d AS (
    SELECT DISTINCT o.id organization_id
    , IF(p.type = 'manufacturer_price'
      , FLOOR(@min_manufacturer_id + (RAND() * (@max_manufacturer_id - @min_manufacturer_id + 1)))
      , NULL
      ) organization_id_manufacturer
    , IF(p.type = 'material_price'
      , FLOOR(1 + (RAND() * @materials_count))
      , NULL
      ) material_id
    FROM organizations o
    CROSS JOIN p
    WHERE o.type = 'client'
)
SELECT organization_id
, FLOOR(2 + (RAND() * 2)) price_type_id
, organization_id_manufacturer
, material_id
, ROUND(1 - RAND() / 10, 5) coefficient
FROM d
;
SET FOREIGN_KEY_CHECKS = 1, SQL_LOG_BIN = 1, UNIQUE_CHECKS = 1
;