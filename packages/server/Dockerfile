FROM node:18.16.0-alpine as build

USER root

WORKDIR /app

# Copy application dependency manifests to the container image.
COPY . .

# Install application dependencies
RUN apk update
RUN apk add python3 build-base

# Set PYTHON env
ENV PYTHON=/usr/bin/python3

# Install pnpm packages dependencies
RUN npm install -g pnpm
RUN pnpm install

# Build server package
RUN pnpm run build:server

# Production stage
FROM node:18.16.0-alpine

USER root

WORKDIR /app

# Install production dependencies
RUN apk update && apk add --no-cache python3 build-base bash

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/server/package.json ./packages/server/
COPY shared ./shared

# Install pnpm and production dependencies only
RUN npm install -g pnpm
RUN pnpm install --prod

# Copy built application from build stage
COPY --from=build /app/packages/server/build ./packages/server/build
COPY --from=build /app/packages/server/static ./packages/server/static
COPY --from=build /app/packages/server/public ./packages/server/public

# Set working directory to server package
WORKDIR /app/packages/server

# Expose port
EXPOSE 3000

# Start the server
CMD ["node", "build/main.js"]
