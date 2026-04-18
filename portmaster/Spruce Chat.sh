#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/spruce_chat"
CONFDIR="$GAMEDIR/conf"
APPDIR="$GAMEDIR/spruce_chat"

mkdir -p "$CONFDIR"
cd "$GAMEDIR"

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

export XDG_DATA_HOME="$CONFDIR"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export SPRUCE_INPUT_MODE="sdl"

# chat.py auto-detects screen dimensions via SDL_GetCurrentDisplayMode when
# SCREEN_WIDTH/SCREEN_HEIGHT aren't set. Export them here only to force a
# specific resolution (e.g. for debugging on a desktop).

# Bundled Python + SDL2 live inside the port
export PYTHONHOME="$APPDIR/python"
export PYTHONPATH="$APPDIR/python/lib/python3.11:$APPDIR/python/lib/python3.11/lib-dynload:$APPDIR/pysdl2"
export PYTHONDONTWRITEBYTECODE=1
export LD_LIBRARY_PATH="$APPDIR/libs.${DEVICE_ARCH}:$APPDIR/python/lib:$LD_LIBRARY_PATH"
export PATH="$APPDIR/python/bin:$PATH"

# SpruceChat uses SDL2 for rendering; pysdl2 finds SDL2 via this var
export PYSDL2_DLL_PATH="$APPDIR/libs.${DEVICE_ARCH}"

# Reassemble the chunked model on first run (PortMaster convention)
MODEL_DIR="$APPDIR/models"
MODEL="$MODEL_DIR/qwen2.5-0.5b-instruct-q4_0.gguf"
if [ ! -f "$MODEL" ] && [ -f "$MODEL_DIR/qwen2.5-0.5b-instruct-q4_0.gguf.00" ]; then
  pm_message "First run: assembling model (one-time, ~30s)..."
  cat "$MODEL_DIR"/qwen2.5-0.5b-instruct-q4_0.gguf.* > "$MODEL"
  rm "$MODEL_DIR"/qwen2.5-0.5b-instruct-q4_0.gguf.??
fi

# Start llama-server in the background; chat.py shows a loading screen until it's ready
SERVER_PID=""
if [ -x "$APPDIR/llama-server" ] && [ -f "$MODEL" ]; then
  "$APPDIR/llama-server" \
    -m "$MODEL" \
    -c 1024 -t 4 -np 1 -ngl 0 -b 32 \
    --port 8086 --host 0.0.0.0 \
    > "$APPDIR/server.log" 2>&1 &
  SERVER_PID=$!
fi

# gptokeyb with no mapping acts as a process terminator on hotkey+start
$GPTOKEYB "python3.11" &

pm_platform_helper "$APPDIR/python/bin/python3.11"

"$APPDIR/python/bin/python3.11" "$APPDIR/chat.py"

if [ -n "$SERVER_PID" ]; then
  kill "$SERVER_PID" 2>/dev/null
  wait "$SERVER_PID" 2>/dev/null
fi

pm_finish
