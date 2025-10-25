FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy test files
COPY tests/ ./tests/

# Run tests
CMD ["npm", "run", "test:integration"]
