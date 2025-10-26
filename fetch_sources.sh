
#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
SOURCES_LIST="$ROOT_DIR/config/sources.txt"
SOURCES_DIR="$ROOT_DIR/config/sources"

if [[ ! -f "$SOURCES_LIST" ]]; then
    echo "Error: $SOURCES_LIST not found. Create it with one archive URL per line."
    exit 1
fi

echo "Creating sources directory..."
mkdir -p "$SOURCES_DIR"

TMP_DIR="/tmp/fetch_sources_$(date +%s)"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

for url in $(cat "$SOURCES_LIST"); do
    url=$(echo "$url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ "$url" =~ ^#.*$ || -z "$url" ]] && continue

    echo "Processing: $url"

    filename=$(basename "$url")
    if [[ "$filename" == *.tar.gz ]]; then
        ext="tar.gz"
    elif [[ "$filename" == *.tar.bz2 ]]; then
        ext="tar.bz2"
    elif [[ "$filename" == *.zip ]]; then
        ext="zip"
    else
        echo "  Skipping: unsupported archive format"
        continue
    fi

    archive="$TMP_DIR/archive.$ext"
    wget -q --timeout=20 "$url" -O "$archive"

    extract_dir="$TMP_DIR/extract_$(date +%s)_$$"
    mkdir -p "$extract_dir"

    if [[ "$ext" == "zip" ]]; then
        unzip -q "$archive" -d "$extract_dir"
    elif [[ "$ext" == "tar.gz" ]]; then
        tar -xzf "$archive" -C "$extract_dir"
    elif [[ "$ext" == "tar.bz2" ]]; then
        tar -xjf "$archive" -C "$extract_dir"
    fi


    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            if grep -q "main\s*(" "$file"; then

                temp_bin="$TMP_DIR/temp_compile_test_$$"
                if timeout 10s gcc -O2 -static -o "$temp_bin" "$file" -lm 2>/dev/null; then
                    cp "$file" "$SOURCES_DIR/"
                    echo "Compiled: $(basename "$file")"
                else
                    echo "Failed to compile: $(basename "$file")"
                fi
                rm -f "$temp_bin" 2>/dev/null || true
            fi
        fi
    done < <(find "$extract_dir" -type f -name "*.c" -print0 2>/dev/null)

done

find "$SOURCES_DIR" -name "*.c" -size 0 -delete 2>/dev/null || true

declare -A seen
while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
        hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
        if [[ -n "${seen[$hash]}" ]]; then
            rm -f "$file"
        else
            seen[$hash]=1
        fi
    fi
done < <(find "$SOURCES_DIR" -name "*.c" -print0 2>/dev/null)

COUNT=$(find "$SOURCES_DIR" -name "*.c" 2>/dev/null | wc -l)
echo
echo "Done! Added $COUNT C source files to: $SOURCES_DIR"
