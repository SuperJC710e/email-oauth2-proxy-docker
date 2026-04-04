# Use a Python image based on Alpine Linux
# Versions newer than 3.11 are not yet fully supported by emailproxy
FROM python:3.11-alpine

# Environment variables
ENV PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_NO_WARN_SCRIPT_LOCATION=1 \
    PIP_PROGRESS_BAR=off \
    PIP_ROOT_USER_ACTION=ignore \
    PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Download default config
ADD https://raw.githubusercontent.com/simonrob/email-oauth2-proxy/refs/heads/main/emailproxy.config /config/emailproxy.config

# Declare volume - when mounted, Docker copies existing content to new volumes
VOLUME /config

# Install core dependencies (build tools needed for cffi on arm/v6 and arm/v7)
RUN apk add --no-cache --virtual .build-deps build-base libffi-dev && \
    pip install emailproxy && \
    apk del .build-deps

# Copy the shell script into the container
COPY --chmod=777 run_email_proxy.sh /app/

# Run the shell script
CMD ["/bin/sh", "/app/run_email_proxy.sh"]
