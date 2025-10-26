#!/bin/bash

set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Использование: $0 <директория> <метка: packed|plain> <выходной_каталог>"
    exit 1
fi

dir="$1"
label="$2"
out_dir="$3"

mkdir -p "$out_dir"

for file in "$dir"/*; do
    if [ ! -f "$file" ] || [ ! -x "$file" ]; then continue; fi

    base=$(basename "$file")
    log="$out_dir/${base}.strace"

    echo "Обрабатываю: $file (метка: $label)"
    timeout 15s strace -f -o "$log" "$file" </dev/null >/dev/null 2>&1 || true
done