FROM node:latest

RUN npm update \
    && npm i -g concurrently \
    && npm i -g autocannon \
    && npm i -g pm2 \
    && rm -rf /var/lib/apt/lists/*
