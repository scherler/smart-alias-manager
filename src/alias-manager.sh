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
        echo "  ah  (alias-help)    - Show this help or get specific alias info"
        echo "  aw  (alias-which)   - Show command expansion and file location"
        echo "  af  (alias-find)    - Search for aliases by keyword"
        echo "  an  (alias-new)     - Create new alias interactively"
        echo "  au  (alias-update)  - Update an existing alias"
        echo "  als (alias-aliases) - List all aliases with file paths"
        echo "  aa  (alias-analyze) - Analyze command history for optimization"
        echo "  ap  (alias-packs)   - List all available packs"
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
                echo "📦 From pack: $pack ($count aliases)"

                # Process each alias
                local shown=0
                for name in "${alias_names[@]}"; do
                    [[ $shown -ge 20 ]] && break

                    # Get description from pack file
                    local desc=""
                    if [[ -n "$pack_file" ]] && command -v jq &>/dev/null; then
                        desc=$(jq -r ".aliases[] | select(.name == \"$name\") | .description // \"\"" "$pack_file" 2>/dev/null)
                    fi

                    # Use command if description is generic or empty
                    if [[ -z "$desc" ]] || [[ "$desc" == "$name command" ]] || [[ "$desc" == "$name"* && ${#desc} -lt 20 ]]; then
                        # Get the actual alias command and clean it up
                        local cmd=$(alias "$name" 2>/dev/null | sed "s/^$name=//")
                        cmd="${cmd//\'/}"  # Remove quotes
                        cmd="${cmd//\"/}"
                        cmd="${cmd//$'\n'/ }"  # Replace newlines with spaces
                        cmd="${cmd//  / }"  # Collapse multiple spaces
                        cmd="${cmd## }"  # Trim leading spaces
                        cmd="${cmd#\$}"  # Remove leading $ from $'...' syntax
                        desc="$cmd"
                    fi

                    # Truncate very long descriptions/commands
                    if [[ ${#desc} -gt 70 ]]; then
                        desc="${desc:0:67}..."
                    fi

                    # Format output with proper alignment
                    printf "  %-15s → %s\n" "$name" "$desc"
                    ((shown++))
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
                local cmd="${custom_aliases_list[$alias_name]}"

                # Clean up command
                cmd="${cmd//\'/}"
                cmd="${cmd//\"/}"
                cmd="${cmd//$'\n'/ }"
                cmd="${cmd//  / }"

                # Truncate long commands
                if [[ ${#cmd} -gt 70 ]]; then
                    cmd="${cmd:0:67}..."
                fi

                printf "  %-15s → %s\n" "$alias_name" "$cmd"
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

    # Generate smart suggestions based on command
    local suggestions=()
    # Split command into words (zsh/bash compatible)
    # In zsh: use $=command for word splitting
    # In bash: IFS splitting is enabled by default
    if [[ -n "$ZSH_VERSION" ]]; then
        setopt SH_WORD_SPLIT  # Enable word splitting in zsh
        local words=($command)
        unsetopt SH_WORD_SPLIT  # Restore default
    else
        local words=($command)  # bash splits by default
    fi
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

alias-update() {
    if [[ -z "$1" ]]; then
        echo "Usage: alias-update <alias-name>"
        echo "Updates an existing alias's command and/or description"
        echo ""
        echo "Examples:"
        echo "  alias-update gs        # Update the 'gs' alias"
        echo "  alias-update xc        # Update the 'xc' alias"
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

    # Get new command
    echo -n "New command (press Enter to keep current): "
    read new_cmd
    [[ -z "$new_cmd" ]] && new_cmd="$current_cmd"

    # Get new description
    echo -n "New description (press Enter to keep current): "
    read new_desc
    [[ -z "$new_desc" ]] && new_desc="$current_desc"

    # Escape for JSON
    local escaped_cmd=$(echo "$new_cmd" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    local escaped_desc=$(echo "$new_desc" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

    # Update the alias in the pack file
    jq ".aliases = [.aliases[] | if .name == \"$alias_name\" then .command = \"$escaped_cmd\" | .description = \"$escaped_desc\" else . end]" "$pack_file" > "${pack_file}.tmp" && mv "${pack_file}.tmp" "$pack_file"

    # Validate JSON
    if ! jq empty "$pack_file" 2>/dev/null; then
        echo "❌ Error: Invalid JSON generated"
        return 1
    fi

    # Update alias in current session
    alias "$alias_name"="$new_cmd"

    echo ""
    echo "✅ Alias updated successfully!"
    echo ""
    echo "📌 Updated: $alias_name = '$new_cmd'"
    echo "📦 Saved to: $pack_file"
    echo ""
    echo "💡 The alias is now active in your current session"
    echo "💡 Run 'alias-refresh' to update the cache for future sessions"
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
    echo "📊 Analyzing Command History..."
    echo "================================"
    echo ""

    # Analyze command history for patterns
    echo "🔝 Top 20 Most Used Commands:"
    if [[ -n "$HISTFILE" ]]; then
        history | awk '{$1=""; print $0}' | sed 's/^[ \t]*//' | sort | uniq -c | sort -rn | head -20 | while read count cmd; do
            # First check if the entire command itself is an alias
            local first_word=$(echo "$cmd" | awk '{print $1}')
            local is_alias=$(alias "$first_word" 2>/dev/null)

            if [[ -n "$is_alias" ]]; then
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
                # Check if command already has an alias
                local first_word=$(echo "$cmd" | awk '{print $1}')
                local existing_alias=$(alias "$first_word" 2>/dev/null)

                if [[ -n "$existing_alias" ]]; then
                    # Skip if already aliased
                    continue
                fi

                echo "  $count× $cmd"

                # Generate smart suggestions based on command
                local suggestions=()
                if [[ -n "$ZSH_VERSION" ]]; then
                    setopt SH_WORD_SPLIT
                    local words=($cmd)
                    unsetopt SH_WORD_SPLIT
                else
                    local words=($cmd)
                fi

                # Build suggestions based on command type
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

                # Check which suggestions are available
                local available_suggestions=()
                for suggestion in "${suggestions[@]}"; do
                    if [[ -n "$suggestion" ]]; then
                        local existing=$(alias "$suggestion" 2>/dev/null)
                        if [[ -z "$existing" ]]; then
                            available_suggestions+=("$suggestion")
                        fi
                    fi
                done

                # Display suggestions
                if [[ ${#available_suggestions[@]} -gt 0 ]]; then
                    echo "     → Suggested aliases: ${available_suggestions[*]}"
                else
                    echo "     → No simple suggestions available (common aliases taken)"
                fi
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
alias au='alias-update'
alias als='alias-aliases'
alias aa='alias-analyze'

# Export functions so they're available in subshells
# Note: export -f is bash-specific, zsh doesn't need this
if [[ -n "$BASH_VERSION" ]]; then
    export -f alias-help
    export -f alias-which
    export -f alias-find
    export -f alias-new
    export -f alias-update
    export -f alias-aliases
    export -f alias-analyze
fi
