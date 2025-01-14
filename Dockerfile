# Stage 1: Build
FROM node:22 AS builder

WORKDIR /app

COPY package*.json .npmrc ./ 
COPY prisma ./prisma/

RUN npm ci --only=production

RUN npm i

RUN npm run setup

COPY . .

RUN npm run build

# Stage 2: Runtime
FROM node:22 AS runtime

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./ 
COPY --from=builder /app/dist ./dist

# Add PostgreSQL client if needed
RUN apt-get update && apt-get install -y postgresql-client && apt-get clean

EXPOSE 3000

CMD ["npm", "run", "start:prod"]
