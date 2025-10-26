#!/bin/bash

if [ $# -lt 1 ] || [ ! -d "$1" ]; then
    echo "Использование: $0 <директория_логов> [выходной_файл.csv]" >&2
    exit 1
fi

log_dir="$1"
output="${2:-/dev/stdout}"


packed=0
plain=0

echo "filename,label" > "$output"

for f in "$log_dir"/*.strace; do
    if [ ! -f "$f" ]; then
        continue
    fi

    base=$(basename "$f")
    
    if grep -q 'memfd_create.*up[Xx]"' "$f" ||
   (grep -q 'mprotect.*PROT_EXEC' "$f" && grep -q 'mmap.*PROT_WRITE' "$f"); then
	    echo "$base,packed" >> "$output"
        ((packed++))
	
    else
        echo "$base,plain" >> "$output"
        ((plain++))
    fi
done

echo "Готово. Результат записан в '$output'." >&2
echo "Всего обработано файлов: $((packed + plain))" >&2
echo "  packed: $packed" >&2
echo "  plain:  $plain" >&2