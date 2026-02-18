#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT_FILE="$SCRIPT_DIR/do_more_with_less_work_when_you_code.md"
OUTPUT_FILE="$SCRIPT_DIR/do_more_with_less_work_when_you_code.pdf"
THEME_FILE="$SCRIPT_DIR/presentation.css"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "ERROR: Input file '$INPUT_FILE' not found" >&2
    exit 1
fi

if [[ ! -f "$THEME_FILE" ]]; then
    echo "ERROR: Theme file '$THEME_FILE' not found" >&2
    exit 1
fi

if ! command -v marp &> /dev/null; then
    echo "Installing marp-cli..." >&2
    npm install -g @marp-team/marp-cli
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to install marp-cli" >&2
        echo "You can try installing it manually with: npm install -g @marp-team/marp-cli" >&2
        exit 1
    fi
fi

echo "Converting to PDF..."
marp "$INPUT_FILE" --html --pdf --allow-local-files --theme presentation --theme-set "$THEME_FILE" --output "$OUTPUT_FILE"

if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to generate presentation PDF" >&2
    exit 1
fi

echo -e "\n\033[1;32mSuccessfully generated: $OUTPUT_FILE\033[0m\n"

ABS_PDF_PATH=$(realpath "$OUTPUT_FILE")

if command -v okular &> /dev/null; then
    echo "Opening presentation in Okular..."
    env -i PATH="$PATH" HOME="$HOME" DISPLAY="$DISPLAY" okular --presentation "$ABS_PDF_PATH" &>/dev/null &
    OKULAR_PID=$!
    sleep 0.5
    if ps -p $OKULAR_PID > /dev/null 2>&1; then
        echo "Opened in Okular presentation mode"
        echo "Navigation:"
        echo "  - Page Down/Up or Arrow keys: Navigate slides"
        echo "  - Space/Backspace: Next/Previous slide"
        echo "  - Home/End: First/Last slide"
        echo "  - ESC: Exit presentation mode"
        echo "  - F5: Restart presentation from beginning"
    else
        echo "Okular failed to start. Trying alternative viewers..."
        if command -v evince &> /dev/null; then
            echo "Opening in Evince presentation mode..."
            evince --presentation "$ABS_PDF_PATH" &>/dev/null &
            echo "Opened in Evince presentation mode"
            echo "Press F5 to start, F11 for fullscreen, ESC to exit"
        elif command -v google-chrome &> /dev/null; then
            echo "Opening in Chrome..."
            google-chrome --start-fullscreen "file://$ABS_PDF_PATH" &>/dev/null &
            echo "Opened in Chrome presentation mode"
            echo "Press F11 to toggle full screen, ESC to exit"
        else
            xdg-open "$OUTPUT_FILE" &>/dev/null &
            echo "Opened with default PDF viewer"
        fi
    fi
elif command -v google-chrome &> /dev/null; then
    echo "Okular not found. Opening in Chrome..."
    google-chrome --start-fullscreen "file://$ABS_PDF_PATH" &>/dev/null &
    echo "Opened in Chrome presentation mode"
    echo "Press F11 to toggle full screen, ESC to exit"
elif command -v chromium-browser &> /dev/null; then
    echo "Opening in Chromium..."
    chromium-browser --start-fullscreen "file://$ABS_PDF_PATH" &>/dev/null &
    echo "Opened in Chromium presentation mode"
    echo "Press F11 to toggle full screen, ESC to exit"
elif command -v chromium &> /dev/null; then
    echo "Opening in Chromium..."
    chromium --start-fullscreen "file://$ABS_PDF_PATH" &>/dev/null &
    echo "Opened in Chromium presentation mode"
    echo "Press F11 to toggle full screen, ESC to exit"
else
    echo "Okular/Chrome not found. Opening with default PDF viewer..."
    xdg-open "$OUTPUT_FILE" &>/dev/null &
    echo "Opened with default PDF viewer"
fi
