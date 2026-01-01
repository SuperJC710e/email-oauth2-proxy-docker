#!/bin/sh

# Set default values for external_auth, local_auth, debug, cache_store, and logfile
EXTERNAL_AUTH_VALUE=""
LOCAL_SERVER_AUTH_VALUE=""
DEBUG_VALUE=""
CACHE_STORE_VALUE=""
LOG_FILE_PATH=""

# Check if LOCAL_SERVER_AUTH environment variable is set to "true"
if [ "$LOCAL_SERVER_AUTH" = "true" ]; then
    LOCAL_SERVER_AUTH_VALUE="--local-server-auth"
else
    EXTERNAL_AUTH_VALUE="--external-auth"  # Default to --external-auth if not using local server auth
fi

# Check if DEBUG environment variable is set to "true"
if [ "$DEBUG" = "true" ]; then
    DEBUG_VALUE="--debug"
fi

# Check if CACHE_STORE environment variable is set
if [ -n "$CACHE_STORE" ]; then
    CACHE_STORE_VALUE="--cache-store $CACHE_STORE"
fi

# Check if LOGFILE environment variable is set to "true"
if [ "$LOGFILE" = "true" ]; then
    LOG_FILE_PATH="/config/emailproxy.log"
else
    LOG_FILE_PATH="/app/emailproxy.log"
fi

# Cleanup function to stop all child processes
cleanup() {
    echo "Shutting down..."
    kill -TERM $PYTHON_PID 2>/dev/null
    kill -TERM $TAIL_PID 2>/dev/null
    wait $PYTHON_PID 2>/dev/null
    wait $TAIL_PID 2>/dev/null
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup TERM INT

# Start emailproxy in the background
emailproxy --no-gui --log-file $LOG_FILE_PATH --config-file /config/emailproxy.config $CACHE_STORE_VALUE $DEBUG_VALUE $EXTERNAL_AUTH_VALUE $LOCAL_SERVER_AUTH_VALUE &
PYTHON_PID=$!

# Start tail in background to stream logs to Docker
# -F waits for file creation and follows it
tail -F $LOG_FILE_PATH &
TAIL_PID=$!

# Wait for Python process to exit (keeps script running)
wait $PYTHON_PID
