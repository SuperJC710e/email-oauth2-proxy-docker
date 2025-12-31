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

# Start tail in the background with -F to wait for file creation
tail -F $LOG_FILE_PATH &
TAIL_PID=$!

# Trap signals to ensure clean shutdown
trap "kill $TAIL_PID 2>/dev/null; exit" TERM INT

# Execute the Python script with arguments as PID 1
exec python emailproxy.py --no-gui --log-file $LOG_FILE_PATH --config-file /config/emailproxy.config $CACHE_STORE_VALUE $DEBUG_VALUE $EXTERNAL_AUTH_VALUE $LOCAL_SERVER_AUTH_VALUE
