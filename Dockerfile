# Build separately so the runtime image stays small.
FROM node:22-slim AS builder

WORKDIR /app

# Keep dependency installation cached when only source files change.
COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src/ ./src/
# Remove development dependencies before copying into the runtime image.
RUN npm run build && npm prune --omit=dev

# Copy only the compiled app and production dependencies.
FROM node:22-slim AS runtime

ENV NODE_ENV=production

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package.json ./

# Do not run the MCP server as root.
USER node

ENTRYPOINT ["node", "/app/dist/index.js"]
