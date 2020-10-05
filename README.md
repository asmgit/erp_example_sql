#ERP Example SQL

###Install
* Install Node 14 or high
* Install MySQL 8.0.21 or high
* get repository
```
git clone https://github.com/asmgit/erp_example_sql.git
```
* create database in mysql
```mysql
CREATE DATABASE IF NOT EXISTS erp_example_sql
```
* configure .env 
```
PORT=3030
DB_HOST=mysql
DB_USER=root
DB_PASSWORD=secret
DB_DATABASE=erp_example_sql
```
* install npm packages and run migrations
```
npm i
npm run migrate up
```
###Run
* run with nolog flag
```
npm run dev_nolog
```
* check url
```
http://localhost:3030/api/test_validation
```
* run autocannon test
```
autocannon http://localhost:3030/api/test_validation
```
