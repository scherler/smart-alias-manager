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

alias-help() {
    if [[ -z "$1" ]]; then
        echo "📚 ALIAS HELP - Available Commands"
        echo "=================================="
        echo ""
        echo "🔧 MANAGEMENT COMMANDS:"
        echo "  ah (alias-help)    - Show this help or get specific alias info"
        echo "  aw (alias-which)   - Show command expansion for an alias"
        echo "  af (alias-find)    - Search for aliases by keyword"
        echo "  an (alias-new)     - Create new alias interactively"
        echo "  aa (alias-analyze) - Analyze command history for optimization"
        echo "  ap (alias-packs)   - List all available packs"
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
            [[ "$alias_name" =~ ^(ah|aw|af|an|aa|ae|ap)$ ]] && continue

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

        echo "📊 YOUR ALIASES (${total_aliases} total):"
        echo ""

        # Show pack-based aliases first
        if [[ ${#pack_aliases[@]} -gt 0 ]]; then
            for pack in "${(@k)pack_aliases}"; do
                local count=$(echo -e "${pack_aliases[$pack]}" | wc -l)
                echo "📦 From pack: $pack ($count aliases)"
                echo -e "${pack_aliases[$pack]}" | head -20 | while IFS= read -r line; do
                    local name="${line%%=*}"
                    echo "  $name"
                done
                if [[ $count -gt 20 ]]; then
                    echo "  ... and $((count - 20)) more"
                fi
                echo ""
            done
        fi

        # Show custom aliases
        if [[ ${#custom_aliases_list[@]} -gt 0 ]]; then
            local custom_count=${#custom_aliases_list[@]}
            echo "✏️  Custom aliases ($custom_count)"
            local shown=0
            for alias_name in "${(@k)custom_aliases_list}"; do
                echo "  $alias_name"
                ((shown++))
                [[ $shown -ge 20 ]] && break
            done
            if [[ $custom_count -gt 20 ]]; then
                echo "  ... and $((custom_count - 20)) more"
            fi
            echo ""
        fi

        # Only show samples if no aliases exist
        if [[ $total_aliases -eq 0 ]]; then
            echo "  No aliases loaded yet."
            echo ""
            echo "  💡 Enable a pack: alias-enable <pack-name>"
            echo "  💡 Create an alias: alias-new <command>"
            echo "  💡 View available packs: alias-packs"
        else
            echo "💡 TIP: Use 'alias-help <name>' for specific alias info"
            echo "💡 TIP: Use 'alias-find <keyword>' to search aliases"
            echo "💡 TIP: Use 'alias-packs' to see available packs"
        fi
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
        echo "Shows the full command expansion for an alias"
        echo ""
        echo "Example: alias-which gs"
        echo "Output: 'git status'"
    else
        local alias_def=$(alias "$1" 2>/dev/null)
        if [[ -n "$alias_def" ]]; then
            echo "${alias_def#*=}"
        else
            echo "Alias '$1' not found"
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

    # Generate smart suggestions based on command
    local suggestions=()
    local words=($=command)  # Use $= to force word splitting
    local first_word="${words[1]}"  # zsh arrays start at 1

    # Determine category based on command
    local category="misc"
    case "$first_word" in
        git)
            category="git"
            local git_cmd="${words[2]}"
            suggestions+=("g${git_cmd:0:1}")
            suggestions+=("g${git_cmd:0:2}")
            if [[ "${#words[@]}" -gt 2 ]]; then
                suggestions+=("g${git_cmd:0:1}${words[3]:0:1}")
            fi
            ;;
        docker)
            category="docker"
            if [[ "${words[2]}" == "compose" ]]; then
                suggestions+=("dc${words[3]:0:1}")
                suggestions+=("dc${words[3]:0:2}")
            else
                suggestions+=("d${words[2]:0:1}")
                suggestions+=("d${words[2]:0:2}")
            fi
            ;;
        kubectl|k)
            category="misc"
            suggestions+=("k${words[2]:0:1}")
            suggestions+=("k${words[2]:0:2}")
            if [[ "${#words[@]}" -gt 2 ]]; then
                suggestions+=("k${words[2]:0:1}${words[3]:0:1}")
            fi
            ;;
        npm)
            category="npm-yarn"
            suggestions+=("n${words[2]:0:1}")
            suggestions+=("n${words[2]:0:2}")
            ;;
        yarn)
            category="npm-yarn"
            suggestions+=("y${words[2]:0:1}")
            suggestions+=("y${words[2]:0:2}")
            ;;
        mvn|maven)
            category="maven"
            suggestions+=("m${words[2]:0:1}")
            suggestions+=("m${words[2]:0:2}")
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

    # Check existing aliases and show suggestions
    echo "💡 Suggested aliases (based on command pattern):"
    local valid_suggestions=()
    for suggestion in "${suggestions[@]}"; do
        if [[ -n "$suggestion" ]]; then
            local existing=$(alias "$suggestion" 2>/dev/null)
            if [[ -z "$existing" ]]; then
                echo "  ✅ $suggestion (available)"
                valid_suggestions+=("$suggestion")
            else
                echo "  ❌ $suggestion (taken: ${existing#*=})"
            fi
        fi
    done

    echo "  📝 Or enter a custom alias name"
    echo ""

    # Get user choice
    echo -n "Choose alias name (or press Enter to skip): "
    read chosen_alias

    if [[ -z "$chosen_alias" ]]; then
        echo "❌ Alias creation cancelled"
        return
    fi

    # Check if alias already exists
    local existing=$(alias "$chosen_alias" 2>/dev/null)
    if [[ -n "$existing" ]]; then
        echo "⚠️  Alias '$chosen_alias' already exists: ${existing#*=}"
        echo -n "Overwrite? (y/N): "
        read overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            echo "❌ Alias creation cancelled"
            return
        fi
    fi

    # Get description if not provided
    if [[ -z "$description" ]]; then
        echo -n "Description (optional): "
        read description
        [[ -z "$description" ]] && description="$chosen_alias command"
    fi

    # Determine pack file
    local pack_file="$packs_dir/extracted-${category}.json"

    # Create pack if it doesn't exist
    if [[ ! -f "$pack_file" ]]; then
        echo "📦 Creating new pack: extracted-${category}"
        cat > "$pack_file" <<EOF
{
  "name": "extracted-${category}",
  "version": "1.0.0",
  "author": "User-created aliases",
  "description": "${category^} aliases",
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

    echo "✅ Alias created successfully!"
    echo ""
    echo "📌 New alias: $chosen_alias = '$command'"
    echo "📦 Saved to: $pack_file"
    echo ""
    echo "💡 The alias is now active in your current session"
    echo "💡 To persist across sessions, ensure pack is enabled:"
    echo "   alias-enable extracted-${category}"
}

alias-analyze() {
    echo "📊 Analyzing Command History..."
    echo "================================"
    echo ""
    
    # Analyze command history for patterns
    echo "🔝 Top 20 Most Used Commands:"
    if [[ -n "$HISTFILE" ]]; then
        history | awk '{$1=""; print $0}' | sed 's/^[ \t]*//' | sort | uniq -c | sort -rn | head -20 | while read count cmd; do
            # Check if command has an alias
            local first_word=$(echo "$cmd" | awk '{print $1}')
            local has_alias=$(alias | grep "='$first_word" | head -1)
            if [[ -n "$has_alias" ]]; then
                echo "  $count× $cmd ✅ (aliased)"
            else
                echo "  $count× $cmd ⚠️ (no alias)"
            fi
        done
    else
        fc -l 1 2>/dev/null | awk '{$1=""; print $0}' | sed 's/^[ \t]*//' | sort | uniq -c | sort -rn | head -20
    fi
    
    echo ""
    echo "💡 OPTIMIZATION SUGGESTIONS:"
    
    # Find long commands without aliases
    local long_commands=$(history 2>/dev/null | awk '{$1=""; print $0}' | sed 's/^[ \t]*//' | awk 'length > 20' | sort | uniq -c | sort -rn | head -5)
    if [[ -n "$long_commands" ]]; then
        echo ""
        echo "📝 Long commands that could benefit from aliases:"
        echo "$long_commands" | while read count cmd; do
            if [[ $count -gt 2 ]]; then
                echo "  $count× $cmd"
                # Suggest an alias
                local words=($cmd)
                local suggestion=""
                for word in "${words[@]:0:3}"; do
                    suggestion+="${word:0:1}"
                done
                echo "     → Suggested alias: $suggestion"
            fi
        done
    fi
    
    echo ""
    echo "🎯 Next Steps:"
    echo "  1. Use 'alias-new <command>' to create aliases for frequent commands"
    echo "  2. Use 'alias-find <keyword>' to check existing aliases"
    echo "  3. Keep aliases short (2-4 characters) for maximum efficiency"
}

# Create short aliases for the management commands
alias ah='alias-help'
alias aw='alias-which'
alias af='alias-find'
alias an='alias-new'
alias aa='alias-analyze'

# Export functions so they're available in subshells
# Note: export -f is bash-specific, zsh doesn't need this
if [[ -n "$BASH_VERSION" ]]; then
    export -f alias-help
    export -f alias-which
    export -f alias-find
    export -f alias-new
    export -f alias-analyze
fi
