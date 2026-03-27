#!/bin/sh
. /mnt/SDCARD/spruce/scripts/helperFunctions.sh

APP_DIR="/mnt/SDCARD/App/SpruceChat"
export HOME="$APP_DIR"
cd "$APP_DIR"

export LD_LIBRARY_PATH="$APP_DIR:/mnt/SDCARD/spruce/a30/lib:/mnt/SDCARD/miyoo/lib:$LD_LIBRARY_PATH"
export PYSDL2_DLL_PATH="/mnt/SDCARD/spruce/a30/sdl2"

# Ensure loopback is up (some A30 builds don't configure it)
ifconfig lo 127.0.0.1 up 2>/dev/null

SERVER_BIN="$APP_DIR/llama-server"
LOADER="$APP_DIR/lib/ld-linux-armhf.so.3"
LIB_DIR="$APP_DIR/lib"
MODEL_Q4="$APP_DIR/models/qwen2.5-0.5b-instruct-q4_0.gguf"
MODEL_Q2="$APP_DIR/models/qwen2.5-0.5b-instruct-q2_k.gguf"
PORT=8086

# Pick best available model (Q4_0 is faster on ARM NEON)
if [ -f "$MODEL_Q4" ]; then
    MODEL="$MODEL_Q4"
else
    MODEL="$MODEL_Q2"
fi

# Start persistent llama-server using bundled glibc (device glibc is too old)
SERVER_PID=""
if [ -x "$LOADER" ] && [ -x "$SERVER_BIN" ] && [ -f "$MODEL" ]; then
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
    SERVER_PID=$!
    # Don't wait here — chat.py shows a loading screen while server starts
fi

/mnt/SDCARD/spruce/bin/python/bin/python3.10 "$APP_DIR/chat.py" > "$APP_DIR/chat.log" 2>&1

# Cleanup: kill server when app exits
if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null
    wait "$SERVER_PID" 2>/dev/null
fi
