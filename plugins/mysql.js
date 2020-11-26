'use strict'

const mysql = require('mysql2/promise');
const fp = require('fastify-plugin');

const db_config = {
    host: process.env.DB_HOST || 'localhost'
    , port: process.env.DB_PORT || 3306
    , user: process.env.DB_USER || 'root'
    , password: process.env.DB_PASSWORD || 'secret'
    , database: process.env.DB_DATABASE
    , charset: 'utf8mb4_0900_ai_ci'
    , connectionLimit: 40
    , namedPlaceholders: true
    , dateStrings: true
};

module.exports.db_config = db_config;

let register_db_vars = async (db, vars) => {
    for (let var_name in vars) {
        let val = vars[var_name];
        if (!['number', 'string', 'boolean'].includes(typeof val) && val !== null) {
            val = JSON.stringify(val);
        }
        await db.query("SET @`req_" + var_name.replace(/[^a-zA-Z0-9_-]/g, '') + "` = :val", {val});
    }
};

module.exports.default = fp(async fastify => {
    let db_pool = await mysql.createPool(db_config);
    console.log('Connection pool created');

    fastify.decorate('db_pool', db_pool);
    fastify.decorate('register_db_vars', register_db_vars);

    fastify.addHook('preHandler', async (req) => {
        req.db = await db_pool.getConnection();
        await register_db_vars(req.db, req.params);
        await req.db.beginTransaction();
        return;
    });

    fastify.addHook('preSerialization', async (req) => {
        await req.db.commit();
        req.db.release();
        return;
    });

    fastify.setErrorHandler(async (err, req, res) => {
        //console.error(err);
        await req.db.rollback();
        req.db.release();
        try {
            // TODO mysql exception catcher

            // Error number: 1644; Symbol: ER_SIGNAL_EXCEPTION; SQLSTATE: HY000
            // Message: Unhandled user-defined exception condition
            if (err.errno == 1644) {
                res.code(422).send(err);
                // Error number: 3819; Symbol: ER_CHECK_CONSTRAINT_VIOLATED; SQLSTATE: HY000
                // Message: Check constraint '%s' is violated.
            } else if (err.errno == 3819) {
                let msg = err.message.match(/Check constraint '(.*)_chk' is violated/);
                err.message = 'Field ' + msg[1] + ' is incorrect';
                res.code(422).send(err);
                // Error number: 1292; Symbol: ER_TRUNCATED_WRONG_VALUE; SQLSTATE: 22007
                // Message: Truncated incorrect %s value: '%s'
                // Message: Incorrect %s value: '%s' for column '%s' at row %ld
            } else if (err.errno == 1292) {
                let msg = err.message.match(/Incorrect (.*) value: '(.*)' for column '(.*)' at row (.*)/);
                err.message = 'Field ' + msg[3] + ' is incorrect';
                res.code(422).send(err);
                // Error number: 1366; Symbol: ER_TRUNCATED_WRONG_VALUE_FOR_FIELD; SQLSTATE: HY000
                // Message: Incorrect %s value: '%s' for column '%s' at row %ld
            } else if (err.errno == 1366) {
                let msg = err.message.match(/Incorrect (.*) value: '(.*)' for column '(.*)' at row (.*)/);
                err.message = 'Field ' + msg[2] + ' is incorrect';
                res.code(422).send(err);
                // Error number: 1406; Symbol: ER_DATA_TOO_LONG; SQLSTATE: 22001
                // Message: Data too long for column '%s' at row %ld
            } else if (err.errno == 1406) {
                let msg = err.message.match(/Data too long for column '(.*)' at row (.*)/);
                err.message = 'Field ' + msg[1] + ' is incorrect';
                res.code(422).send(err);
            } else {
                console.error(err);
                res.send(err);
            }
        } catch (e) {
            console.error(err);
            console.error(e);
            res.send(e);
        }
    })
});