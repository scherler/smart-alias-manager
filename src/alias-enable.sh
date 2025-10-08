#!/bin/zsh
# Alias Pack Manager - Enable/disable custom alias packs
# Part of Smart Alias Manager

# Configuration
ALIAS_CONFIG_DIR="${HOME}/.config/smart-aliases"
CONFIG_FILE="${ALIAS_CONFIG_DIR}/config.json"
PACKS_DIR="${ALIAS_CONFIG_DIR}/packs"
LOCAL_PACKS_DIR="${PACKS_DIR}/local"
COMMUNITY_PACKS_DIR="${PACKS_DIR}/community"
CACHE_DIR="${PACKS_DIR}/cache"

# Ensure directories exist
mkdir -p "${LOCAL_PACKS_DIR}" "${COMMUNITY_PACKS_DIR}" "${CACHE_DIR}"

# Initialize config file if it doesn't exist
if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo '{"version": "1.0.0", "enabled_packs": [], "settings": {"auto_load": true}}' > "${CONFIG_FILE}"
fi

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if jq is available for JSON parsing
check_jq() {
    if ! command_exists jq; then
        echo "❌ Error: jq is required for alias pack management"
        echo "Install: sudo apt-get install jq (or brew install jq on macOS)"
        return 1
    fi
    return 0
}

# Validate pack JSON structure
validate_pack() {
    local pack_file="$1"

    if [[ ! -f "$pack_file" ]]; then
        echo "❌ Pack file not found: $pack_file"
        return 1
    fi

    # Check if valid JSON
    if ! jq empty "$pack_file" 2>/dev/null; then
        echo "❌ Invalid JSON in pack file: $pack_file"
        return 1
    fi

    # Check required fields
    local name=$(jq -r '.name // empty' "$pack_file")
    local version=$(jq -r '.version // empty' "$pack_file")

    if [[ -z "$name" ]]; then
        echo "❌ Pack missing required field: name"
        return 1
    fi

    if [[ -z "$version" ]]; then
        echo "❌ Pack missing required field: version"
        return 1
    fi

    return 0
}

# Check pack requirements
check_requirements() {
    local pack_file="$1"
    local errors=0

    # Check required commands
    local required_commands=$(jq -r '.requires.commands[]? // empty' "$pack_file")
    if [[ -n "$required_commands" ]]; then
        echo "$required_commands" | while read cmd; do
            if ! command_exists "$cmd"; then
                echo "⚠️  Warning: Required command not found: $cmd"
                ((errors++))
            fi
        done
    fi

    return $errors
}

# Load pack and create aliases/functions
load_pack() {
    local pack_file="$1"
    local pack_name=$(jq -r '.name' "$pack_file")

    echo "📦 Loading pack: $pack_name"

    # Load aliases
    local alias_count=0
    while IFS= read -r alias_json; do
        local name=$(echo "$alias_json" | jq -r '.name')
        local type=$(echo "$alias_json" | jq -r '.type')
        local enabled=$(echo "$alias_json" | jq -r '.enabled // true')

        if [[ "$enabled" != "true" ]]; then
            continue
        fi

        if [[ "$type" == "alias" ]]; then
            local command=$(echo "$alias_json" | jq -r '.command')
            alias "$name"="$command"
            ((alias_count++))
        elif [[ "$type" == "global" ]]; then
            local command=$(echo "$alias_json" | jq -r '.command')
            alias -g "$name"="$command"
            ((alias_count++))
        fi
    done < <(jq -c '.aliases[]?' "$pack_file")

    # Load functions
    local function_count=0
    # Temporarily disabled due to JSON encoding issues with complex function bodies
    # Functions with newlines/tabs need proper escaping in JSON
    # TODO: Fix function extraction to properly escape control characters
    # while IFS= read -r func_json; do
    #     local name=$(echo "$func_json" | jq -r '.name')
    #     local body=$(echo "$func_json" | jq -r '.body')
    #
    #     # Create function using eval
    #     eval "function $name { $body }"
    #     ((function_count++))
    # done < <(jq -c '.functions[]?' "$pack_file")

    echo "✅ Loaded $alias_count aliases and $function_count functions from $pack_name"
}

# Download pack from URL
download_pack() {
    local url="$1"
    local cache_file="${CACHE_DIR}/$(echo -n "$url" | md5sum | cut -d' ' -f1).json"

    echo "📥 Downloading pack from URL..."

    if command_exists curl; then
        if curl -fsSL "$url" -o "$cache_file"; then
            echo "$cache_file"
            return 0
        fi
    elif command_exists wget; then
        if wget -q "$url" -O "$cache_file"; then
            echo "$cache_file"
            return 0
        fi
    else
        echo "❌ Error: curl or wget required to download packs"
        return 1
    fi

    echo "❌ Failed to download pack from $url"
    return 1
}

# Find pack file by name
find_pack() {
    local pack_name="$1"

    # Check local packs first
    if [[ -f "${LOCAL_PACKS_DIR}/${pack_name}.json" ]]; then
        echo "${LOCAL_PACKS_DIR}/${pack_name}.json"
        return 0
    fi

    # Check community packs
    if [[ -f "${COMMUNITY_PACKS_DIR}/${pack_name}.json" ]]; then
        echo "${COMMUNITY_PACKS_DIR}/${pack_name}.json"
        return 0
    fi

    # Check cache
    for cached in "${CACHE_DIR}"/*.json; do
        if [[ -f "$cached" ]]; then
            local name=$(jq -r '.name' "$cached" 2>/dev/null)
            if [[ "$name" == "$pack_name" ]]; then
                echo "$cached"
                return 0
            fi
        fi
    done

    return 1
}

# Add pack to enabled list
enable_pack_persistent() {
    local pack_name="$1"
    local pack_file="$2"

    # Read current enabled packs
    local enabled=$(jq '.enabled_packs' "$CONFIG_FILE")

    # Add if not already present
    if ! echo "$enabled" | jq -e ".[] | select(. == \"$pack_name\")" > /dev/null 2>&1; then
        jq ".enabled_packs += [\"$pack_name\"]" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
}

# Remove pack from enabled list
disable_pack_persistent() {
    local pack_name="$1"

    jq ".enabled_packs = (.enabled_packs - [\"$pack_name\"])" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

# List enabled packs
list_enabled() {
    check_jq || return 1

    echo "📋 Enabled Alias Packs:"
    echo ""

    local count=0
    while IFS= read -r pack_name; do
        local pack_file=$(find_pack "$pack_name")
        if [[ -n "$pack_file" ]]; then
            local version=$(jq -r '.version' "$pack_file")
            local desc=$(jq -r '.description' "$pack_file")
            echo "  ✓ $pack_name (v$version)"
            echo "    $desc"
            echo ""
            ((count++))
        fi
    done < <(jq -r '.enabled_packs[]' "$CONFIG_FILE")

    if [[ $count -eq 0 ]]; then
        echo "  No packs enabled yet."
        echo ""
        echo "  💡 Enable a pack with: alias-enable <pack-name>"
    fi
}

# Show pack info
show_pack_info() {
    local pack_name="$1"

    check_jq || return 1

    local pack_file=$(find_pack "$pack_name")
    if [[ -z "$pack_file" ]]; then
        echo "❌ Pack not found: $pack_name"
        return 1
    fi

    echo "📦 Pack Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local name=$(jq -r '.name' "$pack_file")
    local version=$(jq -r '.version' "$pack_file")
    local author=$(jq -r '.author // "Unknown"' "$pack_file")
    local desc=$(jq -r '.description // "No description"' "$pack_file")
    local license=$(jq -r '.license // "Unknown"' "$pack_file")

    echo "Name:        $name"
    echo "Version:     $version"
    echo "Author:      $author"
    echo "License:     $license"
    echo "Description: $desc"
    echo ""

    # Count items
    local alias_count=$(jq '[.aliases[]?] | length' "$pack_file")
    local func_count=$(jq '[.functions[]?] | length' "$pack_file")

    echo "Contents:    $alias_count aliases, $func_count functions"
    echo ""

    # Show aliases
    if [[ $alias_count -gt 0 ]]; then
        echo "Aliases:"
        jq -r '.aliases[] | "  \(.name) → \(.command // .description)"' "$pack_file"
        echo ""
    fi

    # Show functions
    if [[ $func_count -gt 0 ]]; then
        echo "Functions:"
        jq -r '.functions[] | "  \(.name) - \(.description)"' "$pack_file"
        echo ""
    fi
}

# Search for packs
search_packs() {
    local query="$1"

    echo "🔍 Searching for packs matching: $query"
    echo ""

    local found=0
    for pack_dir in "$LOCAL_PACKS_DIR" "$COMMUNITY_PACKS_DIR" "$CACHE_DIR"; do
        for pack_file in "$pack_dir"/*.json; do
            if [[ -f "$pack_file" ]]; then
                local name=$(jq -r '.name' "$pack_file" 2>/dev/null)
                local desc=$(jq -r '.description' "$pack_file" 2>/dev/null)
                local tags=$(jq -r '.tags[]?' "$pack_file" 2>/dev/null)

                if [[ "$name" == *"$query"* ]] || [[ "$desc" == *"$query"* ]] || [[ "$tags" == *"$query"* ]]; then
                    echo "  📦 $name"
                    echo "     $desc"
                    echo ""
                    ((found++))
                fi
            fi
        done
    done

    if [[ $found -eq 0 ]]; then
        echo "  No packs found matching '$query'"
    fi
}

# Main alias-enable function
alias-enable() {
    if [[ $# -eq 0 ]]; then
        list_enabled
        return 0
    fi

    case "$1" in
        --help|-h)
            echo "🚀 Alias Pack Manager"
            echo ""
            echo "Usage: alias-enable [OPTIONS] [PACK]"
            echo ""
            echo "Options:"
            echo "  --list, -l          List enabled packs"
            echo "  --info PACK         Show pack information"
            echo "  --disable PACK      Disable a pack"
            echo "  --search QUERY      Search for packs"
            echo "  --reload            Reload all enabled packs"
            echo "  --help, -h          Show this help"
            echo ""
            echo "Arguments:"
            echo "  PACK                Pack name or URL to enable"
            echo ""
            echo "Examples:"
            echo "  alias-enable git-essentials          # Enable local pack"
            echo "  alias-enable https://example.com/pack.json  # Enable from URL"
            echo "  alias-enable --info docker-essentials"
            echo "  alias-enable --disable git-essentials"
            echo "  alias-enable --search docker"
            echo ""
            echo "Pack locations:"
            echo "  Local:     ~/.config/smart-aliases/packs/local/"
            echo "  Community: ~/.config/smart-aliases/packs/community/"
            echo "  Cache:     ~/.config/smart-aliases/packs/cache/"
            return 0
            ;;
        --list|-l)
            list_enabled
            return 0
            ;;
        --info)
            show_pack_info "$2"
            return $?
            ;;
        --disable)
            if [[ -z "$2" ]]; then
                echo "❌ Error: Pack name required"
                return 1
            fi
            check_jq || return 1
            disable_pack_persistent "$2"
            echo "✅ Disabled pack: $2"
            echo "💡 Restart your shell or run 'source ~/.zshrc' to apply changes"
            return 0
            ;;
        --search)
            if [[ -z "$2" ]]; then
                echo "❌ Error: Search query required"
                return 1
            fi
            check_jq || return 1
            search_packs "$2"
            return 0
            ;;
        --reload)
            check_jq || return 1
            echo "♻️  Reloading enabled packs..."
            while IFS= read -r pack_name; do
                local pack_file=$(find_pack "$pack_name")
                if [[ -n "$pack_file" ]]; then
                    load_pack "$pack_file"
                fi
            done < <(jq -r '.enabled_packs[]' "$CONFIG_FILE")
            return 0
            ;;
        *)
            # Enable a pack
            check_jq || return 1

            local pack_source="$1"
            local pack_file=""

            # Check if it's a URL
            if [[ "$pack_source" =~ ^https?:// ]]; then
                pack_file=$(download_pack "$pack_source")
                [[ $? -ne 0 ]] && return 1
            else
                # Local pack name
                pack_file=$(find_pack "$pack_source")
                if [[ -z "$pack_file" ]]; then
                    echo "❌ Pack not found: $pack_source"
                    echo ""
                    echo "Available packs:"
                    for p in "$LOCAL_PACKS_DIR"/*.json "$COMMUNITY_PACKS_DIR"/*.json; do
                        if [[ -f "$p" ]]; then
                            echo "  - $(basename "$p" .json)"
                        fi
                    done
                    return 1
                fi
            fi

            # Validate pack
            validate_pack "$pack_file" || return 1

            # Check requirements
            check_requirements "$pack_file"

            # Load pack
            load_pack "$pack_file"

            # Add to enabled list
            local pack_name=$(jq -r '.name' "$pack_file")
            enable_pack_persistent "$pack_name" "$pack_file"

            echo ""
            echo "💡 Pack will be loaded automatically on next shell startup"
            echo "💡 Or run: alias-enable --reload"

            return 0
            ;;
    esac
}

# Auto-load enabled packs on shell startup (call this from .zshrc)
alias-autoload() {
    if [[ -f "${CONFIG_FILE}" ]] && command_exists jq; then
        while IFS= read -r pack_name; do
            local pack_file=$(find_pack "$pack_name")
            if [[ -n "$pack_file" ]]; then
                load_pack "$pack_file"
            fi
        done < <(jq -r '.enabled_packs[]' "$CONFIG_FILE" 2>/dev/null)
    fi
}

# Export functions
alias ae='alias-enable'  # Short alias
