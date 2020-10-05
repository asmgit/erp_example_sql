CREATE TABLE data_for_validation (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT
    , name VARCHAR(191)
    , login VARCHAR(191)
    , email VARCHAR(191) NOT NULL
    , password VARCHAR(64) NOT NULL
    , agreed TINYINT NOT NULL
    , date DATETIME
    , ipv4 VARCHAR(15)
    , guid VARCHAR(36)
    , CONSTRAINT name_chk CHECK (name REGEXP '^[A-Za-z]+ [A-Za-z]+$')
    , CONSTRAINT login_chk CHECK (login REGEXP '^[a-zA-Z0-9\-_]+$')
    , CONSTRAINT email_chk CHECK (email REGEXP '^[a-zA-Z0-9!#$%&\'*+\\/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&\'*+\\/=?^_`{|}~-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$')
    , CONSTRAINT password_chk CHECK (CHAR_LENGTH(password) >= 8)
    , CONSTRAINT agreed_chk CHECK (agreed IN (0, 1))
    , CONSTRAINT ipv4_chk CHECK (ipv4 REGEXP '^(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))$')
    , CONSTRAINT guid_chk CHECK (guid REGEXP '^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$')
)
;

-- MIGRATION_ROLLBACK
-- write rollback migration below (do not change these comments)

DROP TABLE data_for_validation
;