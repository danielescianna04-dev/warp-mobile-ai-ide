FROM node:18-slim

# Create app directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    python3-pip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./

# Install app dependencies
RUN npm install

# Bundle app source
COPY . .

# Create workspace directory for user sessions
RUN mkdir -p /tmp/warp-users && chmod 755 /tmp/warp-users

# Environment setup
ENV NODE_ENV=production
ENV PORT=8080

# Run as non-root user for better security
RUN groupadd -r warpuser && useradd -r -g warpuser warpuser
RUN chown -R warpuser:warpuser /app /tmp/warp-users
USER warpuser

# Expose port
EXPOSE 8080

# Start production server
CMD ["node", "backend/server-production.js"]