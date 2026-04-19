#!/bin/bash
set -e

OUTPUT_DIR="${OUTPUT_DIR:-/output}"

echo "=== Building llama.cpp for aarch64 (universal) ==="

# Clone llama.cpp
if [ ! -d "llama.cpp" ]; then
    git clone --depth 1 https://github.com/ggerganov/llama.cpp.git
fi

cd llama.cpp

# Default-disable llama.cpp's memory-fit preflight. It demands ~1024 MiB
# free host RAM on start and aborts otherwise, which kills us on 1 GiB
# devices (e.g. RGB30) even though Qwen2.5-0.5B only uses ~500 MiB. The
# runtime -fit off / --fit / LLAMA_ARG_FIT=off paths are not honored by
# our build for reasons we couldn't nail down, so flip the default.
sed -i -E 's|(\bbool[[:space:]]+fit_params[[:space:]]*=[[:space:]]*)true(\s*;)|\1false\2|' common/common.h
grep -n 'fit_params' common/common.h | head -3

# Cross-compilation environment
export CCACHE_DIR="${CCACHE_DIR:-/ccache}"

cat > /tmp/aarch64-toolchain.cmake <<'EOF'
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
EOF

cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=/tmp/aarch64-toolchain.cmake \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_C_FLAGS="-O3 -ffunction-sections -fdata-sections -fomit-frame-pointer -flto=auto" \
    -DCMAKE_CXX_FLAGS="-O3 -ffunction-sections -fdata-sections -fomit-frame-pointer -flto=auto" \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--gc-sections,--strip-all -static-libstdc++ -flto=auto" \
    -DGGML_NATIVE=OFF \
    -DLLAMA_CURL=OFF \
    -DLLAMA_OPENSSL=OFF \
    -DGGML_OPENMP=OFF

cmake --build build --target llama-server llama-cli -j$(nproc)

# Collect output
mkdir -p "$OUTPUT_DIR/lib"

# Binaries
cp build/bin/llama-server "$OUTPUT_DIR/"
cp build/bin/llama-cli "$OUTPUT_DIR/"
aarch64-linux-gnu-strip -s "$OUTPUT_DIR/llama-server" "$OUTPUT_DIR/llama-cli"

# llama.cpp shared libs (no glibc — device has ≥2.33)
for soname in libggml-base.so.0 libggml-cpu.so.0 libggml.so.0 \
              libllama.so.0 libllama-common.so.0 libmtmd.so.0; do
    real=$(find build/bin -name "${soname}*" ! -type l | head -1)
    if [ -n "$real" ]; then
        cp "$real" "$OUTPUT_DIR/lib/$soname"
    fi
done

chmod +x "$OUTPUT_DIR/llama-server" "$OUTPUT_DIR/llama-cli"

echo "=== Build complete ==="
