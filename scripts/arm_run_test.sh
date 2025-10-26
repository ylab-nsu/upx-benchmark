LOG_FILE="${PWD}/armtest.log"
PROGRAM="${PWD}/../build/debug/upx"
SOURCE_ROOT="${PWD}/build/aarch64"
TEMP_DIR="${PWD}/build/upx_arm"

rm -f "$LOG_FILE"
rm -rf "$TEMP_DIR" && echo "Старые временные файлы удалены." >> "$LOG_FILE"
mkdir -p "$TEMP_DIR"

if [ ! -x "$PROGRAM" ]; then
    echo "Ошибка: программа не найдена или не исполняема: $PROGRAM" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Ищем исполняемые файлы в: $SOURCE_ROOT"
mapfile -t FILES < <(find "$SOURCE_ROOT" -type f -executable -not -name ".*" 2>/dev/null | sort)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Не найдено исполняемых файлов в $SOURCE_ROOT" >> "$LOG_FILE"
    exit 1
fi

echo "Найдено файлов: ${#FILES[@]}" >> "$LOG_FILE"
echo "Файлы:" >> "$LOG_FILE"
printf '  %s\n' "${FILES[@]}" >> "$LOG_FILE"

TEMP_FILES=()
for file in "${FILES[@]}"; do
    filename="temp_$(basename "$file")"
    dest="$TEMP_DIR/$filename"
    cp "$file" "$dest"
    chmod +x "$dest"
    TEMP_FILES+=("$dest")
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Запуск upx для ${#TEMP_FILES[@]} файлов..." >> "$LOG_FILE"

"$PROGRAM" "${TEMP_FILES[@]}" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Завершено с кодом: $EXIT_CODE" >> "$LOG_FILE"

echo "Лог сохранён: $LOG_FILE"