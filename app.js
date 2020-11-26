'use strict'

const path = require('path')
const AutoLoad = require('fastify-autoload')

module.exports = async function (fastify, opts) {
    fastify.register(require('fastify-formbody'));

    // all input data to params
    fastify.addHook('preHandler', (req, res, next) => {
        req.params = {...req.body, ...req.params, ...req.query};
        next()
    });

    fastify.register(AutoLoad, {
        dir: path.join(__dirname, 'plugins'),
        options: Object.assign({}, opts)
    });

    fastify.register(AutoLoad, {
        dir: path.join(__dirname, 'routes'),
        options: Object.assign({}, opts)
    })
};
