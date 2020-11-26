SET @@cte_max_recursion_depth = 999999
;
SET @clients_count = 5000
, @materials_count = 50000
, @documents_count = 100000
, @positions_per_document = 150
;
SET FOREIGN_KEY_CHECKS = 0, SQL_LOG_BIN = 0, UNIQUE_CHECKS = 0
;
TRUNCATE TABLE current_stock;
TRUNCATE TABLE document_positions;
TRUNCATE TABLE documents;
TRUNCATE TABLE materials;
TRUNCATE TABLE organizations;
TRUNCATE TABLE document_types;

INSERT document_types (id, credit_type, name)
VALUES (1, 1, 'Отгрузка покупателю')
, (2, -1, 'Приход от поставщика')
, (6, 0, 'ЗПС')
, (8, 0, 'План производства')
;
INSERT organizations (type, name)
VALUES ('address', 'Склад 1')
, ('address', 'Склад 2')
, ('address', 'Склад 3')
, ('address', 'Склад 4')
, ('ur', 'Юрлицо 1')
, ('ur', 'Юрлицо 2')
, ('ur', 'Юрлицо 3')
, ('manufacturer', 'Производитель 1')
, ('manufacturer', 'Производитель 2')
, ('manufacturer', 'Производитель 3')
, ('manufacturer', 'Производитель 4')
, ('manufacturer', 'Производитель 5')
, ('manufacturer', 'Производитель 6')
, ('manufacturer', 'Производитель 7')
, ('manufacturer', 'Производитель 8')
, ('manufacturer', 'Производитель 9')
, ('manufacturer', 'Производитель 10')
, ('manufacturer', 'Производитель 11')
;
INSERT organizations (type, name)
WITH RECURSIVE p(n) AS (
    SELECT 1 n
    UNION ALL
    SELECT n + 1 n FROM p WHERE n + 1 <= @clients_count
)
SELECT 'client', CONCAT('Клиент ', p.n) name
FROM p
;
SELECT MIN(IF(type = 'address', id, NULL)) min_address_id
, MAX(IF(type = 'address', id, NULL)) max_address_id
, MIN(IF(type = 'ur', id, NULL)) min_ur_id
, MAX(IF(type = 'ur', id, NULL)) max_ur_id
, MIN(IF(type = 'manufacturer', id, NULL)) min_manufacturer_id
, MAX(IF(type = 'manufacturer', id, NULL)) max_manufacturer_id
, MIN(IF(type = 'client', id, NULL)) min_client_id
, MAX(IF(type = 'client', id, NULL)) max_client_id
FROM organizations
INTO @min_address_id
, @max_address_id
, @min_ur_id
, @max_ur_id
, @min_manufacturer_id
, @max_manufacturer_id
, @min_client_id
, @max_client_id
;
INSERT materials (name, organization_id_manufacturer)
WITH RECURSIVE p(n) AS (
    SELECT 1 n
    UNION ALL
    SELECT n + 1 n FROM p WHERE n + 1 <= @materials_count
)
SELECT CONCAT('Товар ', n) name
, FLOOR(@min_manufacturer_id + (RAND() * (@max_manufacturer_id - @min_manufacturer_id + 1))) organization_id_manufacturer
FROM p
;
INSERT documents (date, document_type_id, organization_id_address, organization_id_ur, organization_id_client, closed)
WITH RECURSIVE p(n, date) AS (
    SELECT 1 n
    , DATE(NOW() - INTERVAL FLOOR(0 + (RAND() * 365)) DAY) date
    UNION ALL
    SELECT n + 1 n
    , DATE(NOW() - INTERVAL FLOOR(0 + (RAND() * 365)) DAY) date
    FROM p WHERE n + 1 <= @documents_count
)
SELECT date
, CASE FLOOR(1 + (RAND() * 4)) WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 6 WHEN 4 THEN 8 END document_type_id
, FLOOR(@min_address_id + (RAND() * (@max_address_id - @min_address_id + 1))) organization_id_address
, FLOOR(@min_ur_id + (RAND() * (@max_ur_id - @min_ur_id + 1))) organization_id_ur
, FLOOR(@min_client_id + (RAND() * (@max_client_id - @min_client_id + 1))) organization_id_client
, IF(date < DATE(NOW() - INTERVAL 30 DAY), 1, 0)
FROM p
;
ALTER TABLE document_positions
DROP CONSTRAINT document_positions_document_id
, DROP CONSTRAINT document_positions_material_id
, DROP KEY document_id
, DROP KEY material_id
;
INSERT document_positions (document_id, material_id, cnt)
WITH RECURSIVE p(n) AS (
    SELECT 1 n
    UNION ALL
    SELECT n + 1 n FROM p WHERE n + 1 <= @positions_per_document
)
, d AS (
    SELECT d.id document_id
    , FLOOR(1 + (RAND() * @materials_count)) material_id
    FROM p
    CROSS JOIN documents d
)
SELECT document_id, material_id
, FLOOR(1 + (RAND() * 1000)) cnt
FROM d
;
ALTER TABLE document_positions ADD KEY (document_id, material_id, cnt)
;
ALTER TABLE document_positions ADD KEY (material_id)
;
ALTER TABLE document_positions ADD CONSTRAINT document_positions_document_id FOREIGN KEY (document_id) REFERENCES documents (id)
;
ALTER TABLE document_positions ADD CONSTRAINT document_positions_material_id FOREIGN KEY (material_id) REFERENCES materials (id)
;
ALTER TABLE current_stock
DROP CONSTRAINT current_stock_material_id
, DROP CONSTRAINT current_stock_organization_id_address
, DROP CONSTRAINT current_stock_organization_id_ur
, DROP KEY current_stock_material_id
, DROP KEY current_stock_organization_id_ur
;
INSERT INTO current_stock (organization_id_address, organization_id_ur, material_id, cnt, reserve)
SELECT d.organization_id_address, d.organization_id_ur, dp.material_id
, SUM(IF(d.closed = 1, IFNULL(dp.cnt, 0) * t.credit_type * -1, 0)) cnt
, SUM(IF(d.closed = 1, 0, IFNULL(dp.cnt, 0) * IF(t.credit_type = 1, 1, 0))) reserve
FROM documents d
INNER JOIN document_positions dp ON d.id = dp.document_id
INNER JOIN document_types t ON d.document_type_id = t.id
WHERE IFNULL(dp.cnt, 0) != 0
AND t.credit_type IN (-1, 1)
GROUP BY d.organization_id_address, d.organization_id_ur, dp.material_id
HAVING cnt != 0 OR reserve != 0
;
ALTER TABLE current_stock ADD KEY current_stock_material_id (material_id)
;
ALTER TABLE current_stock ADD KEY current_stock_organization_id_ur (organization_id_ur)
;
ALTER TABLE current_stock ADD CONSTRAINT current_stock_organization_id_address FOREIGN KEY (organization_id_address) REFERENCES organizations (id)
;
ALTER TABLE current_stock ADD CONSTRAINT current_stock_organization_id_ur FOREIGN KEY (organization_id_ur) REFERENCES organizations (id)
;
ALTER TABLE current_stock ADD CONSTRAINT current_stock_material_id FOREIGN KEY (material_id) REFERENCES materials (id)
;
SET FOREIGN_KEY_CHECKS = 1, SQL_LOG_BIN = 1, UNIQUE_CHECKS = 1
;