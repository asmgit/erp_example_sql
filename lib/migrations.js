const moment = require("moment");
const {split: sql_splitter} = require('@verycrazydog/mysql-parser');
const {promises: fs} = require("fs");
const database_file_path = './database/';
const migration_file_path = database_file_path + 'migrations';
const routines_file_path = database_file_path + 'routines';
const migration_rollback_str_divider = '-- MIGRATION_ROLLBACK';

module.exports.index = async (db) => {
    let files = await fs.readdir(migration_file_path);

    let results;
    try {
        [results] = await db.query(`
            WITH files AS (
              SELECT *
              FROM JSON_TABLE(:files, "$[*]"
                COLUMNS (
                  file_name VARCHAR(255) PATH "$" ERROR ON ERROR
                )
              ) files
            )
            SELECT t.*
            , IF(name IS NULL OR status NOT IN ('Installed'), 1, 0) need_migration
            FROM (
                SELECT *
                FROM migrations m
                LEFT JOIN files f ON m.name = f.file_name
                UNION ALL
                SELECT *
                FROM migrations m
                RIGHT JOIN files f ON m.name = f.file_name
                WHERE m.name IS NULL
            ) t
            ORDER BY IFNULL(name, file_name)
        `, {files: JSON.stringify(files)});
    } catch (e) {
        if (e.errno === 1146) {
            await module.exports.create_migration_table(db);
            return await module.exports.index(db);
        }
        throw e;
    }

    let contents = {};
    await Promise.all(files.map(async (file) => {
        contents[file] = await fs.readFile(migration_file_path + '/' + file, 'utf8');
    }));

    let need_migrations = false;
    for (let i = results.length - 1; i >= 0; i--) {
        if (results[i].need_migration) {
            need_migrations = true;
        }
        results[i].file_content = contents[results[i].file_name];
    }

    return {
        items: results
        , need_migrations: need_migrations
    };
};

module.exports.up = async (db, {files}) => {
    // set autocommit;
    await db.commit();
    await db.query(`SET @date = NOW(6)`);
    for (let file of files) {
        let file_data = await fs.readFile(migration_file_path + '/' + file, 'utf8');
        file_data = file_data.split(migration_rollback_str_divider)[0];

        let queries = sql_splitter(file_data);

        let query = null;
        let status = 'Installed';
        let message = null;
        try {
            for (query of queries) {
                await db.query(query);
            }
            console.log(file + ' - ' + status);
        } catch (e) {
            status = 'Error';
            message = e.sqlMessage + '\nSQL:\n' + query;
            console.error(file + ' - ' + status + '\n' + message);
            throw new Error('mirgate error');
        } finally {
            await db.query(`
                REPLACE migrations (name, status, message, created_at)
                VALUES (:name, :status, :message, @date)
            `, {name: file, status: status, message: message});
        }
    }
};

module.exports.down = async (db, {files}) => {
    // set autocommit;
    await db.commit();
    await db.query(`SET @date = NOW(6)`);
    for (let file of files) {
        let file_data = await fs.readFile(migration_file_path + '/' + file, 'utf8');
        file_data = file_data.split(migration_rollback_str_divider)[1];

        let queries = sql_splitter(file_data);

        let query = null;
        let status = 'Rollbacked';
        let message = null;
        try {
            for (query of queries) {
                await db.query(query);
            }
            console.log(file + ' - ' + status);
        } catch (e) {
            status = 'Installed';
            message = e.sqlMessage + '\nSQL:\n' + query;
            console.error(file + ' - Rollback Error\n' + message);
            throw new Error('mirgate error');
        } finally {
            await db.query(`
                REPLACE migrations (name, status, message, created_at)
                VALUES (:name, :status, :message, @date)
            `, {name: file, status: status, message: message});
        }
    }
};

module.exports.add = async (db, {label}) => {
    let data = '\n' + migration_rollback_str_divider
        + '\n-- write rollback migration below (do not change these comments)'
        + '\n'
    ;
    let path = migration_file_path
        + '/' + moment().format('YYYY_MM_DD_HHmmss')
        + (label ? '_' + label : '')
        + '.sql'
    ;
    await fs.writeFile(path, data);

    return {};
};

module.exports.drop_routines = async (db) => {
    // TODO events
    let [queries] = await db.query(`
        SELECT CONCAT('DROP ', r.ROUTINE_TYPE, ' ', r.SPECIFIC_NAME) cmd
        FROM INFORMATION_SCHEMA.ROUTINES r
        WHERE r.ROUTINE_SCHEMA = DATABASE()
        UNION ALL
        SELECT CONCAT('DROP TRIGGER ', t.TRIGGER_NAME)
        FROM INFORMATION_SCHEMA.TRIGGERS t
        WHERE t.TRIGGER_SCHEMA = DATABASE()
        UNION ALL
        SELECT CONCAT('DROP VIEW ', v.TABLE_NAME)
        FROM INFORMATION_SCHEMA.VIEWS v
        WHERE v.TABLE_SCHEMA = DATABASE()
    `);
    for (let query of queries) {
        await db.query(query.cmd);
    }
};

module.exports.routines = async (db) => {
    await module.exports.drop_routines(db);
    for (let routine_type of ['functions', 'procedures', 'triggers', 'views', 'events']) {
        let file;
        try {
            let path = routines_file_path + '/' + routine_type;
            let files = await fs.readdir(path);
            for (file of files) {
                let file_data = await fs.readFile(path + '/' + file, 'utf8');
                await db.query(file_data);
                console.log(path + '/' + file);
            }
        } catch (e) {
            if (e.code === 'ENOENT') continue;
            if (file) console.error(e);
        }
    }
};

module.exports.seed = async (db, {file}) => {
    let file_data = await fs.readFile(file, 'utf8');
    let queries = sql_splitter(file_data);

    let query = null;
    db.beginTransaction();
    try {
        for (query of queries) {
            await db.query(query);
        }
        db.commit();
    } catch (e) {
        console.error(query);
        db.rollback();
        throw e;
    }
};

module.exports.create_migration_table = async (db) => {
    await db.query(`
        CREATE TABLE migrations (
            name VARCHAR(191) NOT NULL
            , status ENUM('Installed', 'Rollbacked', 'Error') NOT NULL
            , message VARCHAR(3000)
            , created_at DATETIME(6)
        )
    `);
};


//module.exports.migrations = {};
//module.exports.name = 'migrations';
//module.exports = {index}
//export class Migrations {index}
//export {migrate}
