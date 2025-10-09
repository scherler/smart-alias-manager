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
METADATA_FILE="${ALIAS_CONFIG_DIR}/metadata.json"
CONFLICTS_LOG="${ALIAS_CONFIG_DIR}/conflicts.log"
CACHE_FILE="${ALIAS_CONFIG_DIR}/cache.sh"

# Ensure directories exist
mkdir -p "${LOCAL_PACKS_DIR}" "${COMMUNITY_PACKS_DIR}" "${CACHE_DIR}"

# Initialize config file if it doesn't exist
if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo '{"version": "1.0.0", "enabled_packs": [], "settings": {"auto_load": true}}' > "${CONFIG_FILE}"
fi

# Initialize metadata file if it doesn't exist
if [[ ! -f "${METADATA_FILE}" ]]; then
    echo '{"alias_sources": {}, "conflicts": {}}' > "${METADATA_FILE}"
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

# Record alias source in metadata
record_alias_source() {
    local alias_name="$1"
    local pack_name="$2"

    jq ".alias_sources[\"$alias_name\"] = \"$pack_name\"" "$METADATA_FILE" > "${METADATA_FILE}.tmp"
    mv "${METADATA_FILE}.tmp" "$METADATA_FILE"
}

# Get alias source pack
get_alias_source() {
    local alias_name="$1"
    jq -r ".alias_sources[\"$alias_name\"] // \"custom\"" "$METADATA_FILE" 2>/dev/null || echo "custom"
}

# Log conflict to file
log_conflict() {
    local alias_name="$1"
    local existing_pack="$2"
    local new_pack="$3"
    local existing_cmd="$4"
    local new_cmd="$5"
    local resolution="$6"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    cat >> "$CONFLICTS_LOG" <<EOF
[$timestamp] CONFLICT: $alias_name
  Existing: $existing_pack → $existing_cmd
  New:      $new_pack → $new_cmd
  Resolution: $resolution

EOF

    # Also record in metadata
    jq ".conflicts[\"$alias_name\"] = {\"existing_pack\": \"$existing_pack\", \"new_pack\": \"$new_pack\", \"resolution\": \"$resolution\", \"timestamp\": \"$timestamp\"}" "$METADATA_FILE" > "${METADATA_FILE}.tmp"
    mv "${METADATA_FILE}.tmp" "$METADATA_FILE"
}

# Suggest alternative alias names
suggest_alternatives() {
    local alias_name="$1"
    local suggestions=()

    # Try appending numbers
    for i in {2..5}; do
        if ! alias "$alias_name$i" &>/dev/null; then
            suggestions+=("$alias_name$i")
            break
        fi
    done

    # Try different prefixes based on alias pattern
    if [[ ${#alias_name} -eq 2 ]]; then
        # Two-letter alias, try adding third letter
        local prefix="${alias_name:0:1}"
        local chars=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
        for char in "${chars[@]}"; do
            local alt="${alias_name}${char}"
            if ! alias "$alt" &>/dev/null && [[ ! " ${suggestions[@]} " =~ " ${alt} " ]]; then
                suggestions+=("$alt")
                [[ ${#suggestions[@]} -ge 3 ]] && break
            fi
        done
    else
        # Try shortening or alternate abbreviations
        if [[ ${#alias_name} -gt 2 ]]; then
            local short="${alias_name:0:2}"
            if ! alias "$short" &>/dev/null; then
                suggestions+=("$short")
            fi
        fi
    fi

    # Print suggestions
    for suggestion in "${suggestions[@]}"; do
        echo "$suggestion"
    done
}

# Check for alias conflicts before loading
check_alias_conflicts() {
    local pack_file="$1"
    local pack_name=$(jq -r '.name' "$pack_file")
    local conflicts=()
    local conflict_details=()

    # Check all aliases in the pack
    while IFS= read -r alias_json; do
        local name=$(echo "$alias_json" | jq -r '.name')
        local command=$(echo "$alias_json" | jq -r '.command')
        local enabled=$(echo "$alias_json" | jq -r '.enabled // true')

        if [[ "$enabled" != "true" ]]; then
            continue
        fi

        # Check if alias already exists
        local existing=$(alias "$name" 2>/dev/null)
        if [[ -n "$existing" ]]; then
            local existing_cmd="${existing#*=}"
            local existing_pack=$(get_alias_source "$name")

            # Only conflict if commands are different
            if [[ "$existing_cmd" != "'$command'" && "$existing_cmd" != "\"$command\"" ]]; then
                conflicts+=("$name")
                conflict_details+=("$name|$existing_pack|$pack_name|${existing_cmd}|$command")
            fi
        fi
    done < <(jq -c '.aliases[]?' "$pack_file")

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        return 0
    fi

    # Display conflicts
    echo "⚠️  CONFLICTS DETECTED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The following aliases in '$pack_name' conflict with existing aliases:"
    echo ""

    for detail in "${conflict_details[@]}"; do
        IFS='|' read -r alias_name existing_pack new_pack existing_cmd new_cmd <<< "$detail"
        echo "  ❌ $alias_name"
        echo "     Current ($existing_pack): $existing_cmd"
        echo "     New     ($new_pack): $new_cmd"
        echo ""

        # Suggest alternatives
        echo "     💡 Suggested alternatives:"
        local alts=($(suggest_alternatives "$alias_name"))
        for alt in "${alts[@]:0:3}"; do
            echo "        - $alt (available)"
        done
        echo ""
    done

    echo "Options:"
    echo "  1. Skip - Don't load conflicting aliases (safe)"
    echo "  2. Override - Replace existing aliases with new ones (⚠️  replaces $existing_pack)"
    echo "  3. Cancel - Don't enable this pack"
    echo ""
    echo -n "Choose [1/2/3] (default: 1): "
    read choice

    case "$choice" in
        2)
            # Override - allow conflicts
            for detail in "${conflict_details[@]}"; do
                IFS='|' read -r alias_name existing_pack new_pack existing_cmd new_cmd <<< "$detail"
                log_conflict "$alias_name" "$existing_pack" "$new_pack" "$existing_cmd" "$new_cmd" "override"
            done
            return 0
            ;;
        3)
            # Cancel
            echo "❌ Pack activation cancelled"
            return 2
            ;;
        *)
            # Skip conflicts (default)
            for detail in "${conflict_details[@]}"; do
                IFS='|' read -r alias_name existing_pack new_pack existing_cmd new_cmd <<< "$detail"
                log_conflict "$alias_name" "$existing_pack" "$new_pack" "$existing_cmd" "$new_cmd" "skipped"
            done
            return 1
            ;;
    esac
}

# Generate static cache file for fast loading
generate_cache() {
    local show_progress="${1:-true}"

    [[ "$show_progress" == "true" ]] && echo "♻️  Regenerating alias cache..."

    # Start with header
    cat > "$CACHE_FILE" <<'EOF'
#!/usr/bin/env zsh
# Auto-generated alias cache
# Generated by smart-alias-manager
# DO NOT EDIT MANUALLY - use alias-enable/alias-refresh instead

EOF

    # Load each enabled pack and extract aliases
    while IFS= read -r pack_name; do
        local pack_file=$(find_pack "$pack_name")
        if [[ -n "$pack_file" ]]; then
            echo "# Pack: $pack_name" >> "$CACHE_FILE"

            # Extract and write aliases
            while IFS= read -r alias_json; do
                local name=$(echo "$alias_json" | jq -r '.name')
                local type=$(echo "$alias_json" | jq -r '.type')
                local command=$(echo "$alias_json" | jq -r '.command')
                local enabled=$(echo "$alias_json" | jq -r '.enabled // true')

                if [[ "$enabled" != "true" ]]; then
                    continue
                fi

                if [[ "$type" == "alias" ]]; then
                    # Escape single quotes in command
                    local escaped_cmd="${command//\'/\'\\\'\'}"
                    echo "alias ${name}='${escaped_cmd}'" >> "$CACHE_FILE"
                elif [[ "$type" == "global" ]]; then
                    local escaped_cmd="${command//\'/\'\\\'\'}"
                    echo "alias -g ${name}='${escaped_cmd}'" >> "$CACHE_FILE"
                fi
            done < <(jq -c '.aliases[]?' "$pack_file")

            echo "" >> "$CACHE_FILE"
        else
            [[ "$show_progress" == "true" ]] && echo "⚠️  Pack not found: $pack_name"
        fi
    done < <(jq -r '.enabled_packs[]' "$CONFIG_FILE" 2>/dev/null)

    # Make cache file executable
    chmod +x "$CACHE_FILE"

    [[ "$show_progress" == "true" ]] && echo "✅ Cache regenerated: $CACHE_FILE"
}

# Load pack and create aliases/functions
load_pack() {
    local pack_file="$1"
    local skip_conflicts="${2:-false}"
    local pack_name=$(jq -r '.name' "$pack_file")

    echo "📦 Loading pack: $pack_name"

    # Get list of skipped aliases from conflicts
    local skipped_aliases=()
    if [[ "$skip_conflicts" == "true" ]]; then
        while IFS= read -r alias_json; do
            local name=$(echo "$alias_json" | jq -r '.name')
            local enabled=$(echo "$alias_json" | jq -r '.enabled // true')

            if [[ "$enabled" != "true" ]]; then
                continue
            fi

            # Check if alias already exists
            if alias "$name" &>/dev/null; then
                skipped_aliases+=("$name")
            fi
        done < <(jq -c '.aliases[]?' "$pack_file")
    fi

    # Load aliases
    local alias_count=0
    local skipped_count=0
    while IFS= read -r alias_json; do
        local name=$(echo "$alias_json" | jq -r '.name')
        local type=$(echo "$alias_json" | jq -r '.type')
        local enabled=$(echo "$alias_json" | jq -r '.enabled // true')

        if [[ "$enabled" != "true" ]]; then
            continue
        fi

        # Skip if in skipped list
        if [[ "$skip_conflicts" == "true" ]] && [[ " ${skipped_aliases[@]} " =~ " ${name} " ]]; then
            ((skipped_count++))
            continue
        fi

        if [[ "$type" == "alias" ]]; then
            local command=$(echo "$alias_json" | jq -r '.command')
            alias "$name"="$command"
            record_alias_source "$name" "$pack_name"
            ((alias_count++))
        elif [[ "$type" == "global" ]]; then
            local command=$(echo "$alias_json" | jq -r '.command')
            alias -g "$name"="$command"
            record_alias_source "$name" "$pack_name"
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

    if [[ $skipped_count -gt 0 ]]; then
        echo "✅ Loaded $alias_count aliases ($skipped_count skipped due to conflicts) and $function_count functions from $pack_name"
    else
        echo "✅ Loaded $alias_count aliases and $function_count functions from $pack_name"
    fi
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

    # Regenerate cache
    generate_cache false
}

# Remove pack from enabled list
disable_pack_persistent() {
    local pack_name="$1"

    jq ".enabled_packs = (.enabled_packs - [\"$pack_name\"])" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    # Regenerate cache
    generate_cache false
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

# List all available packs
list_all_packs() {
    check_jq || return 1

    echo "📦 All Available Alias Packs:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get list of enabled packs
    local enabled_packs=($(jq -r '.enabled_packs[]' "$CONFIG_FILE" 2>/dev/null))

    local total=0

    # Enable null_glob to handle empty directories gracefully
    setopt local_options null_glob

    # Check each pack directory
    for pack_dir in "$LOCAL_PACKS_DIR" "$COMMUNITY_PACKS_DIR"; do
        local dir_name=$(basename "$pack_dir")
        local found_in_dir=0

        # Skip if directory doesn't exist
        [[ ! -d "$pack_dir" ]] && continue

        for pack_file in "$pack_dir"/*.json; do
            if [[ -f "$pack_file" ]]; then
                local name=$(jq -r '.name' "$pack_file" 2>/dev/null)
                local version=$(jq -r '.version' "$pack_file" 2>/dev/null)
                local desc=$(jq -r '.description' "$pack_file" 2>/dev/null)
                local alias_count=$(jq '[.aliases[]?] | length' "$pack_file" 2>/dev/null)

                # Check if enabled
                local pack_status="○"
                local pack_state="disabled"
                if [[ " ${enabled_packs[@]} " =~ " ${name} " ]]; then
                    pack_status="●"
                    pack_state="enabled"
                fi

                # Print pack info
                if [[ $found_in_dir -eq 0 ]]; then
                    # Capitalize first letter (zsh compatible)
                    local display_name="${(C)dir_name}"
                    echo "📁 ${display_name}:"
                    found_in_dir=1
                fi

                echo "  $pack_status $name (v$version) - $pack_state"
                echo "    $desc"
                echo "    Aliases: $alias_count"
                echo ""

                ((total++))
            fi
        done
    done

    if [[ $total -eq 0 ]]; then
        echo "  No packs found."
        echo ""
        echo "  💡 Create packs using: alias-new <command>"
        echo "  💡 Or extract from existing config: extract-aliases.py"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Total: $total packs (${#enabled_packs[@]} enabled)"
        echo ""
        echo "💡 Enable a pack:  alias-enable <pack-name>"
        echo "💡 Disable a pack: alias-enable --disable <pack-name>"
        echo "💡 View details:   alias-enable --info <pack-name>"
    fi
}

# Show conflict history
show_conflicts() {
    check_jq || return 1

    echo "⚠️  Alias Conflict History:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if conflicts log exists
    if [[ ! -f "$CONFLICTS_LOG" || ! -s "$CONFLICTS_LOG" ]]; then
        echo "  ✅ No conflicts recorded."
        echo ""
        echo "  The system automatically detects conflicts when enabling packs."
        return 0
    fi

    # Display conflicts from log file
    cat "$CONFLICTS_LOG"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 To view current aliases: alias-help"
    echo "💡 To see which pack an alias is from: alias-which <name>"
    echo "💡 Log file: $CONFLICTS_LOG"
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
            echo "  --all               List all available packs"
            echo "  --info PACK         Show pack information"
            echo "  --disable PACK      Disable a pack"
            echo "  --search QUERY      Search for packs"
            echo "  --conflicts         Show current alias conflicts"
            echo "  --reload            Reload all enabled packs"
            echo "  --help, -h          Show this help"
            echo ""
            echo "Arguments:"
            echo "  PACK                Pack name or URL to enable"
            echo ""
            echo "Examples:"
            echo "  alias-enable git-essentials          # Enable local pack"
            echo "  alias-enable https://example.com/pack.json  # Enable from URL"
            echo "  alias-enable --all                   # List all available packs"
            echo "  alias-enable --info docker-essentials"
            echo "  alias-enable --disable git-essentials"
            echo "  alias-enable --conflicts             # Show conflict history"
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
        --all)
            check_jq || return 1
            list_all_packs
            return 0
            ;;
        --conflicts)
            check_jq || return 1
            show_conflicts
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

            # Check for conflicts
            check_alias_conflicts "$pack_file"
            local conflict_result=$?

            if [[ $conflict_result -eq 2 ]]; then
                # User cancelled
                return 1
            fi

            # Load pack (skip conflicts if user chose option 1)
            local skip_conflicts="false"
            [[ $conflict_result -eq 1 ]] && skip_conflicts="true"
            load_pack "$pack_file" "$skip_conflicts"

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
# Fast version: just sources the pre-generated cache file
alias-autoload() {
    # Check if cache exists, if not generate it
    if [[ ! -f "$CACHE_FILE" ]]; then
        # Silently check if jq is available
        if ! command_exists jq; then
            return 1
        fi
        generate_cache false
    fi

    # Simply source the pre-generated cache file - INSTANT!
    source "$CACHE_FILE" 2>/dev/null
}

# Refresh alias cache (regenerate from packs)
alias-refresh() {
    check_jq || return 1

    echo "🔄 Refreshing alias system..."
    echo ""

    # Regenerate cache from enabled packs
    generate_cache true

    # Reload in current shell
    source "$CACHE_FILE" 2>/dev/null

    echo ""
    echo "✅ Refresh complete! Aliases reloaded."
}

# Shortcut command for listing all packs
alias-packs() {
    alias-enable --all
}

# Export functions
alias ae='alias-enable'  # Short alias
alias ap='alias-packs'   # Short alias for pack listing
alias ar='alias-refresh' # Short alias for refreshing cache
