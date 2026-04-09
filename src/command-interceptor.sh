#!/bin/zsh
# Smart Alias Agent - Command Interceptor
# Hooks into shell preexec to analyze commands before execution

# Agent state
SMART_ALIAS_AGENT_ACTIVE=0
SMART_ALIAS_AGENT_IN_HOOK=0

# Initialize agent hook for zsh
smart_alias_agent_init() {
    # Check if already initialized
    if [[ $SMART_ALIAS_AGENT_ACTIVE -eq 1 ]]; then
        return 0
    fi

    # Load config
    local config_file="$HOME/.config/smart-aliases/agent-config.json"
    if [[ ! -f "$config_file" ]]; then
        smart_alias_agent_create_default_config
    fi

    # Check if enabled
    local enabled=$(jq -r '.enabled' "$config_file" 2>/dev/null || echo "false")
    if [[ "$enabled" != "true" ]]; then
        return 0
    fi

    # Add to preexec hook for zsh
    if [[ -n "$ZSH_VERSION" ]]; then
        local init_log="/tmp/smart-alias-init.log"
        echo "=== Agent Init ===" >> "$init_log"
        echo "Timestamp: $(date)" >> "$init_log"

        # Use add-zsh-hook if available, otherwise use array directly
        if (( $+functions[add-zsh-hook] )); then
            echo "Using add-zsh-hook method" >> "$init_log"
            add-zsh-hook preexec smart_alias_agent_hook
        else
            echo "Using preexec_functions array method" >> "$init_log"
            # Ensure array exists
            typeset -ga preexec_functions 2>/dev/null
            if [[ ! " ${preexec_functions[*]} " =~ " smart_alias_agent_hook " ]]; then
                preexec_functions+=(smart_alias_agent_hook)
                echo "Added hook to array" >> "$init_log"
            else
                echo "Hook already in array" >> "$init_log"
            fi
        fi

        echo "preexec_functions contents: ${preexec_functions[*]}" >> "$init_log"
        echo "" >> "$init_log"
    fi

    SMART_ALIAS_AGENT_ACTIVE=1
    SMART_ALIAS_AGENT_IN_HOOK=0
}

# Create default config
smart_alias_agent_create_default_config() {
    local config_file="$HOME/.config/smart-aliases/agent-config.json"
    local config_dir="$HOME/.config/smart-aliases"

    mkdir -p "$config_dir"

    cat > "$config_file" <<'EOF'
{
  "enabled": false,
  "min_command_length": 8,
  "min_frequency": 3,
  "prompt_timeout": 5,
  "skip_patterns": [
    "^cd ",
    "^ls ",
    "^cat ",
    "^echo ",
    "^pwd",
    "^clear"
  ],
  "sensitive_keywords": [
    "password",
    "token",
    "secret",
    "key",
    "api_key",
    "apikey"
  ],
  "suggestion_limit": 3
}
EOF

    # Create other data files
    echo '{"patterns": []}' > "$config_dir/command-patterns.json"
    echo '{"rejections": []}' > "$config_dir/rejections.json"
    echo '{"total_suggestions": 0, "accepted": 0, "rejected": 0, "ignored": 0}' > "$config_dir/agent-stats.json"
}

# Check if command could be replaced by existing alias
smart_alias_agent_check_existing_alias() {
    local cmd="$1"
    local debug_log="/tmp/smart-alias-debug.log"

    echo "=== DEBUG: Checking '$cmd' ===" >> "$debug_log"
    echo "Timestamp: $(date)" >> "$debug_log"

    # Check if any alias expands to this exact command
    local found_count=0
    while IFS= read -r alias_line; do
        # Skip empty lines
        [[ -z "$alias_line" ]] && continue

        ((found_count++))

        # Parse alias line: "name=value" or "name='value'"
        local alias_name="${alias_line%%=*}"
        local alias_value="${alias_line#*=}"

        # Debug: show what we're comparing
        if [[ $found_count -le 5 ]]; then
            echo "  Alias $found_count: name='$alias_name' value='$alias_value'" >> "$debug_log"
        fi

        # Remove quotes
        alias_value="${alias_value#\'}"
        alias_value="${alias_value%\'}"
        alias_value="${alias_value#\"}"
        alias_value="${alias_value%\"}"

        # Debug: show after quote removal
        if [[ $found_count -le 5 ]]; then
            echo "    After quotes: '$alias_value'" >> "$debug_log"
        fi

        # If this alias expands to our command, and the alias is shorter
        if [[ "$alias_value" == "$cmd" ]]; then
            echo "  MATCH FOUND: $alias_name = $alias_value" >> "$debug_log"
            if [[ ${#alias_name} -lt ${#cmd} ]]; then
                echo "  SUGGESTING (saves $((${#cmd} - ${#alias_name})) chars)" >> "$debug_log"
                echo ""
                echo "💡 Alias suggestion: Use '\033[36m$alias_name\033[0m' instead of '$cmd'"
                echo "   (saves $((${#cmd} - ${#alias_name})) characters)"
                echo ""
                return 0
            fi
        fi
    done < <(alias 2>/dev/null)

    echo "Total aliases checked: $found_count" >> "$debug_log"
    echo "" >> "$debug_log"
    return 0
}

# Main preexec hook
smart_alias_agent_hook() {
    local debug_log="/tmp/smart-alias-debug.log"

    echo ">>> HOOK CALLED with $# args" >> "$debug_log"
    echo "    \$1='$1'" >> "$debug_log"
    echo "    \$2='$2'" >> "$debug_log"
    echo "    \$3='$3'" >> "$debug_log"
    echo "    ACTIVE=$SMART_ALIAS_AGENT_ACTIVE IN_HOOK=$SMART_ALIAS_AGENT_IN_HOOK" >> "$debug_log"

    # Use $1 which is the command as typed
    local cmd="$1"

    # Skip if agent disabled
    if [[ $SMART_ALIAS_AGENT_ACTIVE -ne 1 ]]; then
        echo "    SKIPPED: Agent not active" >> "$debug_log"
        return 0
    fi

    # CRITICAL: Prevent infinite loop - skip if already in hook
    if [[ $SMART_ALIAS_AGENT_IN_HOOK -eq 1 ]]; then
        echo "    SKIPPED: Already in hook (preventing recursion)" >> "$debug_log"
        return 0
    fi

    # Set guard flag
    SMART_ALIAS_AGENT_IN_HOOK=1

    # FIRST: Check if user typed long form when short alias exists
    smart_alias_agent_check_existing_alias "$cmd"

    # THEN: Check eligibility for creating new aliases
    if ! smart_alias_agent_is_eligible "$cmd"; then
        echo "    Not eligible for new alias suggestion" >> "$debug_log"
        SMART_ALIAS_AGENT_IN_HOOK=0
        return 0
    fi

    # Analyze and potentially suggest
    smart_alias_agent_analyze "$cmd"

    # Clear guard flag
    SMART_ALIAS_AGENT_IN_HOOK=0
}

# Check if command is eligible for analysis
smart_alias_agent_is_eligible() {
    local cmd="$1"
    local config_file="$HOME/.config/smart-aliases/agent-config.json"

    # Load config
    local min_length=$(jq -r '.min_command_length' "$config_file")

    # Skip if command too short
    if [[ ${#cmd} -le $min_length ]]; then
        return 1
    fi

    # Extract first word
    local first_word="${cmd%% *}"

    # Skip if starts with known alias
    if alias "$first_word" &>/dev/null; then
        return 1
    fi

    # Skip if matches skip patterns
    local skip_patterns=$(jq -r '.skip_patterns[]' "$config_file" 2>/dev/null)
    while IFS= read -r pattern; do
        if [[ "$cmd" =~ $pattern ]]; then
            return 1
        fi
    done <<< "$skip_patterns"

    # Skip if contains sensitive keywords
    local sensitive_keywords=$(jq -r '.sensitive_keywords[]' "$config_file" 2>/dev/null)
    while IFS= read -r keyword; do
        if [[ "$cmd" =~ $keyword ]]; then
            return 1
        fi
    done <<< "$sensitive_keywords"

    # Skip if in rejections
    local rejections_file="$HOME/.config/smart-aliases/rejections.json"
    if [[ -f "$rejections_file" ]]; then
        local is_rejected=$(jq -r --arg cmd "$cmd" '.rejections[] | select(.pattern == $cmd) | .pattern' "$rejections_file")
        if [[ -n "$is_rejected" ]]; then
            return 1
        fi
    fi

    return 0
}

# Analyze command and suggest if appropriate
smart_alias_agent_analyze() {
    local cmd="$1"
    local config_file="$HOME/.config/smart-aliases/agent-config.json"
    local patterns_file="$HOME/.config/smart-aliases/command-patterns.json"
    local min_frequency=$(jq -r '.min_frequency' "$config_file")

    # Record this command execution
    smart_alias_agent_record_command "$cmd"

    # Check frequency
    local frequency=$(jq -r --arg cmd "$cmd" '.patterns[] | select(.command == $cmd) | .count' "$patterns_file")
    frequency=${frequency:-0}

    # Only suggest if seen enough times
    if [[ $frequency -lt $min_frequency ]]; then
        return 0
    fi

    # Check if already suggested
    local already_suggested=$(jq -r --arg cmd "$cmd" '.patterns[] | select(.command == $cmd) | .suggested' "$patterns_file")
    if [[ "$already_suggested" == "true" ]]; then
        return 0
    fi

    # Generate suggestions
    local suggestions=$(smart_alias_agent_generate_suggestions "$cmd")

    if [[ -z "$suggestions" ]]; then
        return 0
    fi

    # Show interactive prompt
    smart_alias_agent_show_prompt "$cmd" "$suggestions"
}

# Record command for pattern learning
smart_alias_agent_record_command() {
    local cmd="$1"
    local patterns_file="$HOME/.config/smart-aliases/command-patterns.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if command already exists
    local exists=$(jq -r --arg cmd "$cmd" '.patterns[] | select(.command == $cmd) | .command' "$patterns_file")

    if [[ -n "$exists" ]]; then
        # Update count and last_seen
        jq --arg cmd "$cmd" --arg ts "$timestamp" \
            '(.patterns[] | select(.command == $cmd) | .count) += 1 |
             (.patterns[] | select(.command == $cmd) | .last_seen) = $ts' \
            "$patterns_file" > "${patterns_file}.tmp" && mv "${patterns_file}.tmp" "$patterns_file"
    else
        # Add new pattern
        jq --arg cmd "$cmd" --arg ts "$timestamp" \
            '.patterns += [{
                "command": $cmd,
                "count": 1,
                "first_seen": $ts,
                "last_seen": $ts,
                "suggested": false
            }]' \
            "$patterns_file" > "${patterns_file}.tmp" && mv "${patterns_file}.tmp" "$patterns_file"
    fi
}

# Generate alias suggestions (uses existing logic from alias-manager)
smart_alias_agent_generate_suggestions() {
    local cmd="$1"

    # Use existing generate_suggestions function if available
    if command -v generate_suggestions &>/dev/null; then
        generate_suggestions "$cmd"
    else
        # Fallback basic suggestion
        local first_word="${cmd%% *}"
        local second_word="${cmd#* }"
        second_word="${second_word%% *}"

        # Generate simple suggestions based on initials
        echo "${first_word:0:1}${second_word:0:1}"
        echo "${first_word:0:1}${second_word:0:2}"
    fi
}

# Show interactive prompt
smart_alias_agent_show_prompt() {
    local cmd="$1"
    local suggestions="$2"
    local config_file="$HOME/.config/smart-aliases/agent-config.json"
    local timeout=$(jq -r '.prompt_timeout' "$config_file")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 Smart Alias Suggestion"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Command: \033[33m$cmd\033[0m"
    echo ""
    echo "Suggestions:"

    local -a suggestion_array
    local idx=1
    while IFS= read -r suggestion; do
        [[ -z "$suggestion" ]] && continue
        echo "  [\033[32m$idx\033[0m] Create alias: \033[36m$suggestion\033[0m='$cmd'"
        suggestion_array+=("$suggestion")
        ((idx++))
    done <<< "$suggestions"

    local run_idx=$idx
    local never_idx=$((idx + 1))

    echo "  [\033[32m$run_idx\033[0m] Just run command"
    echo "  [\033[32m$never_idx\033[0m] Never suggest for this pattern"
    echo ""

    # Read user choice with timeout
    local choice
    read -t $timeout -k 1 "choice?Choose [1-$never_idx] (${timeout}s timeout): "
    echo ""

    # Update stats
    smart_alias_agent_update_stats "suggestion_shown"

    case "$choice" in
        [1-9])
            if [[ $choice -le ${#suggestion_array[@]} ]]; then
                # Create alias
                local alias_name="${suggestion_array[$choice]}"
                echo "✅ Creating alias: $alias_name='$cmd'"
                smart_alias_agent_create_and_use "$alias_name" "$cmd"
                smart_alias_agent_mark_suggested "$cmd"
                smart_alias_agent_update_stats "accepted"
            elif [[ $choice -eq $run_idx ]]; then
                # Just run - mark as suggested to avoid repeat
                smart_alias_agent_mark_suggested "$cmd"
                smart_alias_agent_update_stats "ignored"
            elif [[ $choice -eq $never_idx ]]; then
                # Never suggest
                echo "🚫 Won't suggest again for: $cmd"
                smart_alias_agent_add_rejection "$cmd"
                smart_alias_agent_update_stats "rejected"
            fi
            ;;
        *)
            # Timeout or invalid - just run
            echo "⏱️  Timeout - running command"
            smart_alias_agent_mark_suggested "$cmd"
            smart_alias_agent_update_stats "ignored"
            ;;
    esac

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Create alias and add to pack
smart_alias_agent_create_and_use() {
    local alias_name="$1"
    local cmd="$2"
    local pack_file="$HOME/.config/smart-aliases/packs/local/agent-created.json"

    # Ensure pack exists
    if [[ ! -f "$pack_file" ]]; then
        mkdir -p "$(dirname "$pack_file")"
        cat > "$pack_file" <<'EOF'
{
  "name": "agent-created",
  "version": "1.0.0",
  "description": "Aliases created by Smart Alias Agent",
  "aliases": []
}
EOF
    fi

    # Add alias to pack
    local escaped_cmd=$(echo "$cmd" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    jq --arg name "$alias_name" --arg cmd "$escaped_cmd" \
        '.aliases += [{
            "name": $name,
            "type": "alias",
            "command": $cmd,
            "description": "Auto-generated by agent",
            "category": "agent",
            "enabled": true
        }]' \
        "$pack_file" > "${pack_file}.tmp" && mv "${pack_file}.tmp" "$pack_file"

    # Refresh cache
    if command -v alias-refresh &>/dev/null; then
        alias-refresh &>/dev/null
    fi

    # Create alias in current session
    alias "$alias_name=$cmd"
}

# Mark command as suggested
smart_alias_agent_mark_suggested() {
    local cmd="$1"
    local patterns_file="$HOME/.config/smart-aliases/command-patterns.json"

    jq --arg cmd "$cmd" \
        '(.patterns[] | select(.command == $cmd) | .suggested) = true' \
        "$patterns_file" > "${patterns_file}.tmp" && mv "${patterns_file}.tmp" "$patterns_file"
}

# Add to rejections
smart_alias_agent_add_rejection() {
    local cmd="$1"
    local rejections_file="$HOME/.config/smart-aliases/rejections.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq --arg cmd "$cmd" --arg ts "$timestamp" \
        '.rejections += [{
            "pattern": $cmd,
            "rejected_at": $ts,
            "reason": "user_choice"
        }]' \
        "$rejections_file" > "${rejections_file}.tmp" && mv "${rejections_file}.tmp" "$rejections_file"
}

# Update statistics
smart_alias_agent_update_stats() {
    local event="$1"
    local stats_file="$HOME/.config/smart-aliases/agent-stats.json"

    case "$event" in
        suggestion_shown)
            jq '.total_suggestions += 1' "$stats_file" > "${stats_file}.tmp" && mv "${stats_file}.tmp" "$stats_file"
            ;;
        accepted)
            jq '.accepted += 1' "$stats_file" > "${stats_file}.tmp" && mv "${stats_file}.tmp" "$stats_file"
            ;;
        rejected)
            jq '.rejected += 1' "$stats_file" > "${stats_file}.tmp" && mv "${stats_file}.tmp" "$stats_file"
            ;;
        ignored)
            jq '.ignored += 1' "$stats_file" > "${stats_file}.tmp" && mv "${stats_file}.tmp" "$stats_file"
            ;;
    esac
}

# Note: In zsh, functions are automatically available once defined.
# No explicit export needed (unlike bash which requires 'export -f')
