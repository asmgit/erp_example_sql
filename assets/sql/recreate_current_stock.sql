TRUNCATE TABLE current_stock
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
