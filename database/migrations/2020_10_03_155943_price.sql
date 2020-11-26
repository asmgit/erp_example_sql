CREATE TABLE price_types (
  id int UNSIGNED NOT NULL AUTO_INCREMENT
  , name varchar(100) DEFAULT NULL
  , PRIMARY KEY (id)
  , UNIQUE KEY (name)
) COMMENT='Типы прайсов'
;
CREATE TABLE currency (
  id int UNSIGNED NOT NULL AUTO_INCREMENT
  , name varchar(100) NOT NULL
  , abbr varchar(4) NOT NULL COMMENT 'Аббревиатура'
  , PRIMARY KEY (id)
  , UNIQUE KEY (name)
  , UNIQUE KEY (abbr)
) COMMENT='Типы валют'
;
CREATE TABLE exchange_rate (
  currency_id int UNSIGNED NOT NULL COMMENT 'Валюта'
  , date date NOT NULL COMMENT 'Дата'
  , value decimal(29,15) NOT NULL COMMENT 'Курс к рублю'
  , PRIMARY KEY (currency_id, date DESC)
  , CONSTRAINT exchange_rate_currency_id_fk FOREIGN KEY (currency_id) REFERENCES currency (id)
) COMMENT='Курсы валют на дату к рублю'
;
CREATE TABLE prices (
  date date NOT NULL
  , price_type_id int UNSIGNED NOT NULL COMMENT 'Тип прайса'
  , material_id int UNSIGNED NOT NULL COMMENT 'Материал'
  , price decimal(29,15) NOT NULL COMMENT 'Цена'
  , currency_id int UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Валюта'
  , PRIMARY KEY (price_type_id, material_id, date DESC)
  , KEY (material_id)
  , KEY (currency_id)
  , CONSTRAINT prices_material_id_fk FOREIGN KEY (material_id) REFERENCES materials (id)
  , CONSTRAINT prices_price_type_id_fk FOREIGN KEY (price_type_id) REFERENCES price_types (id)
  , CONSTRAINT prices_currency_id_fk FOREIGN KEY (currency_id) REFERENCES currency (id)
) COMMENT='Прайсы: цена по прайсам на дату'
;
CREATE TABLE promo_discounts (
  material_id int UNSIGNED NOT NULL COMMENT 'Материал'
  , beg_date date NOT NULL COMMENT 'Дата начала акции'
  , end_date date COMMENT 'Дата окончания акции'
  , price_type_id int UNSIGNED NOT NULL COMMENT 'Тип прайса'
  , coefficient decimal(10,5) NOT NULL DEFAULT 1 COMMENT 'Коэффициент'
  , PRIMARY KEY (material_id, beg_date DESC)
  , KEY (price_type_id)
  , CONSTRAINT promo_discounts_material_id_fk FOREIGN KEY (material_id) REFERENCES materials (id)
  , CONSTRAINT promo_discounts_price_type_id_fk FOREIGN KEY (price_type_id) REFERENCES price_types (id)
) COMMENT='Скидки бонусы акции'
;
CREATE TABLE client_price (
  organization_id int UNSIGNED NOT NULL COMMENT 'Клиент'
  , price_type_id int UNSIGNED NOT NULL COMMENT 'Тип прайса'
  , organization_id_manufacturer int UNSIGNED COMMENT 'Производитель'
  , material_id int UNSIGNED COMMENT 'Материал'
  , coefficient decimal(10,5) NOT NULL DEFAULT 1 COMMENT 'Коэффициент'
  , organization_id_manufacturer_for_pk int UNSIGNED AS (IFNULL(organization_id_manufacturer, 0)) STORED NOT NULL
  , material_id_for_pk int UNSIGNED AS (IFNULL(material_id, 0)) STORED NOT NULL
  , PRIMARY KEY (organization_id, organization_id_manufacturer_for_pk, material_id_for_pk)
  , UNIQUE KEY client_price_organization_id_material_id (organization_id, material_id)
  -- material_id и organization_id_manufacturer не могут быть одновременно заполнены
  , CONSTRAINT client_price_material_id_organization_id_manufacturer_chk
     CHECK (NOT (material_id IS NOT NULL AND organization_id_manufacturer IS NOT NULL))
  , KEY price_type_id (price_type_id)
  , KEY material_id (material_id)
  , CONSTRAINT client_price_organization_id_fk FOREIGN KEY (organization_id) REFERENCES organizations (id)
  , CONSTRAINT client_price_price_type_id_fk FOREIGN KEY (price_type_id) REFERENCES price_types (id)
  , CONSTRAINT client_price_material_id_fk FOREIGN KEY (material_id) REFERENCES materials (id)
) COMMENT='Прайсы клиентов'
;
-- MIGRATION_ROLLBACK
-- write rollback migration below (do not change these comments)

DROP TABLE client_price
;
DROP TABLE promo_discounts
;
DROP TABLE prices
;
DROP TABLE exchange_rate
;
DROP TABLE currency
;
DROP TABLE price_types
;
