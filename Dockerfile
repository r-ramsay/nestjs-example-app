# Stage 1: Build
FROM node:22 AS builder

WORKDIR /app

# Copy application files
COPY package*.json .npmrc ./ 
COPY prisma ./prisma/
COPY .env .env

# Install dependencies
RUN npm ci --only=production
RUN npm i

# Load environment variables from .env during the setup process
ARG ENV_FILE=.env
RUN export $(cat $ENV_FILE | xargs) && npm run setup

COPY . .

RUN npm run build

# Stage 2: Runtime
FROM node:22 AS runtime

WORKDIR /app

# Copy necessary files from the builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./ 
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/.env .env

# Add PostgreSQL client if needed
RUN apt-get update && apt-get install -y postgresql-client && apt-get clean

# Expose application port
EXPOSE 3000

# Command to run the application
CMD ["npm", "run", "start:prod"]
