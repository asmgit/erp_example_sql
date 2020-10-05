'use strict'

function randomString(min_len = 1, max_len = 30) {
    let length = Math.floor(Math.random() * (max_len - min_len + 1) + min_len);

    let text = "";
    let possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

    for (let i = 0; i < length; i++) {
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    }

    return text;
}

function uuidv4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

let generate_data = (need_error) => {
    let data = {
        name: randomString() + ' ' + randomString()
        , login: randomString()
        , email: randomString() + '@example.com'
        , password: randomString(8, 64)
        , agreed: Math.round(Math.random())
        , date: require("moment")()
            .subtract(Math.floor(Math.random() * 86400 + 1), 'seconds')
            .format('YYYY-MM-DD-HH:mm:ss')
        , ipv4: [Math.floor(Math.random() * 256)
                , Math.floor(Math.random() * 256)
                , Math.floor(Math.random() * 256)
                , Math.floor(Math.random() * 256)
            ].join('.')
        , guid: uuidv4()
    };

    if (need_error) {
        let incorrect_data = {
            name: randomString() + randomString()
            , login: '#' + Math.floor(Math.random() * (999999999 - 100000000 + 1) + 100000000)
            , email: randomString()
            , password: randomString(4, 6)
            , agreed: Math.floor(Math.random() * (20 - 10 + 1) + 10)
            , date: randomString()
            , ipv4: randomString()
            , guid: randomString()
        };
        let cols = Object.keys(data);
        let random_col = cols[Math.floor(Math.random() * cols.length)];
        data[random_col] = incorrect_data[random_col];
    }
    return data;
};

module.exports = async function (fastify, opts) {
    // autocannon http://localhost:3030/api/test_validation
    fastify.get('/test_validation', async function (req, res) {
        let need_error = Math.random() < 0.1;
        //need_error = 1;
        //need_error = 0;
        let data = generate_data(need_error);
        let [ret] = await req.db.query(`
            INSERT INTO data_for_validation (name, login, email, password, agreed, date, ipv4, guid)
            VALUES (:name, :login, :email, :password, :agreed, :date, :ipv4, :guid)
        `, data);
        return ret;
    });
};
