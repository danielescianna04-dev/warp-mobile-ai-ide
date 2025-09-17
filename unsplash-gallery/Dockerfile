FROM node:20-alpine

LABEL maintainer="Warp Mobile AI IDE"
LABEL description="React Unsplash Gallery for Warp IDE"

# Set working directory
WORKDIR /app

# Set environment variables
ENV NODE_ENV=development
ENV VITE_PORT=5174

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production --silent

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S react -u 1001

# Change ownership
RUN chown -R react:nodejs /app
USER react

# Expose port
EXPOSE 5174

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5174 || exit 1

# Start the application
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5174"]