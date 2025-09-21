#!/bin/bash

# payload.sh - Script to clone repositories, install dependencies, and execute final steps

# Configuration
REPO1_URL="https://github.com/kishorkumartv000/amd-aio-mltb-update-08"
REPO2_URL="https://github.com/exislow/tidal-dl-ng.git"
TARGET_DIR1="/usr/src/app/amd-aio-for-curser"
TARGET_DIR2="/usr/src/app/tidal-dl-ng"
WORKING_DIR="/usr/src/app"
LOG_FILE="/var/log/payload.log"

INSTALL_DEPS_REPO1=true
INSTALL_DEPS_REPO2=false
INSTALL_POETRY=false

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log_message "🚀 Starting repository cloning and setup"
log_message "Flags: INSTALL_DEPS_REPO1=$INSTALL_DEPS_REPO1, INSTALL_DEPS_REPO2=$INSTALL_DEPS_REPO2, INSTALL_POETRY=$INSTALL_POETRY"

# STEP 1: Clone first repo
log_message "STEP 1: Cloning $REPO1_URL"
git clone "$REPO1_URL" "$TARGET_DIR1" 2>&1 | tee -a "$LOG_FILE"
[ $? -eq 0 ] && log_message "✓ Repo1 cloned to $TARGET_DIR1" || { log_message "✗ Failed to clone Repo1"; exit 1; }

# STEP 2: Clone second repo
log_message "STEP 2: Cloning $REPO2_URL"
git clone "$REPO2_URL" "$TARGET_DIR2" 2>&1 | tee -a "$LOG_FILE"
[ $? -eq 0 ] && log_message "✓ Repo2 cloned to $TARGET_DIR2" || { log_message "✗ Failed to clone Repo2"; exit 1; }

# STEP 3: Install Repo1 dependencies
if [ "$INSTALL_DEPS_REPO1" = true ]; then
    log_message "STEP 3: Installing dependencies for Repo1"
    cd "$TARGET_DIR1" || { log_message "✗ Cannot cd to $TARGET_DIR1"; exit 1; }
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt 2>&1 | tee -a "$LOG_FILE"
        [ $? -eq 0 ] && log_message "✓ Repo1 dependencies installed" || { log_message "✗ Failed to install Repo1 dependencies"; exit 1; }
    else
        log_message "ℹ No requirements.txt found in Repo1"
    fi
else
    log_message "SKIP: Repo1 dependency install disabled"
fi

# STEP 4: Install tidal-dl-ng
if [ "$INSTALL_DEPS_REPO2" = true ]; then
    log_message "STEP 4: Installing tidal-dl-ng"
    cd "$TARGET_DIR2" || { log_message "✗ Cannot cd to $TARGET_DIR2"; exit 1; }
    pip install --upgrade tidal-dl-ng 2>&1 | tee -a "$LOG_FILE"
    [ $? -eq 0 ] && log_message "✓ tidal-dl-ng installed" || { log_message "✗ Failed to install tidal-dl-ng"; exit 1; }
else
    log_message "SKIP: Repo2 dependency install disabled"
fi

# STEP 5: Install pipx
if [ "$INSTALL_POETRY" = true ]; then
    log_message "STEP 5: Installing pipx"
    pip install --user pipx 2>&1 | tee -a "$LOG_FILE"
    export PATH="$HOME/.local/bin:$PATH"
    python -m pipx ensurepath 2>&1 | tee -a "$LOG_FILE"
else
    log_message "SKIP: pipx install disabled"
fi

# STEP 6: Install Poetry
if [ "$INSTALL_POETRY" = true ]; then
    log_message "STEP 6: Installing Poetry"
    pipx install poetry 2>&1 | tee -a "$LOG_FILE"
    if [ $? -ne 0 ]; then
        log_message "ℹ pipx failed, trying pip"
        pip install --user poetry 2>&1 | tee -a "$LOG_FILE"
        [ $? -eq 0 ] && log_message "✓ Poetry installed via pip" || { log_message "✗ Failed to install Poetry"; exit 1; }
    else
        log_message "✓ Poetry installed via pipx"
    fi
else
    log_message "SKIP: Poetry install disabled"
fi

# STEP 7: Install Poetry dependencies
if [ "$INSTALL_DEPS_REPO2" = true ] && [ "$INSTALL_POETRY" = true ]; then
    log_message "STEP 7: Installing Poetry dependencies for Repo2"
    cd "$TARGET_DIR2" || { log_message "✗ Cannot cd to $TARGET_DIR2"; exit 1; }
    poetry install --all-extras --with dev,docs 2>&1 | tee -a "$LOG_FILE"
    [ $? -eq 0 ] && log_message "✓ Poetry dependencies installed" || { log_message "✗ Failed to install Poetry dependencies"; exit 1; }
else
    log_message "SKIP: Poetry dependency install disabled"
fi

# STEP 8: Move Repo1 files to working dir
log_message "STEP 8: Moving Repo1 files to $WORKING_DIR"
find "$TARGET_DIR1" -mindepth 1 -maxdepth 1 -exec mv -t "$WORKING_DIR" {} + 2>&1 | tee -a "$LOG_FILE"
rmdir "$TARGET_DIR1" 2>&1 | tee -a "$LOG_FILE"
log_message "✓ Repo1 files moved"

# STEP 9: Final setup
log_message "STEP 9: Final setup in $WORKING_DIR"
cd "$WORKING_DIR" || { log_message "✗ Cannot cd to $WORKING_DIR"; exit 1; }
chmod 777 "$WORKING_DIR"/* 2>&1 | tee -a "$LOG_FILE"

if [ -f "sample.env" ]; then
    mv sample.env .env 2>&1 | tee -a "$LOG_FILE"
    log_message "✓ sample.env renamed to .env"
else
    log_message "ℹ sample.env not found"
fi

if [ -f "start.sh" ]; then
    bash start.sh 2>&1 | tee -a "$LOG_FILE"
    [ $? -eq 0 ] && log_message "✓ start.sh executed" || { log_message "✗ start.sh failed"; exit 1; }
else
    log_message "ℹ start.sh not found"
fi

log_message "✅ All steps completed successfully"
