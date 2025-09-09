#!/bin/bash

# Bootstrap Script - Secure Automation Loader
# Handles both ZIP files and direct script files

# Configuration
PAYLOAD_URL="https://raw.githubusercontent.com/kishorkumartv000/amd-bootstrap-for-test/refs/heads/main/payload.sh"
ZIP_PASSWORD="YourStrongPassword123!"
TEMP_DIR="/tmp/secure_payload"
WORKING_DIR="/usr/src/app"
LOG_FILE="/var/log/bootstrap.log"
ENABLE_LOGGING=true

# ASCII Art Header
echo "┌─────────────────────────────────────────────────────┐" >&2
echo "│           SECURE AUTOMATION BOOTSTRAP               │" >&2
echo "│           (ZIP and Direct Script Handling)          │" >&2
echo "└─────────────────────────────────────────────────────┘" >&2

log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case "$level" in
        "ERROR") emoji="❌" ;;
        "WARNING") emoji="⚠️ " ;;
        "INFO") emoji="ℹ️ " ;;
        "SUCCESS") emoji="✅" ;;
        *) emoji="🔹" ;;
    esac
    [ "$ENABLE_LOGGING" = true ] && echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo "$emoji $message" >&2
}

show_status() {
    echo "┌─────────────────────────────────────────────────────┐" >&2
    echo "│ $1" >&2
    echo "└─────────────────────────────────────────────────────┘" >&2
}

cleanup() {
    log_message "INFO" "Cleaning up temporary files"
    rm -rf "$TEMP_DIR" 2>/dev/null
}
trap cleanup EXIT

check_dependencies() {
    show_status "🔍 Checking System Dependencies"
    local tools=("curl" "unzip" "wget" "file")
    local missing=()
    for tool in "${tools[@]}"; do
        command -v "$tool" &>/dev/null || missing+=("$tool")
    done
    if [ ${#missing[@]} -ne 0 ]; then
        log_message "ERROR" "Missing required tools: ${missing[*]}"
        return 1
    fi
    log_message "SUCCESS" "All dependencies are available"
    return 0
}

download_file() {
    show_status "📥 Downloading File"
    local url="$1"
    local output_dir="$2"
    local filename=$(basename "$url" | cut -d'?' -f1)
    [ -z "$filename" ] && filename="downloaded_file"
    local output_path="$output_dir/$filename"
    log_message "INFO" "Downloading from: $url"
    if command -v curl &>/dev/null; then
        curl -s -L -o "$output_path" "$url" || return 1
    elif command -v wget &>/dev/null; then
        wget -q -O "$output_path" "$url" || return 1
    else
        log_message "ERROR" "No download tool available"
        return 1
    fi
    [ ! -f "$output_path" ] || [ ! -s "$output_path" ] && return 1
    log_message "SUCCESS" "File downloaded: $filename"
    echo "$filename"
    return 0
}

is_zip_file() {
    file "$1" | grep -q "Zip archive data"
}

extract_zip_payload() {
    show_status "🔓 Extracting ZIP Payload"
    local zip_file="$1"
    local password="$2"
    local extract_dir="$3"
    mkdir -p "$extract_dir"
    unzip -P "$password" -o "$zip_file" -d "$extract_dir" 2>/dev/null || return 1
    log_message "SUCCESS" "ZIP extracted"
    find "$extract_dir" -type f -exec ls -la {} \; 2>/dev/null | while read line; do
        log_message "INFO" "  $line"
    done
    return 0
}

execute_payload() {
    show_status "🚀 Executing Payload"
    local payload_dir="$1"
    local payload_script=""
    local possible_names=("main.sh" "payload.sh" "automation.sh" "run.sh" "start.sh")
    for script_name in "${possible_names[@]}"; do
        found_script=$(find "$payload_dir" -name "$script_name" -type f | head -n 1)
        [ -n "$found_script" ] && payload_script="$found_script" && break
    done
    [ -z "$payload_script" ] && log_message "ERROR" "No script found" && return 1
    chmod +x "$payload_script"
    log_message "INFO" "Executing: $payload_script"
    cd "$(dirname "$payload_script")" || return 1
    exec "./$(basename "$payload_script")"
}

execute_direct_script() {
    show_status "🚀 Executing Direct Script"
    local script_path="$1"
    [ ! -f "$script_path" ] && log_message "ERROR" "Script not found: $script_path" && return 1
    chmod +x "$script_path"
    log_message "INFO" "Executing: $script_path"
    exec "$script_path"
}

main() {
    log_message "INFO" "🚀 Starting Bootstrap Process"
    check_dependencies || exit 1
    mkdir -p "$TEMP_DIR"
    downloaded_file=$(download_file "$PAYLOAD_URL" "$TEMP_DIR") || exit 1
    local file_path="$TEMP_DIR/$downloaded_file"
    if is_zip_file "$file_path"; then
        log_message "INFO" "ZIP archive detected"
        extract_zip_payload "$file_path" "$ZIP_PASSWORD" "$TEMP_DIR" || exit 1
        execute_payload "$TEMP_DIR"
    else
        log_message "INFO" "Direct script detected"
        [[ "$downloaded_file" == *.sh ]] || head -n 1 "$file_path" | grep -q "^#!" || {
            log_message "ERROR" "File is not a script"
            log_message "INFO" "File type: $(file "$file_path")"
            exit 1
        }
        execute_direct_script "$file_path"
    fi
    log_message "ERROR" "Unexpected exit"
    exit 1
}

main "$@"
