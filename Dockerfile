# Stage 1: Build — Debian slim supports arm-unknown-linux-gnueabihf (rustup-compatible)
FROM python:3.11-slim AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libffi-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --prefer-binary --prefix=/install emailproxy

# Stage 2: Runtime — clean image with no build tools
FROM python:3.11-slim

ENV PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_NO_WARN_SCRIPT_LOCATION=1 \
    PIP_PROGRESS_BAR=off \
    PIP_ROOT_USER_ACTION=ignore \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Download default config
ADD https://raw.githubusercontent.com/simonrob/email-oauth2-proxy/refs/heads/main/emailproxy.config /config/emailproxy.config

# Declare volume - when mounted, Docker copies existing content to new volumes
VOLUME /config

# Copy the shell script into the container
COPY --chmod=777 run_email_proxy.sh /app/

# Run the shell script
CMD ["/bin/sh", "/app/run_email_proxy.sh"]
