#!/bin/bash

# ---------------------------
# DEFAULT CONFIGURATION
# ---------------------------
BAND_ROOT=""
OUTPUT_ROOT=""
VERBOSE=0
STEP_MODE=0
RAW_FLAG=0

# ---------------------------
# HANDLE FLAGS
# ---------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose) VERBOSE=1 ;;
        -s|--step) STEP_MODE=1 ;;
        -r|--raw) RAW_FLAG=1 ;;
        -i|--input)
            shift
            if [ -n "$1" ]; then
                BAND_ROOT="$1"
            else
                echo "Error: --input requires a folder path"
                exit 1
            fi
            ;;
        -o|--output)
            shift
            if [ -n "$1" ]; then
                OUTPUT_ROOT="$1"
            else
                echo "Error: --output requires a folder path"
                exit 1
            fi
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# ---------------------------
# VALIDATE INPUT
# ---------------------------
if [ -z "$BAND_ROOT" ]; then
    echo "Error: Input folder not specified. Use -i /path/to/folder"
    exit 1
fi

if [ -z "$OUTPUT_ROOT" ]; then
    OUTPUT_ROOT="$BAND_ROOT/Exports"
fi

MP4_FOLDER="$OUTPUT_ROOT/MP4"
mkdir -p "$MP4_FOLDER"

if [ "$RAW_FLAG" -eq 1 ]; then
    RAW_FOLDER="$OUTPUT_ROOT/RAW"
    mkdir -p "$RAW_FOLDER"
fi

# ---------------------------
# LOG FUNCTION
# ---------------------------
log() {
    if [ "$VERBOSE" -eq 1 ]; then
        echo "$@"
    fi
}

# ---------------------------
# PAUSE FUNCTION FOR STEP MODE
# ---------------------------
pause() {
    if [ "$STEP_MODE" -eq 1 ]; then
        echo
        echo "Press [Enter] to process this project, or 's' then [Enter] to skip it..."
        read -r key
        if [ "$key" = "s" ] || [ "$key" = "S" ]; then
            return 1  # skip
        fi
    fi
    return 0
}

# ---------------------------
# PROCESS SINGLE PROJECT
# ---------------------------
process_project() {
    local BAND_PATH="$1"
    local BASE_NAME=$(basename "$BAND_PATH" .band)
    local AUDIO_DIR="$BAND_PATH/Media/Audio Files"

    log "------------------------------"
    log "Processing project: $BASE_NAME"
    log "Audio folder: $AUDIO_DIR"

    # Step mode with skip option
    if ! pause; then
        log "Skipped project: $BASE_NAME"
        return
    fi

    if [ ! -d "$AUDIO_DIR" ]; then
        log "No audio folder found, skipping."
        return
    fi

    # ---------------------------
    # Collect audio files
    # ---------------------------
    AUDIO_FILES=()
    while IFS= read -r -d '' f; do
        AUDIO_FILES+=("$f")
    done < <(find "$AUDIO_DIR" -type f \( -iname "*.caf" -o -iname "*.aif" -o -iname "*.wav" \) -print0)

    if [ "${#AUDIO_FILES[@]}" -eq 0 ]; then
        log "No audio files found, skipping."
        return
    fi

    log "Found ${#AUDIO_FILES[@]} audio files:"
    for f in "${AUDIO_FILES[@]}"; do log "  $f"; done

    # ---------------------------
    # Copy raw audio files if flag set
    # ---------------------------
    if [ "$RAW_FLAG" -eq 1 ]; then
        for f in "${AUDIO_FILES[@]}"; do
            EXT="${f##*.}"  # get file extension
            RAW_FILE="$RAW_FOLDER/${BASE_NAME}.${EXT}"
            
            # Avoid overwriting duplicates
            if [ -f "$RAW_FILE" ]; then
                n=1
                while [ -f "$RAW_FOLDER/${BASE_NAME}_$n.${EXT}" ]; do
                    n=$((n+1))
                done
                RAW_FILE="$RAW_FOLDER/${BASE_NAME}_$n.${EXT}"
            fi

            cp "$f" "$RAW_FILE"
            log "Copied raw audio to: $RAW_FILE"
        done
    fi

    # ---------------------------
    # Build ffmpeg input args
    # ---------------------------
    FFMPEG_ARGS=()
    for f in "${AUDIO_FILES[@]}"; do
        FFMPEG_ARGS+=("-i" "$f")
    done

    # ---------------------------
    # Output MP4 path
    # ---------------------------
    OUTPUT_FILE="$MP4_FOLDER/${BASE_NAME}.mp4"
    # Handle duplicates
    if [ -f "$OUTPUT_FILE" ]; then
        n=1
        while [ -f "$MP4_FOLDER/${BASE_NAME}_$n.mp4" ]; do
            n=$((n+1))
        done
        OUTPUT_FILE="$MP4_FOLDER/${BASE_NAME}_$n.mp4"
    fi

    # ---------------------------
    # Mix into MP4
    # ---------------------------
    log "Mixing into MP4: $OUTPUT_FILE"
    ffmpeg -y "${FFMPEG_ARGS[@]}" -filter_complex "amerge=inputs=${#AUDIO_FILES[@]}" -ac 2 -c:a aac "$OUTPUT_FILE"
    log "Created MP4: $OUTPUT_FILE"
}

# ---------------------------
# MAIN LOOP
# ---------------------------
BAND_DIRS=()
while IFS= read -r -d '' dir; do
    BAND_DIRS+=("$dir")
done < <(find "$BAND_ROOT" -type d -name "*.band" -print0)

for BAND_PATH in "${BAND_DIRS[@]}"; do
    process_project "$BAND_PATH"
done

log "All projects processed."
