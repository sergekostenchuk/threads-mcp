# Multi-stage build for Threads MCP Server
# Production-ready Docker image optimized for Node.js

# Stage 1: Builder
FROM node:20-alpine as builder

# Install build dependencies
RUN apk add --no-cache python3 make g++ git

WORKDIR /build

# Copy package files for better caching
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy the rest of the application
COPY . .

# Build TypeScript if needed
RUN if [ -f "tsconfig.json" ]; then npm run build; fi

# Stage 2: Runtime
FROM node:20-alpine

# Security: Create non-root user
RUN addgroup -g 1001 -S threads && \
    adduser -u 1001 -S threads -G threads && \
    mkdir -p /app /data /logs && \
    chown -R threads:threads /app /data /logs

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata

# Copy application from builder
COPY --from=builder --chown=threads:threads /build/node_modules /app/node_modules
COPY --from=builder --chown=threads:threads /build/package*.json /app/
COPY --from=builder --chown=threads:threads /build/dist /app/dist
COPY --from=builder --chown=threads:threads /build/src /app/src

# Set environment variables
ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=2048" \
    TZ=UTC

# Switch to non-root user
USER threads
WORKDIR /app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:8766/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

# Volume for persistent data
VOLUME ["/data", "/logs"]

# Expose MCP server port
EXPOSE 8766

# Entry point
ENTRYPOINT ["node"]
CMD ["src/index.js"]