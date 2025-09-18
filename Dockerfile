FROM node:18-slim

# Create app directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    htop \
    tree \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Install useful Python packages (using --break-system-packages for Docker)
RUN pip3 install --no-cache-dir --break-system-packages \
    requests \
    flask \
    fastapi \
    uvicorn \
    pandas \
    numpy

# Create python3 alias if needed
RUN ln -sf /usr/bin/python3 /usr/local/bin/python

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

# Lambda handler entry point - use node directly
CMD ["node", "lambda-handler.js"]
