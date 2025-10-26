#!/bin/bash

ARCH=${1:-x86_64}
COMPILER=${2:-gcc}
CFLAGS=${3:-"-O2"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
SOURCES_DIR="$ROOT_DIR/config/sources"

BUILD_DIR="$ROOT_DIR/build/$ARCH"

mkdir -p "$BUILD_DIR"

declare -A ARCH_TO_CC=(
    ["x86_64"]="gcc"
    ["amd64"]="gcc"
    ["arm"]="arm-linux-gnueabihf-gcc"
    ["aarch64"]="aarch64-linux-gnu-gcc"
    ["riscv64"]="riscv64-linux-gnu-gcc"
)

if [[ "$COMPILER" == "clang" ]]; then
    case "$ARCH" in
        x86_64|amd64)   TARGET="x86_64-unknown-linux-gnu" ;;
        arm)            TARGET="armv7-unknown-linux-gnueabihf" ;;
        aarch64)        TARGET="aarch64-unknown-linux-gnu" ;;
        riscv64)        TARGET="riscv64-unknown-linux-gnu" ;;
        *) echo "Unsupported arch for clang: $ARCH"; exit 1 ;;
    esac
    CC="clang --target=$TARGET"
    CFLAGS="$CFLAGS -static"
elif [[ "$COMPILER" == "gcc" ]]; then
    if [[ -v ARCH_TO_CC["$ARCH"] ]]; then
        CC="${ARCH_TO_CC[$ARCH]}"
        CFLAGS="$CFLAGS -static"
    else
        echo "Unsupported architecture: $ARCH"
        echo "Supported: ${!ARCH_TO_CC[@]}"
        exit 1
    fi
else
    echo "Unsupported compiler: $COMPILER (use gcc or clang)"
    exit 1
fi

echo "Building for ARCH=$ARCH | COMPILER=$COMPILER | CFLAGS=$CFLAGS"
echo "Using compiler: $CC"

mapfile -d '' c_files < <(find "$SOURCES_DIR" -name "*.c" -print0)

if [[ ${#c_files[@]} -eq 0 ]]; then
    echo "No .c files found in $SOURCES_DIR"
    exit 1
fi

echo "Found ${#c_files[@]} C source files. Compiling..."

success=0
failed=0

for src in "${c_files[@]}"; do
    [[ ! -f "$src" ]] && continue

    bin_name=$(basename "$src" .c)
    bin_path="$BUILD_DIR/${bin_name}_${ARCH}"

    echo -n "Compiling $bin_name ... "

    if timeout 30s $CC $CFLAGS -o "$bin_path" "$src" -lm 2>/dev/null; then
        if file "$bin_path" 2>/dev/null | grep -q "ELF.*executable"; then
            ((success++))
        else
            echo "(not ELF)"
            rm -f "$bin_path"
            ((failed++))
        fi
    else
        echo "(compile failed)"
        ((failed++))
    fi
done

echo
echo "Done: $success succeeded, $failed failed."
echo "Output dir: $BUILD_DIR"
