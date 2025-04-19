FROM node:alpine

WORKDIR /app
EXPOSE 3000
USER node

COPY src/* .

CMD ["node", "main.js"]
