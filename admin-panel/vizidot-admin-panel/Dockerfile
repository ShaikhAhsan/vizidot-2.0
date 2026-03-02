# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage: serve static build (no webpack-dev-server)
FROM node:20-alpine

WORKDIR /app

# Install serve to run the built app
RUN npm install -g serve@14

COPY --from=builder /app/build ./build

ENV PORT=3000
EXPOSE 3000

# Serve the built app; do NOT use npm start (dev server)
# Use PORT env when set (e.g. Railway, Render)
CMD ["sh", "-c", "serve -s build -l ${PORT:-3000}"]
