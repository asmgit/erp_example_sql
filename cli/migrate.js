require('dotenv').config();
let {db_config} = require('../plugins/mysql');
let migrations = require('../lib/migrations');
const mysql = require('mysql2/promise');

let {argv} = process;
let command = argv[2];
let param = argv[3];

let main = async () => {
    let db = await mysql.createConnection(db_config);
    if (command === 'up') {
        let index = await migrations.index(db);
        let files = index.items.filter(item => item.need_migration).map(item => item.file_name);
        await migrations.up(db, {files: files});
    } else if (command === 'down') {
        let index = await migrations.index(db);
        let items = index.items.filter(item => item.status === 'Installed');
        if (!items.length) return;
        let max_date = items[items.length - 1].created_at;
        let files = items.filter(item => item.created_at === max_date).map(item => item.file_name).reverse();
        await migrations.down(db, {files: files});
    } else if (command === 'add') {
        await migrations.add(db, {label: param});
    } else if (command === 'routines') {
        await migrations.routines(db);
    } else if (command === 'seed') {
        await migrations.seed(db, {file: param});
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
