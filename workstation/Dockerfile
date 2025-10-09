# Container ottimizzato per Cloud Workstations
# Include: Node.js, Python, Flutter, Dart, Go, Rust, C/C++
FROM ubuntu:22.04

# Evita prompt interattivi
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/user/.local/bin:/home/user/flutter/bin:${PATH}"

# Installa dipendenze base
RUN apt-get update && apt-get install -y \
    curl wget git unzip xz-utils zip \
    build-essential cmake ninja-build \
    ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest yarn pnpm \
    && rm -rf /var/lib/apt/lists/*

# Python 3.11 + pip
RUN apt-get update && apt-get install -y \
    python3.11 python3-pip python3.11-venv \
    && ln -sf /usr/bin/python3.11 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Go 1.21
RUN wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz \
    && rm go1.21.5.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Flutter SDK (stable channel)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /home/user/flutter \
    && /home/user/flutter/bin/flutter precache \
    && /home/user/flutter/bin/flutter config --no-analytics

# Dart (già incluso in Flutter, ma aggiungiamo al PATH)
ENV PATH="/home/user/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Java (per Android development)
RUN apt-get update && apt-get install -y openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Android SDK (solo command line tools, no Android Studio)
ENV ANDROID_HOME=/opt/android-sdk
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip -q commandlinetools-linux-9477386_latest.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm commandlinetools-linux-9477386_latest.zip
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Accetta licenze Android
RUN yes | sdkmanager --licenses || true \
    && sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Docker CLI (per container in container)
RUN curl -fsSL https://get.docker.com | sh

# Tools utili
RUN apt-get update && apt-get install -y \
    vim nano htop tree jq \
    && rm -rf /var/lib/apt/lists/*

# Crea user non-root
RUN useradd -m -s /bin/bash user \
    && chown -R user:user /home/user

USER user
WORKDIR /home/user/workspace

# Pre-warm Flutter
RUN flutter doctor || true

CMD ["/bin/bash"]
