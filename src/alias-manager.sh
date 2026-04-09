#!/bin/bash
# Smart Alias Manager - Core Functions
# A powerful shell alias management system with AI-enhanced suggestions
# Version: 1.0.0
# License: MIT

# ============================================
# ALIAS HELP SYSTEM
# ============================================
# Type 'alias-help' to list all aliases with descriptions
# Type 'alias-help <name>' to see what a specific alias does
# Type 'alias-which <name>' to see the full command expansion
# Type 'alias-find <term>' to search for aliases
# Type 'alias-new <command>' to create new aliases interactively

# ============================================
# HELPER FUNCTIONS
# ============================================

# Validate alias name - returns 0 if valid, 1 if invalid
validate_alias_name() {
    local name="$1"

    # Check for empty string
    [[ -z "$name" ]] && return 1

    # Check for . and ..
    [[ "$name" == "." || "$name" == ".." ]] && return 1

    # Check if starts with - (looks like a flag)
    [[ "$name" =~ ^- ]] && return 1

    # Check if starts with a digit (invalid in some shells)
    [[ "$name" =~ ^[0-9] ]] && return 1

    # Check for shell special characters that break aliases
    # Use character class matching compatible with both bash and zsh
    if [[ "$name" == *[\$\|\&\;\<\>\(\)\{\}\[\]\'\"\`\\\ ]* ]]; then
        return 1
    fi

    # Check for shell keywords
    local keywords=("if" "then" "else" "elif" "fi" "case" "esac" "for" "while" "until" "do" "done" "function" "select" "time" "in")
    for keyword in "${keywords[@]}"; do
        [[ "$name" == "$keyword" ]] && return 1
    done

    return 0
}

# Extract binary name from path (e.g., "./bin/foo" -> "foo", "/usr/bin/bar" -> "bar")
extract_binary_name() {
    local path="$1"

    # Remove leading path components
    local basename="${path##*/}"

    # Remove file extensions if present
    basename="${basename%.*}"

    echo "$basename"
}

# Extract the main command from a complex command line (handles pipes, redirects)
extract_main_command() {
    local cmd="$1"

    # Remove everything after pipes, redirects, and other operators using parameter expansion
    # Find first occurrence of special characters
    cmd="${cmd%%|*}"   # Remove pipe and everything after
    cmd="${cmd%%\&*}"  # Remove ampersand and everything after
    cmd="${cmd%%;*}"   # Remove semicolon and everything after
    cmd="${cmd%%>*}"   # Remove redirect and everything after
    cmd="${cmd%%<*}"   # Remove redirect and everything after

    # Trim leading/trailing whitespace using parameter expansion
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"  # Remove leading whitespace
    cmd="${cmd%"${cmd##*[![:space:]]}"}"  # Remove trailing whitespace

    echo "$cmd"
}

# Generate smart alias suggestions for a command
generate_suggestions() {
    local cmd="$1"
    local suggestions=()

    # Extract main command (strip pipes, redirects)
    cmd=$(extract_main_command "$cmd")

    # Word splitting
    if [[ -n "$ZSH_VERSION" ]]; then
        setopt SH_WORD_SPLIT
        local words=($cmd)
        unsetopt SH_WORD_SPLIT
    else
        local words=($cmd)
    fi

    local first_word="${words[1]}"

    # Check if it's a path-based command
    if [[ "$first_word" =~ ^[.~/] || "$first_word" =~ / ]]; then
        # Extract binary name from path
        local binary=$(extract_binary_name "$first_word")

        if [[ -n "$binary" ]]; then
            # Generate suggestions based on binary name
            suggestions+=("${binary:0:2}")
            suggestions+=("${binary:0:3}")
            suggestions+=("${binary:0:4}")

            # Also try initials if multi-word binary name (e.g., status-reporter -> sr)
            if [[ "$binary" =~ - ]]; then
                local initials=""
                local parts
                if [[ -n "$ZSH_VERSION" ]]; then
                    setopt SH_WORD_SPLIT
                    parts=(${binary//-/ })
                    unsetopt SH_WORD_SPLIT
                else
                    IFS='-' read -ra parts <<< "$binary"
                fi
                for part in "${parts[@]}"; do
                    initials+="${part:0:1}"
                done
                suggestions+=("$initials")
            fi
        fi
    else
        # Command-specific patterns
        case "$first_word" in
            git)
                local git_cmd="${words[2]}"
                suggestions+=("g${git_cmd:0:1}")
                suggestions+=("g${git_cmd:0:2}")
                if [[ "${#words[@]}" -gt 2 ]]; then
                    suggestions+=("g${git_cmd:0:1}${words[3]:0:1}")
                fi
                ;;
            docker)
                if [[ "${words[2]}" == "compose" ]]; then
                    suggestions+=("dc${words[3]:0:1}")
                    suggestions+=("dc${words[3]:0:2}")
                else
                    suggestions+=("d${words[2]:0:1}")
                    suggestions+=("d${words[2]:0:2}")
                fi
                ;;
            kubectl|k)
                suggestions+=("k${words[2]:0:1}")
                suggestions+=("k${words[2]:0:2}")
                if [[ "${#words[@]}" -gt 2 ]]; then
                    suggestions+=("k${words[2]:0:1}${words[3]:0:1}")
                fi
                ;;
            npm)
                suggestions+=("n${words[2]:0:1}")
                suggestions+=("n${words[2]:0:2}")
                ;;
            yarn)
                suggestions+=("y${words[2]:0:1}")
                suggestions+=("y${words[2]:0:2}")
                ;;
            mvn|maven)
                suggestions+=("m${words[2]:0:1}")
                suggestions+=("m${words[2]:0:2}")
                ;;
            aws)
                suggestions+=("a${words[2]:0:1}")
                suggestions+=("a${words[2]:0:2}")
                if [[ "${#words[@]}" -gt 2 ]]; then
                    suggestions+=("a${words[2]:0:1}${words[3]:0:1}")
                fi
                ;;
            *)
                # Generic suggestions using initials
                local initials=""
                for word in "${words[@]:1:3}"; do
                    initials+="${word:0:1}"
                done
                suggestions+=("$initials")
                suggestions+=("${first_word:0:2}")
                suggestions+=("${first_word:0:3}")
                ;;
        esac
    fi

    # Filter out invalid suggestions
    local valid_suggestions=()
    for suggestion in "${suggestions[@]}"; do
        if validate_alias_name "$suggestion"; then
            valid_suggestions+=("$suggestion")
        fi
    done

    # Return unique suggestions
    printf '%s\n' "${valid_suggestions[@]}" | sort -u
}

alias-help() {
    if [[ -z "$1" ]]; then
        echo "📚 ALIAS HELP - Available Commands"
        echo "=================================="
        echo ""
        echo "🔧 MANAGEMENT COMMANDS:"
        echo "  ah  (alias-help)    - Show this help or get specific alias info"
        echo "  aw  (alias-which)   - Show command expansion and file location"
        echo "  af  (alias-find)    - Search for aliases by keyword"
        echo "  an  (alias-new)     - Create new alias interactively"
        echo "  au  (alias-update)  - Update an existing alias"
        echo "  als (alias-aliases) - List all aliases with file paths"
        echo "  aa  (alias-analyze) - Analyze command history for optimization"
        echo "  ap  (alias-packs)   - List all available packs"
        echo ""
        echo "🤖 AGENT MODE (Smart Learning):"
        echo "  aae  (alias-agent-enable)  - Enable intelligent alias suggestions"
        echo "  aad  (alias-agent-disable) - Disable agent mode"
        echo "  aas  (alias-agent-status)  - Show agent status and quick stats"
        echo "  aast (alias-agent-stats)   - Show detailed statistics"
        echo "  aac  (alias-agent-config)  - Edit agent configuration"
        echo "  aacl (alias-agent-clear)   - Clear learned patterns"
        echo ""
        echo "💡 TIPS:"
        echo "  • Use 'als' to list all aliases with their locations"
        echo "  • Use 'af <keyword>' to search for specific aliases"
        echo "  • Use 'aa' to analyze your command usage and find optimizations"
        echo "  • Use 'ap' to see all available alias packs"
        echo ""
        echo "📖 USAGE EXAMPLES:"
        echo "  ah gs              # Show info about 'gs' alias"
        echo "  af docker          # Find all Docker-related aliases"
        echo "  an 'git status'    # Create new alias interactively"
        echo "  au gs              # Update existing 'gs' alias"
    else
        # Show specific alias info
        local alias_def=$(alias "$1" 2>/dev/null)
        if [[ -n "$alias_def" ]]; then
            echo "📌 Alias: $1"
            echo "Command: ${alias_def#*=}"

            # Show pack source if available
            local metadata_file="${HOME}/.config/smart-aliases/metadata.json"
            if [[ -f "$metadata_file" ]] && command -v jq &>/dev/null; then
                local source=$(jq -r ".alias_sources[\"$1\"] // \"custom\"" "$metadata_file" 2>/dev/null)
                if [[ "$source" != "custom" && -n "$source" ]]; then
                    echo "Source:  📦 $source"
                else
                    echo "Source:  ✏️  Custom"
                fi
            fi

            # Try to provide intelligent description based on command
            local cmd="${alias_def#*=}"
            cmd="${cmd//\'/}"  # Remove quotes
            case "$cmd" in
                git*) echo "Category: Git version control" ;;
                docker*) echo "Category: Docker container management" ;;
                npm*|yarn*) echo "Category: Node.js package management" ;;
                mvn*) echo "Category: Maven build tool" ;;
                kubectl*|k8s*) echo "Category: Kubernetes orchestration" ;;
                aws*) echo "Category: AWS cloud services" ;;
                *) echo "Category: System/Custom command" ;;
            esac
        else
            echo "❌ Alias '$1' not found"
            echo "💡 Use 'alias-help' to see all available aliases"
            echo "💡 Use 'alias-find $1' to search for similar aliases"
        fi
    fi
}

alias-which() {
    if [[ -z "$1" ]]; then
        echo "Usage: alias-which <alias-name>"
        echo "Shows the full command expansion and location for an alias"
        echo ""
        echo "Example: alias-which gs"
        echo "Output: Command and file location"
    else
        local alias_def=$(alias "$1" 2>/dev/null)
        if [[ -n "$alias_def" ]]; then
            echo "📌 Alias: $1"
            echo "Command: ${alias_def#*=}"

            # Find the pack file containing this alias
            local metadata_file="${HOME}/.config/smart-aliases/metadata.json"
            local pack_name=""
            local pack_file=""

            if [[ -f "$metadata_file" ]] && command -v jq &>/dev/null; then
                pack_name=$(jq -r ".alias_sources[\"$1\"] // \"\"" "$metadata_file" 2>/dev/null)
            fi

            if [[ -n "$pack_name" ]]; then
                # Check local and community packs
                for dir in "${HOME}/.config/smart-aliases/packs/local" "${HOME}/.config/smart-aliases/packs/community"; do
                    if [[ -f "$dir/${pack_name}.json" ]]; then
                        pack_file="$dir/${pack_name}.json"
                        break
                    fi
                done

                if [[ -n "$pack_file" ]]; then
                    echo "Pack:    📦 $pack_name"
                    echo "File:    📁 $pack_file"

                    # Show description if available
                    if command -v jq &>/dev/null; then
                        local desc=$(jq -r ".aliases[] | select(.name == \"$1\") | .description // \"\"" "$pack_file" 2>/dev/null)
                        if [[ -n "$desc" && "$desc" != "$1 command" ]]; then
                            echo "Info:    $desc"
                        fi
                    fi
                else
                    echo "Pack:    📦 $pack_name"
                    echo "File:    ⚠️  Pack file not found"
                fi
            else
                echo "Source:  ✏️  Custom (session only)"
                echo "File:    Not saved to pack"
            fi
        else
            echo "❌ Alias '$1' not found"
            # Try to suggest similar aliases
            local similar=$(alias | grep "$1" | head -3)
            if [[ -n "$similar" ]]; then
                echo ""
                echo "Did you mean one of these?"
                echo "$similar" | while read line; do
                    echo "  ${line%%=*}"
                done
            fi
        fi
    fi
}

alias-find() {
    if [[ -z "$1" ]]; then
        echo "Usage: alias-find <search-term>"
        echo "Searches for aliases containing the specified term"
        echo ""
        echo "Examples:"
        echo "  alias-find git     # Find git-related aliases"
        echo "  alias-find status  # Find aliases with 'status' in command"
        echo "  alias-find push    # Find push-related aliases"
        return
    fi
    
    local search_term="$1"
    local found=0
    echo "🔍 Searching for aliases containing '$search_term'..."
    echo ""
    
    # Search through all aliases
    alias | while IFS= read -r line; do
        local alias_name="${line%%=*}"
        local alias_cmd="${line#*=}"
        
        # Search in both alias name and command
        if [[ "$alias_name" == *"$search_term"* ]] || [[ "$alias_cmd" == *"$search_term"* ]]; then
            echo "  📌 $alias_name = $alias_cmd"
            found=1
        fi
    done | head -20  # Limit results
    
    if [[ $found -eq 0 ]]; then
        echo "❌ No aliases found containing '$search_term'"
        echo "💡 Try 'alias-new' to create a new alias"
        echo "💡 Use 'alias-analyze' to discover optimization opportunities"
    fi
}

alias-new() {
    if [[ -z "$1" ]]; then
        echo "Usage: alias-new <command> [description]"
        echo "Creates a new alias with smart suggestions and saves to JSON pack"
        echo ""
        echo "Examples:"
        echo "  alias-new 'git status --short' 'Quick git status'"
        echo "  alias-new 'docker ps -a' 'List all containers'"
        echo "  alias-new 'kubectl get pods --all-namespaces'"
        return
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "❌ Error: jq is required for alias pack management"
        echo "Install: sudo apt-get install jq (or brew install jq on macOS)"
        return 1
    fi

    local command="$1"
    local description="${2:-}"
    local packs_dir="${HOME}/.config/smart-aliases/packs/local"

    # Ensure packs directory exists
    mkdir -p "$packs_dir"

    echo "📝 Creating alias for: $command"
    echo ""

    # Extract main command for category determination
    local main_cmd=$(extract_main_command "$command")

    # Determine category based on command
    local category="misc"
    if [[ -n "$ZSH_VERSION" ]]; then
        setopt SH_WORD_SPLIT
        local words=($main_cmd)
        unsetopt SH_WORD_SPLIT
    else
        local words=($main_cmd)
    fi
    local first_word="${words[1]}"

    # Determine category (handle paths too)
    if [[ "$first_word" =~ ^[.~/] || "$first_word" =~ / ]]; then
        # Path-based command - use extracted binary name for category
        local binary=$(extract_binary_name "$first_word")
        # Try to match binary name to known categories
        case "$binary" in
            git*) category="git" ;;
            docker*) category="docker" ;;
            kubectl*|k8s*) category="misc" ;;
            npm*|node*) category="npm-yarn" ;;
            yarn*) category="npm-yarn" ;;
            mvn*|maven*) category="maven" ;;
            *) category="misc" ;;
        esac
    else
        case "$first_word" in
            git) category="git" ;;
            docker) category="docker" ;;
            kubectl|k) category="misc" ;;
            npm) category="npm-yarn" ;;
            yarn) category="npm-yarn" ;;
            mvn|maven) category="maven" ;;
            aws) category="misc" ;;
        esac
    fi

    # Generate suggestions using helper function
    echo "💡 Suggested aliases (based on command pattern):"
    local available_suggestions=()
    while IFS= read -r suggestion; do
        local existing=$(alias "$suggestion" 2>/dev/null)
        if [[ -z "$existing" ]]; then
            echo "  ✅ $suggestion (available)"
            available_suggestions+=("$suggestion")
        else
            echo "  ❌ $suggestion (taken: ${existing#*=})"
        fi
    done < <(generate_suggestions "$command")

    if [[ ${#available_suggestions[@]} -eq 0 ]]; then
        echo "  ⚠️  No simple suggestions available (consider a custom name)"
    fi

    echo "  📝 Or enter a custom alias name"
    echo ""

    # Get user choice with validation
    local chosen_alias=""
    while true; do
        echo -n "Choose alias name (or press Enter to skip): "
        read chosen_alias

        if [[ -z "$chosen_alias" ]]; then
            echo "❌ Alias creation cancelled"
            return
        fi

        # Validate alias name
        if ! validate_alias_name "$chosen_alias"; then
            echo "❌ Invalid alias name: '$chosen_alias'"
            echo "   Alias names cannot:"
            echo "   - Be empty, '.', or '..'"
            echo "   - Start with '-' or a digit"
            echo "   - Contain special characters (\$|&;<>(){}[]'\"\`\\ or spaces)"
            echo "   - Be shell keywords (if, then, else, etc.)"
            echo ""
            continue
        fi

        # Check if alias already exists
        local existing=$(alias "$chosen_alias" 2>/dev/null)
        if [[ -n "$existing" ]]; then
            echo "⚠️  Alias '$chosen_alias' already exists: ${existing#*=}"
            echo -n "Overwrite? (y/N): "
            read overwrite
            if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
                echo ""
                continue
            fi
        fi

        # Valid name chosen
        break
    done

    # Get description if not provided
    if [[ -z "$description" ]]; then
        echo -n "Description (optional): "
        read description
        [[ -z "$description" ]] && description="$chosen_alias command"
    fi

    # Determine pack file
    local pack_file="$packs_dir/extracted-${category}.json"

    # Create pack if it doesn't exist, is empty, or is missing the name field
    local needs_creation=false
    if [[ ! -f "$pack_file" ]] || [[ ! -s "$pack_file" ]]; then
        needs_creation=true
    elif [[ -z "$(jq -r '.name // empty' "$pack_file" 2>/dev/null)" ]]; then
        needs_creation=true
    fi

    if [[ "$needs_creation" == "true" ]]; then
        echo "📦 Creating new pack: extracted-${category}"
        # Capitalize first letter (compatible with both bash and zsh)
        local category_cap="${category:0:1}" category_rest="${category:1}"
        if [[ -n "$ZSH_VERSION" ]]; then
            category_cap="${(U)category_cap}"
        else
            category_cap="${category_cap^}"
        fi
        local category_title="${category_cap}${category_rest}"

        cat > "$pack_file" <<EOF
{
  "name": "extracted-${category}",
  "version": "1.0.0",
  "author": "User-created aliases",
  "description": "${category_title} aliases",
  "license": "MIT",
  "tags": ["${category}", "extracted", "personal"],
  "requires": {
    "zsh": ">=5.0"
  },
  "aliases": []
}
EOF
    fi

    # Escape command for JSON
    local escaped_command=$(echo "$command" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

    # Check if alias already exists in pack
    local existing_in_pack=$(jq -r ".aliases[] | select(.name == \"$chosen_alias\") | .name" "$pack_file" 2>/dev/null)

    if [[ -n "$existing_in_pack" ]]; then
        # Update existing alias
        jq ".aliases = [.aliases[] | if .name == \"$chosen_alias\" then .command = \"$escaped_command\" | .description = \"$description\" else . end]" "$pack_file" > "${pack_file}.tmp" && mv "${pack_file}.tmp" "$pack_file"
        echo "♻️  Updated existing alias in pack"
    else
        # Add new alias to pack
        jq ".aliases += [{\"name\": \"$chosen_alias\", \"type\": \"alias\", \"command\": \"$escaped_command\", \"description\": \"$description\", \"category\": \"$category\", \"enabled\": true}]" "$pack_file" > "${pack_file}.tmp" && mv "${pack_file}.tmp" "$pack_file"
        echo "➕ Added new alias to pack"
    fi

    # Validate JSON
    if ! jq empty "$pack_file" 2>/dev/null; then
        echo "❌ Error: Invalid JSON generated"
        return 1
    fi

    # Set the alias in current session
    alias "$chosen_alias"="$command"

    # Regenerate cache if pack is enabled (so it's available in new terminals)
    local config_file="${HOME}/.config/smart-aliases/config.json"
    if [[ -f "$config_file" ]]; then
        local pack_enabled=$(jq -r ".enabled_packs[]? | select(. == \"extracted-${category}\")" "$config_file" 2>/dev/null)
        if [[ -n "$pack_enabled" ]]; then
            # Silently regenerate cache
            if command -v generate_cache &>/dev/null; then
                generate_cache false
            fi
        fi
    fi

    echo "✅ Alias created successfully!"
    echo ""
    echo "📌 New alias: $chosen_alias = '$command'"
    echo "📦 Saved to: $pack_file"
    echo ""
    echo "💡 The alias is now active in your current session"
    if [[ -z "$pack_enabled" ]]; then
        echo "💡 To persist across sessions, enable the pack:"
        echo "   alias-enable extracted-${category}"
    else
        echo "💡 To use in new terminals, source your shell config:"
        echo "   source ~/.zshrc"
    fi
}

alias-update() {
    if [[ -z "$1" ]]; then
        echo "Usage: alias-update <alias-name>"
        echo "Updates an existing alias's command, description, or legacy status"
        echo ""
        echo "Examples:"
        echo "  alias-update gs        # Update the 'gs' alias"
        echo "  alias-update xc        # Update and optionally mark as legacy"
        return
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "❌ Error: jq is required for alias pack management"
        echo "Install: sudo apt-get install jq (or brew install jq on macOS)"
        return 1
    fi

    local alias_name="$1"
    local packs_dir="${HOME}/.config/smart-aliases/packs/local"

    # Check if alias exists
    local alias_def=$(alias "$alias_name" 2>/dev/null)
    if [[ -z "$alias_def" ]]; then
        echo "❌ Alias '$alias_name' not found"
        echo "💡 Use 'alias-help' to see all available aliases"
        echo "💡 Use 'alias-new' to create a new alias"
        return 1
    fi

    # Find the pack file containing this alias
    local metadata_file="${HOME}/.config/smart-aliases/metadata.json"
    local pack_name=""
    local pack_file=""

    if [[ -f "$metadata_file" ]] && command -v jq &>/dev/null; then
        pack_name=$(jq -r ".alias_sources[\"$alias_name\"] // \"\"" "$metadata_file" 2>/dev/null)
    fi

    if [[ -n "$pack_name" ]]; then
        # Check local packs
        for dir in "${HOME}/.config/smart-aliases/packs/local" "${HOME}/.config/smart-aliases/packs/community"; do
            if [[ -f "$dir/${pack_name}.json" ]]; then
                pack_file="$dir/${pack_name}.json"
                break
            fi
        done
    fi

    if [[ -z "$pack_file" ]]; then
        echo "❌ Could not find pack file for alias '$alias_name'"
        echo "💡 This might be a session-only alias or from a non-standard location"
        return 1
    fi

    # Get current values
    local current_cmd=$(echo "${alias_def#*=}" | sed "s/^'//" | sed "s/'$//")
    local current_desc=$(jq -r ".aliases[] | select(.name == \"$alias_name\") | .description // \"\"" "$pack_file" 2>/dev/null)

    echo "📝 Updating alias: $alias_name"
    echo "📁 Pack file: $pack_file"
    echo ""
    echo "Current command:     $current_cmd"
    echo "Current description: $current_desc"
    echo ""

    # Get current legacy status
    local current_legacy=$(jq -r ".aliases[] | select(.name == \"$alias_name\") | .legacy // false" "$pack_file" 2>/dev/null)

    # Get new command
    echo -n "New command (press Enter to keep current): "
    read new_cmd
    [[ -z "$new_cmd" ]] && new_cmd="$current_cmd"

    # Get new description
    echo -n "New description (press Enter to keep current): "
    read new_desc
    [[ -z "$new_desc" ]] && new_desc="$current_desc"

    # Ask about legacy status
    echo ""
    if [[ "$current_legacy" == "true" ]]; then
        echo "⚠️  This alias is currently marked as LEGACY (for removal)"
        echo -n "Remove legacy flag? (y/N): "
    else
        echo -n "Mark as LEGACY (for future removal)? (y/N): "
    fi
    read mark_legacy

    local new_legacy="false"
    if [[ "$current_legacy" == "true" ]]; then
        # Currently legacy, asking to unmark
        if [[ "$mark_legacy" == "y" || "$mark_legacy" == "Y" ]]; then
            new_legacy="false"
        else
            new_legacy="true"
        fi
    else
        # Currently not legacy, asking to mark
        if [[ "$mark_legacy" == "y" || "$mark_legacy" == "Y" ]]; then
            new_legacy="true"
        fi
    fi

    # Escape for JSON
    local escaped_cmd=$(echo "$new_cmd" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    local escaped_desc=$(echo "$new_desc" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

    # Update the alias in the pack file
    jq ".aliases = [.aliases[] | if .name == \"$alias_name\" then .command = \"$escaped_cmd\" | .description = \"$escaped_desc\" | .legacy = $new_legacy else . end]" "$pack_file" > "${pack_file}.tmp" && mv "${pack_file}.tmp" "$pack_file"

    # Validate JSON
    if ! jq empty "$pack_file" 2>/dev/null; then
        echo "❌ Error: Invalid JSON generated"
        return 1
    fi

    # Update alias in current session
    alias "$alias_name"="$new_cmd"

    # Regenerate cache if pack is enabled
    local config_file="${HOME}/.config/smart-aliases/config.json"
    if [[ -f "$config_file" ]]; then
        local pack_enabled=$(jq -r ".enabled_packs[]? | select(. == \"$pack_name\")" "$config_file" 2>/dev/null)
        if [[ -n "$pack_enabled" ]]; then
            if command -v generate_cache &>/dev/null; then
                generate_cache false
            fi
        fi
    fi

    echo ""
    echo "✅ Alias updated successfully!"
    echo ""
    echo "📌 Updated: $alias_name = '$new_cmd'"
    if [[ "$new_legacy" == "true" ]]; then
        echo "🗑️  Status: LEGACY (marked for removal)"
    fi
    echo "📦 Saved to: $pack_file"
    echo ""
    echo "💡 The alias is now active in your current session"
    if [[ "$new_legacy" == "true" ]]; then
        echo "💡 Run 'alias-analyze' to see all legacy aliases"
    else
        echo "💡 Changes will be available in new terminals after sourcing shell config"
    fi
}

alias-aliases() {
    echo "📚 ALL ALIASES WITH LOCATIONS"
    echo "=================================="
    echo ""

    # Check if metadata file exists
    local metadata_file="${HOME}/.config/smart-aliases/metadata.json"
    local has_metadata=false
    if [[ -f "$metadata_file" ]] && command -v jq &>/dev/null; then
        has_metadata=true
    fi

    # Group aliases by pack
    declare -A pack_aliases
    declare -A custom_aliases_list
    local total_aliases=0

    # Get all current aliases
    while IFS= read -r line; do
        local alias_name="${line%%=*}"
        local alias_cmd="${line#*=}"

        # Skip management aliases
        [[ "$alias_name" =~ ^(ah|aw|af|an|aa|ae|ap|au|als)$ ]] && continue

        ((total_aliases++))

        if [[ "$has_metadata" == "true" ]]; then
            local source=$(jq -r ".alias_sources[\"$alias_name\"] // \"custom\"" "$metadata_file" 2>/dev/null)
            if [[ "$source" == "custom" || -z "$source" ]]; then
                custom_aliases_list[$alias_name]="$alias_cmd"
            else
                if [[ -z "${pack_aliases[$source]}" ]]; then
                    pack_aliases[$source]="$alias_name=$alias_cmd"
                else
                    pack_aliases[$source]="${pack_aliases[$source]}\n$alias_name=$alias_cmd"
                fi
            fi
        else
            custom_aliases_list[$alias_name]="$alias_cmd"
        fi
    done < <(alias 2>/dev/null)

    echo "📊 TOTAL: ${total_aliases} aliases"
    echo ""

    # Show pack-based aliases with file paths
    if [[ ${#pack_aliases[@]} -gt 0 ]]; then
        for pack in "${(@k)pack_aliases}"; do
            # Find pack file
            local pack_file=""
            for dir in "${HOME}/.config/smart-aliases/packs/local" "${HOME}/.config/smart-aliases/packs/community"; do
                if [[ -f "$dir/${pack}.json" ]]; then
                    pack_file="$dir/${pack}.json"
                    break
                fi
            done

            # Get all alias names from the pack file
            local alias_names=()
            if [[ -n "$pack_file" ]] && command -v jq &>/dev/null; then
                while IFS= read -r name; do
                    alias_names+=("$name")
                done < <(jq -r '.aliases[].name' "$pack_file" 2>/dev/null)
            fi

            local count=${#alias_names[@]}
            echo "📦 Pack: $pack ($count aliases)"
            echo "📁 File: $pack_file"
            echo ""

            # Process each alias
            for name in "${alias_names[@]}"; do
                # Get description from pack file
                local desc=""
                if [[ -n "$pack_file" ]] && command -v jq &>/dev/null; then
                    desc=$(jq -r ".aliases[] | select(.name == \"$name\") | .description // \"\"" "$pack_file" 2>/dev/null)
                fi

                # Use command if description is generic or empty
                if [[ -z "$desc" ]] || [[ "$desc" == "$name command" ]] || [[ "$desc" == "$name"* && ${#desc} -lt 20 ]]; then
                    local cmd=$(alias "$name" 2>/dev/null | sed "s/^$name=//")
                    cmd="${cmd//\'/}"
                    cmd="${cmd//\"/}"
                    cmd="${cmd//$'\n'/ }"
                    cmd="${cmd//  / }"
                    cmd="${cmd## }"
                    cmd="${cmd#\$}"
                    desc="$cmd"
                fi

                # Truncate very long descriptions/commands
                if [[ ${#desc} -gt 60 ]]; then
                    desc="${desc:0:57}..."
                fi

                printf "  %-15s → %s\n" "$name" "$desc"
            done
            echo ""
        done
    fi

    # Show custom aliases
    if [[ ${#custom_aliases_list[@]} -gt 0 ]]; then
        local custom_count=${#custom_aliases_list[@]}
        echo "✏️  Custom aliases ($custom_count) - Session only"
        echo "📁 File: Not saved to pack"
        echo ""
        for alias_name in "${(@k)custom_aliases_list}"; do
            local cmd="${custom_aliases_list[$alias_name]}"

            # Clean up command
            cmd="${cmd//\'/}"
            cmd="${cmd//\"/}"
            cmd="${cmd//$'\n'/ }"
            cmd="${cmd//  / }"

            # Truncate long commands
            if [[ ${#cmd} -gt 60 ]]; then
                cmd="${cmd:0:57}..."
            fi

            printf "  %-15s → %s\n" "$alias_name" "$cmd"
        done
        echo ""
    fi

    echo "💡 TIP: Use 'alias-help <name>' for specific alias info"
    echo "💡 TIP: Use 'aw <name>' to see full command and file location"
    echo "💡 TIP: Use 'alias-update <name>' to modify an alias"
}

alias-analyze() {
    echo "📊 Analyzing Command History & Alias Usage..."
    echo "=============================================="
    echo ""

    # Get full command history
    local history_file="${TMPDIR:-/tmp}/alias-analyze-history-$$.txt"
    if [[ -n "$HISTFILE" ]]; then
        history | awk '{$1=""; print $0}' | sed 's/^[ \t]*//' > "$history_file"
    else
        fc -l 1 2>/dev/null | awk '{$1=""; print $0}' | sed 's/^[ \t]*//' > "$history_file"
    fi

    # Analyze command history for patterns
    echo "🔝 Top 20 Most Used Commands:"
    cat "$history_file" | sort | uniq -c | sort -rn | head -20 | while read count cmd; do
        # First check if the entire command itself is an alias
        local first_word=$(echo "$cmd" | awk '{print $1}')
        local is_alias=$(alias "$first_word" 2>/dev/null)

        if [[ -n "$is_alias" ]]; then
            echo "  $count× $cmd ✅ (aliased)"
        else
            echo "  $count× $cmd ⚠️ (no alias)"
        fi
    done

    echo ""
    echo "💡 OPTIMIZATION SUGGESTIONS:"

    # Find long commands without aliases
    local long_commands=$(cat "$history_file" | awk 'length > 20' | sort | uniq -c | sort -rn | head -5)
    if [[ -n "$long_commands" ]]; then
        echo ""
        echo "📝 Long commands that could benefit from aliases:"
        echo "$long_commands" | while read count cmd; do
            if [[ $count -gt 2 ]]; then
                # Check if command already has an alias
                local first_word=$(echo "$cmd" | awk '{print $1}')
                local existing_alias=$(alias "$first_word" 2>/dev/null)

                if [[ -n "$existing_alias" ]]; then
                    # Skip if already aliased
                    continue
                fi

                echo "  $count× $cmd"

                # Generate suggestions using helper function
                local available_suggestions=()
                while IFS= read -r suggestion; do
                    local existing=$(alias "$suggestion" 2>/dev/null)
                    if [[ -z "$existing" ]]; then
                        available_suggestions+=("$suggestion")
                    fi
                done < <(generate_suggestions "$cmd")

                # Display suggestions
                if [[ ${#available_suggestions[@]} -gt 0 ]]; then
                    echo "     → Suggested aliases: ${available_suggestions[*]}"
                else
                    echo "     → No simple suggestions available (common aliases taken)"
                fi
            fi
        done
    fi

    # Check for unused aliases and command shadowing
    echo ""
    echo "⚠️  UNUSED ALIASES (defined but not found in recent history):"
    local packs_dir="${HOME}/.config/smart-aliases/packs/local"
    local metadata_file="${HOME}/.config/smart-aliases/metadata.json"

    # Pre-extract first words from history for faster lookup
    local used_cmds_file="${TMPDIR:-/tmp}/alias-analyze-used-$$.txt"
    awk '{print $1}' "$history_file" | sort -u > "$used_cmds_file"

    local unused_count=0
    local shadow_count=0
    local shown_unused=0
    local max_show=15
    local shadow_file="${TMPDIR:-/tmp}/alias-analyze-shadow-$$.txt"
    > "$shadow_file"

    # Get all aliases into a temp file first (avoids process substitution issues)
    local aliases_file="${TMPDIR:-/tmp}/alias-analyze-aliases-$$.txt"
    alias > "$aliases_file" 2>&1

    # Verify file was created
    if [[ ! -s "$aliases_file" ]]; then
        echo "  ⚠️  Could not retrieve aliases"
        rm -f "$used_cmds_file" "$aliases_file"
        return 1
    fi

    # Load entire metadata into memory once (much faster than repeated jq calls)
    local metadata_cache="${TMPDIR:-/tmp}/alias-analyze-metadata-$$.txt"
    if [[ -f "$metadata_file" ]] && command -v jq &>/dev/null; then
        jq -r '.alias_sources | to_entries[] | "\(.key)|\(.value)"' "$metadata_file" 2>/dev/null > "$metadata_cache" || touch "$metadata_cache"
    else
        touch "$metadata_cache"
    fi

    # Process each alias - read entire file into array first to avoid file descriptor issues
    local -a alias_lines
    while IFS= read -r line; do
        alias_lines+=("$line")
    done < "$aliases_file"

    # Now process the array
    local line
    for line in "${alias_lines[@]}"; do
        # Remove "alias " prefix if present (bash format)
        line="${line#alias }"
        local alias_name="${line%%=*}"
        local alias_def="${line#*=}"

        # Skip management aliases
        [[ "$alias_name" =~ ^(ah|aw|af|an|au|als|aa|ap|ae|ar)$ ]] && continue

        # Check if alias is used in history (fast grep)
        if ! grep -qx "$alias_name" "$used_cmds_file" 2>/dev/null; then
            ((unused_count++))

            # Only show first N unused aliases
            if [[ $shown_unused -lt $max_show ]]; then
                # Find pack from cache (fast grep instead of jq call per alias)
                local pack_name=""
                if [[ -s "$metadata_cache" ]]; then
                    pack_name=$(grep "^${alias_name}|" "$metadata_cache" 2>/dev/null | head -1 | cut -d'|' -f2)
                fi
                [[ -z "$pack_name" ]] && pack_name="unknown"

                # Get the actual command from alias definition
                local actual_cmd="${alias_def#\'}"
                actual_cmd="${actual_cmd%\'}"

                # Truncate long commands
                if [[ ${#actual_cmd} -gt 60 ]]; then
                    actual_cmd="${actual_cmd:0:57}..."
                fi

                echo "  📌 $alias_name → $actual_cmd"
                if [[ -n "$pack_name" && "$pack_name" != "unknown" ]]; then
                    echo "     Pack: $pack_name"
                fi
                ((shown_unused++))
            fi
        fi

        # Check if alias shadows a system command (only check first 50 aliases to avoid slowness)
        if [[ $shadow_count -lt 50 ]]; then
            local sys_path=""
            if [[ -n "$ZSH_VERSION" ]]; then
                sys_path=$(whence -p "$alias_name" 2>/dev/null || true)
            else
                sys_path=$(type -P "$alias_name" 2>/dev/null || true)
            fi

            if [[ -n "$sys_path" && -x "$sys_path" ]]; then
                echo "$alias_name|$sys_path|$alias_def" >> "$shadow_file"
                ((shadow_count++))
            fi
        fi
    done

    rm -f "$metadata_cache"

    if [[ $unused_count -eq 0 ]]; then
        echo "  ✅ All aliases are being used! Great job!"
    else
        if [[ $unused_count -gt $max_show ]]; then
            echo ""
            echo "  ... and $((unused_count - max_show)) more unused aliases"
            echo "  💡 Total: $unused_count unused aliases"
            echo "  💡 Run 'als' to see all aliases, or 'af <keyword>' to search"
        fi
    fi

    rm -f "$used_cmds_file" "$aliases_file"

    # Show command shadowing warnings
    if [[ $shadow_count -gt 0 ]]; then
        echo ""
        echo "⚠️  COMMAND SHADOWING WARNINGS ($shadow_count conflicts):"
        echo ""
        while IFS='|' read alias_name sys_cmd alias_def; do
            local actual_cmd="${alias_def#\'}"
            actual_cmd="${actual_cmd%\'}"
            echo "  ⚠️  $alias_name shadows system command: $sys_cmd"
            echo "     Alias: $actual_cmd"
            echo "     💡 Use 'command $alias_name' to access the original"
        done < "$shadow_file"
    fi

    rm -f "$shadow_file"

    # Check for legacy aliases marked in packs
    echo ""
    echo "🗑️  LEGACY ALIASES (marked for removal):"
    local config_file="${HOME}/.config/smart-aliases/config.json"
    local legacy_file="${TMPDIR:-/tmp}/alias-analyze-legacy-$$.txt"
    > "$legacy_file"  # Create empty file

    if [[ -f "$config_file" ]]; then
        # Get enabled packs
        local enabled_packs=$(jq -r '.enabled_packs[]?' "$config_file" 2>/dev/null)

        # Check each pack for legacy aliases
        echo "$enabled_packs" | while read pack_name; do
            [[ -z "$pack_name" ]] && continue

            # Find pack file
            local pack_file=""
            if [[ -f "${packs_dir}/${pack_name}.json" ]]; then
                pack_file="${packs_dir}/${pack_name}.json"
            fi

            if [[ -n "$pack_file" && -f "$pack_file" ]]; then
                # Find aliases marked as legacy
                local legacy_aliases=$(jq -r '.aliases[] | select(.legacy == true) | "\(.name)|\(.command)|\(.description // "")"' "$pack_file" 2>/dev/null)

                if [[ -n "$legacy_aliases" ]]; then
                    echo "$legacy_aliases" | while IFS='|' read name cmd desc; do
                        echo "  🗑️  $name → $cmd"
                        [[ -n "$desc" ]] && echo "     Description: $desc"
                        echo "     Pack: $pack_name"
                        echo "     💡 Consider removing with: alias-update $name"
                        echo "1" >> "$legacy_file"
                    done
                fi
            fi
        done
    fi

    local legacy_count=$(wc -l < "$legacy_file" 2>/dev/null || echo 0)
    if [[ $legacy_count -eq 0 ]]; then
        echo "  ✅ No legacy aliases found"
        echo "  💡 To mark an alias as legacy, add '\"legacy\": true' to its entry in the pack JSON"
    fi

    rm -f "$legacy_file"

    # Cleanup
    rm -f "$history_file"

    echo ""
    echo "🎯 Next Steps:"
    echo "  1. Use 'alias-new <command>' to create aliases for frequent commands"
    echo "  2. Use 'alias-update <name>' to update or remove unused aliases"
    echo "  3. Mark aliases as legacy by adding '\"legacy\": true' in pack JSON"
    echo "  4. Use 'alias-find <keyword>' to check existing aliases"
    echo "  5. Keep aliases short (2-4 characters) for maximum efficiency"
}

# Create short aliases for the management commands
alias ah='alias-help'
alias aw='alias-which'
alias af='alias-find'
alias an='alias-new'
alias au='alias-update'
alias als='alias-aliases'
alias aa='alias-analyze'

# Export functions so they're available in subshells
# Note: export -f is bash-specific, zsh doesn't need this
if [[ -n "$BASH_VERSION" ]]; then
    export -f validate_alias_name
    export -f extract_binary_name
    export -f extract_main_command
    export -f generate_suggestions
    export -f alias-help
    export -f alias-which
    export -f alias-find
    export -f alias-new
    export -f alias-update
    export -f alias-aliases
    export -f alias-analyze
fi
