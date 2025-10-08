#!/bin/zsh
# Smart Alias Manager - Simple Loader
# Single entry point for loading all alias packs and functions

# Determine script directory
SCRIPT_DIR="${0:A:h}"

# Configuration file location
CONFIG_FILE="${HOME}/.config/smart-aliases/config.json"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "⚠️  Smart Alias Manager: jq is required but not installed"
    echo "   Install: sudo apt-get install jq (or brew install jq)"
    return 1
fi

# Check if config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "⚠️  Smart Alias Manager: config.json not found at $CONFIG_FILE"
    return 1
fi

# Read configuration
AUTO_LOAD=$(jq -r '.settings.auto_load // true' "$CONFIG_FILE")
SHOW_MESSAGES=$(jq -r '.settings.show_loading_messages // true' "$CONFIG_FILE")

# Source the pack management system
if [[ -f "${SCRIPT_DIR}/alias-enable.sh" ]]; then
    source "${SCRIPT_DIR}/alias-enable.sh"
else
    echo "⚠️  Smart Alias Manager: alias-enable.sh not found"
    return 1
fi

# Auto-load enabled packs if configured
if [[ "$AUTO_LOAD" == "true" ]]; then
    if [[ "$SHOW_MESSAGES" == "false" ]]; then
        # Silent loading
        alias-autoload 2>/dev/null
    else
        # Normal loading with messages
        alias-autoload
    fi
fi

# Load core functions
if [[ -f "${SCRIPT_DIR}/functions.sh" ]]; then
    source "${SCRIPT_DIR}/functions.sh"
fi

# Load alias management commands (alias-new, alias-analyze, etc.)
if [[ -f "${SCRIPT_DIR}/alias-manager.sh" ]]; then
    source "${SCRIPT_DIR}/alias-manager.sh"
fi

# Export useful variables
export SMART_ALIAS_MANAGER_DIR="${SCRIPT_DIR:h}"
export SMART_ALIAS_CONFIG="${CONFIG_FILE}"
