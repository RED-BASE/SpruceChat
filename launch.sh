#!/bin/sh
. /mnt/SDCARD/spruce/scripts/helperFunctions.sh

APP_DIR="/mnt/SDCARD/App/SpruceChat"
export HOME="$APP_DIR"
cd "$APP_DIR"

# Platform-specific binary and library selection
if [ "$PLATFORM" = "A30" ]; then
    SERVER_BIN="$APP_DIR/llama-server32"
    LIB_DIR="$APP_DIR/lib32"
    LOADER="$APP_DIR/lib32/ld-linux-armhf.so.3"
    export LD_LIBRARY_PATH="$APP_DIR/lib32:/mnt/SDCARD/spruce/a30/lib:/mnt/SDCARD/miyoo/lib:$LD_LIBRARY_PATH"
    export PYSDL2_DLL_PATH="/mnt/SDCARD/spruce/a30/sdl2"
else
    SERVER_BIN="$APP_DIR/llama-server"
    LIB_DIR="$APP_DIR/lib"
    LOADER=""
    export LD_LIBRARY_PATH="$APP_DIR/lib:/mnt/SDCARD/spruce/bin64:$LD_LIBRARY_PATH"
    export PYSDL2_DLL_PATH="/mnt/SDCARD/spruce/bin64"
fi

# Ensure loopback is up (some builds don't configure it)
ifconfig lo 127.0.0.1 up 2>/dev/null

MODEL_Q4="$APP_DIR/models/qwen2.5-0.5b-instruct-q4_0.gguf"
MODEL_Q2="$APP_DIR/models/qwen2.5-0.5b-instruct-q2_k.gguf"
PORT=8086

# Pick best available model (Q4_0 is faster on ARM NEON)
if [ -f "$MODEL_Q4" ]; then
    MODEL="$MODEL_Q4"
else
    MODEL="$MODEL_Q2"
fi

# Start persistent llama-server
SERVER_PID=""
if [ -x "$SERVER_BIN" ] && [ -f "$MODEL" ]; then
    if [ -n "$LOADER" ]; then
        # A30: use bundled glibc loader (device glibc is too old)
        "$LOADER" --library-path "$LIB_DIR" "$SERVER_BIN" \
            -m "$MODEL" \
            -c 1024 \
            -t 4 \
            -np 1 \
            -ngl 0 \
            -b 32 \
            --port "$PORT" \
            --host 0.0.0.0 \
            > "$APP_DIR/server.log" 2>&1 &
    else
        # 64-bit: run directly with system glibc
        "$SERVER_BIN" \
            -m "$MODEL" \
            -c 1024 \
            -t 4 \
            -np 1 \
            -ngl 0 \
            -b 32 \
            --port "$PORT" \
            --host 0.0.0.0 \
            > "$APP_DIR/server.log" 2>&1 &
    fi
    SERVER_PID=$!
    # Don't wait here — chat.py shows a loading screen while server starts
fi

/mnt/SDCARD/spruce/bin/python/bin/python3.10 "$APP_DIR/chat.py" > "$APP_DIR/chat.log" 2>&1

# Cleanup: kill server when app exits
if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null
    wait "$SERVER_PID" 2>/dev/null
fi
