# ERP Example SQL

### Install

* install Docker
* get repository
```
git clone https://github.com/asmgit/erp_example_sql.git
```
* run docker containers
```
docker-compose up -d
```
* enter to node container
```
docker exec -it node bash
```
* install npm packages
```
npm i
```
* create database
```
npm run migrate create_database
```
* run migrations
```
npm run migrate up
```
* seed data
```
npm run migrate seed assets/seed/test_data_documents.sql
npm run migrate seed assets/seed/test_data_prices.sql
```
test_data_documents.sql have executing about 5-7 min

test_data_prices.sql have executing about 11-15 min

### Run

* run with nolog flag
```
npm run dev_nolog
```
* check test_validation API url
```
http://localhost:3030/api/test_validation
```
* run autocannon test_validation API test on other docker session
```
autocannon http://localhost:3030/api/test_validation
```
