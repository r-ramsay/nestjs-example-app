# Stage 1: Build
FROM node:22 AS builder

WORKDIR /app

# Copy application files
COPY package*.json .npmrc ./ 
COPY prisma ./prisma/
COPY .env .env

# Install dependencies
RUN npm install dotenv
RUN npm ci --only=production
RUN npm i

# Install PostgreSQL for build-time database setup
RUN apt-get update && apt-get install -y postgresql && apt-get clean

# Update PostgreSQL authentication to use password authentication
RUN sed -i "s/peer/trust/g" /etc/postgresql/*/main/pg_hba.conf && \
    sed -i "s/md5/trust/g" /etc/postgresql/*/main/pg_hba.conf

# Start PostgreSQL service and configure the database
RUN service postgresql start && \
    psql -U postgres -c "CREATE DATABASE dummy_db;" && \
    psql -U postgres -c "ALTER USER postgres PASSWORD 'dummy';"

# Wait for PostgreSQL to be ready
RUN until pg_isready -h localhost -p 5432 -U postgres; do echo "Waiting for PostgreSQL..."; sleep 1; done

# Set a database URL for the build phase
ENV DATABASE_URL="postgresql://postgres:dummy@localhost:5432/dummy_db"

# Run the setup script (migrations and seeds)
RUN npm run setup

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

# Add PostgreSQL client for runtime needs
RUN apt-get update && apt-get install -y postgresql-client && apt-get clean

# Expose application port
EXPOSE 3000

# Command to run the application
CMD ["npm", "run", "start:prod"]
