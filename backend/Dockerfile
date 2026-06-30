# ============================================================
# Rafiq Backend – Dockerfile
# ============================================================
# Stage 1 – Dependencies
FROM node:20-alpine AS deps

WORKDIR /app

# Copy only package files first (better layer caching)
COPY package*.json ./
RUN npm ci --only=production

# ============================================================
# Stage 2 – Runtime
FROM node:20-alpine AS runner

# Add non-root user for security
RUN addgroup -S rafiq && adduser -S rafiq -G rafiq

WORKDIR /app

# Copy installed node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# Create uploads directory (writable by the app)
RUN mkdir -p uploads && chown -R rafiq:rafiq /app

USER rafiq

EXPOSE 5000

# Health-check so Docker Compose knows when the API is ready
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
  CMD wget -qO- http://localhost:5000/health || exit 1

CMD ["node", "src/server.js"]
