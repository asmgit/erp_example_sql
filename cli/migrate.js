require('dotenv').config();
let {db_config} = require('../plugins/mysql');
let migrations = require('../lib/migrations');
const mysql = require('mysql2/promise');

let {argv} = process;
let [, , command, ...params] = argv;

let main = async () => {
    let db, database;
    if (command in migrations) {
        if (command === 'create_database') {
            ({database, ...db_config} = db_config);
            db = await mysql.createConnection(db_config);
            await migrations[command](db, params[0] ?? database);
            return;
        } else {
            db = await mysql.createConnection(db_config);
        }
        if (command === 'up') {
            let index = await migrations.index(db);
            let files = index.items.filter(item => item.need_migration).map(item => item.file_name);
            await migrations.up(db, files);
        } else if (command === 'down') {
            let index = await migrations.index(db);
            let items = index.items.filter(item => item.status === 'Installed');
            if (!items.length) return;
            let max_date = items[items.length - 1].created_at;
            let files = items.filter(item => item.created_at === max_date).map(item => item.file_name).reverse();
            await migrations.down(db, files);
        } else {
            await migrations[command](db, ...params);
        }
    } else {
        console.log(Object.keys(migrations));
    }
};

main().then(() => {
}).catch(e => {
    console.error(e);
}).finally(() => {
    process.exit();
});
