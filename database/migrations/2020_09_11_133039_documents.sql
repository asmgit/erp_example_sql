CREATE TABLE document_types (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT
    , credit_type TINYINT NOT NULL CHECK (credit_type IN (-1, 0, 1))
      COMMENT 'Влияние на баланс: -1 - кредитовый документ, 1 - дебетовый документ, 0 - не влияет на баланс'
    , name VARCHAR(191) NOT NULL UNIQUE
) COMMENT='Типы документов'
;
CREATE TABLE organizations (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT
    , type ENUM('address', 'ur', 'manufacturer', 'client') NOT NULL
      COMMENT 'address - подразделение/склад, ur - Юрлицо, manufacturer - производитель, client - клиент'
    , name VARCHAR(191) NOT NULL UNIQUE
) COMMENT='Организации'
;
CREATE TABLE materials (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT
    , name VARCHAR(191) NOT NULL UNIQUE
    , organization_id_manufacturer INT UNSIGNED NOT NULL COMMENT 'Производитель'
    , CONSTRAINT materials_organization_id_manufacturer FOREIGN KEY (organization_id_manufacturer) REFERENCES organizations (id)
) COMMENT='Материалы/Товары'
;
CREATE TABLE documents (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT
    , date DATE NOT NULL
    , document_type_id INT UNSIGNED NOT NULL COMMENT 'Тип документа'
    , organization_id_address INT UNSIGNED NOT NULL COMMENT 'Склад'
    , organization_id_ur INT UNSIGNED NOT NULL COMMENT 'Юрлицо'
    , organization_id_client INT UNSIGNED NOT NULL COMMENT 'Клиент'
    , closed BOOLEAN DEFAULT 0 NOT NULL CHECK (closed IN (0, 1)) COMMENT '1 - документ закрыт, 0 - документ открыт'
    , CONSTRAINT documents_document_type_id FOREIGN KEY (document_type_id) REFERENCES document_types (id)
    , CONSTRAINT documents_organization_id_address FOREIGN KEY (organization_id_address) REFERENCES organizations (id)
    , CONSTRAINT documents_organization_id_ur FOREIGN KEY (organization_id_ur) REFERENCES organizations (id)
    , CONSTRAINT documents_organization_id_client FOREIGN KEY (organization_id_client) REFERENCES organizations (id)
) COMMENT='Документы'
;
CREATE TABLE document_positions (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT
    , document_id INT UNSIGNED NOT NULL COMMENT 'Документ'
    , material_id INT UNSIGNED NOT NULL COMMENT 'Материал'
    , cnt INT COMMENT 'Количество'
    , price decimal(29,15) COMMENT 'Цена'
    , KEY (document_id, material_id, cnt)
    , KEY (material_id)
    , CONSTRAINT document_positions_document_id FOREIGN KEY (document_id) REFERENCES documents (id)
    , CONSTRAINT document_positions_material_id FOREIGN KEY (material_id) REFERENCES materials (id)
) COMMENT='Позиции документов'
;
CREATE TABLE current_stock (
    organization_id_address INT UNSIGNED NOT NULL COMMENT 'Склад'
    , organization_id_ur INT UNSIGNED NOT NULL COMMENT 'Юрлицо'
    , material_id INT UNSIGNED NOT NULL COMMENT 'Материал'
    , cnt INT NOT NULL DEFAULT 0 COMMENT 'Количество'
    , reserve INT NOT NULL DEFAULT 0 COMMENT 'Резерв'
    , PRIMARY KEY (organization_id_address, organization_id_ur, material_id)
    , CONSTRAINT current_stock_organization_id_address FOREIGN KEY (organization_id_address) REFERENCES organizations (id)
    , CONSTRAINT current_stock_organization_id_ur FOREIGN KEY (organization_id_ur) REFERENCES organizations (id)
    , CONSTRAINT current_stock_material_id FOREIGN KEY (material_id) REFERENCES materials (id)
) COMMENT='Текущие остатки материалов'
;
-- MIGRATION_ROLLBACK
-- write rollback migration below (do not change these comments)

DROP TABLE current_stock
;
DROP TABLE document_positions
;
DROP TABLE documents
;
DROP TABLE materials
;
DROP TABLE organizations
;
DROP TABLE document_types
;