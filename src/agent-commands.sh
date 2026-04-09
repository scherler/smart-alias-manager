#!/bin/zsh
# Smart Alias Agent - Management Commands

# Enable agent mode
alias-agent-enable() {
    local config_file="$HOME/.config/smart-aliases/agent-config.json"

    # Ensure config exists
    if [[ ! -f "$config_file" ]]; then
        smart_alias_agent_create_default_config
    fi

    # Enable in config
    jq '.enabled = true' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"

    # Initialize agent
    smart_alias_agent_init

    echo "✅ Smart Alias Agent enabled"
    echo ""
    echo "The agent will now:"
    echo "  • Analyze commands > 8 characters"
    echo "  • Suggest aliases for frequently repeated commands"
    echo "  • Learn from your patterns"
    echo ""
    echo "To disable: alias-agent-disable"
    echo "To see stats: alias-agent-stats"
}

# Disable agent mode
alias-agent-disable() {
    local config_file="$HOME/.config/smart-aliases/agent-config.json"

    # Disable in config
    if [[ -f "$config_file" ]]; then
        jq '.enabled = false' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    fi

    # Remove from preexec hook
    if [[ -n "$ZSH_VERSION" ]]; then
        # Use add-zsh-hook if available, otherwise use array directly
        if (( $+functions[add-zsh-hook] )); then
            add-zsh-hook -d preexec smart_alias_agent_hook
        else
            preexec_functions=(${preexec_functions:#smart_alias_agent_hook})
        fi
    fi

    SMART_ALIAS_AGENT_ACTIVE=0
    SMART_ALIAS_AGENT_IN_HOOK=0

    echo "✅ Smart Alias Agent disabled"
}

# Show agent status
alias-agent-status() {
    local config_file="$HOME/.config/smart-aliases/agent-config.json"

    if [[ ! -f "$config_file" ]]; then
        echo "❌ Agent not configured"
        echo "Run 'alias-agent-enable' to set up"
        return 1
    fi

    local enabled=$(jq -r '.enabled' "$config_file")
    local min_length=$(jq -r '.min_command_length' "$config_file")
    local min_freq=$(jq -r '.min_frequency' "$config_file")

    echo "Smart Alias Agent Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ "$enabled" == "true" ]]; then
        echo "Status: \033[32m●\033[0m Enabled"
    else
        echo "Status: \033[31m●\033[0m Disabled"
    fi

    echo ""
    echo "Settings:"
    echo "  Min command length: $min_length chars"
    echo "  Min frequency: $min_freq times"
    echo ""

    # Show quick stats
    local stats_file="$HOME/.config/smart-aliases/agent-stats.json"
    if [[ -f "$stats_file" ]]; then
        local total=$(jq -r '.total_suggestions' "$stats_file")
        local accepted=$(jq -r '.accepted' "$stats_file")
        local rejected=$(jq -r '.rejected' "$stats_file")

        echo "Quick Stats:"
        echo "  Total suggestions: $total"
        echo "  Accepted: $accepted"
        echo "  Rejected: $rejected"

        if [[ $total -gt 0 ]]; then
            local acceptance_rate=$(( (accepted * 100) / total ))
            echo "  Acceptance rate: ${acceptance_rate}%"
        fi
    fi

    echo ""
    echo "Commands:"
    echo "  alias-agent-enable  (aae) - Enable agent"
    echo "  alias-agent-disable (aad) - Disable agent"
    echo "  alias-agent-stats   (aast) - Detailed statistics"
    echo "  alias-agent-config  (aac) - Edit configuration"
}

# Show detailed statistics
alias-agent-stats() {
    local stats_file="$HOME/.config/smart-aliases/agent-stats.json"
    local patterns_file="$HOME/.config/smart-aliases/command-patterns.json"
    local rejections_file="$HOME/.config/smart-aliases/rejections.json"

    echo "Smart Alias Agent - Detailed Statistics"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Overall stats
    if [[ -f "$stats_file" ]]; then
        local total=$(jq -r '.total_suggestions' "$stats_file")
        local accepted=$(jq -r '.accepted' "$stats_file")
        local rejected=$(jq -r '.rejected' "$stats_file")
        local ignored=$(jq -r '.ignored' "$stats_file")

        echo "📊 Overall Statistics"
        echo "  Total suggestions shown: $total"
        echo "  Accepted (created alias): $accepted"
        echo "  Rejected (never show): $rejected"
        echo "  Ignored (just ran): $ignored"

        if [[ $total -gt 0 ]]; then
            local acceptance_rate=$(( (accepted * 100) / total ))
            echo "  Acceptance rate: ${acceptance_rate}%"
        fi
        echo ""
    fi

    # Top patterns
    if [[ -f "$patterns_file" ]]; then
        local pattern_count=$(jq -r '.patterns | length' "$patterns_file")
        echo "📝 Learned Patterns: $pattern_count"

        if [[ $pattern_count -gt 0 ]]; then
            echo ""
            echo "Top 5 frequent commands:"
            jq -r '.patterns | sort_by(.count) | reverse | limit(5;.[]) | "  \(.count)x: \(.command)"' "$patterns_file"
        fi
        echo ""
    fi

    # Rejections
    if [[ -f "$rejections_file" ]]; then
        local rejection_count=$(jq -r '.rejections | length' "$rejections_file")
        echo "🚫 Rejected Patterns: $rejection_count"

        if [[ $rejection_count -gt 0 && $rejection_count -le 5 ]]; then
            echo ""
            jq -r '.rejections[] | "  • \(.pattern)"' "$rejections_file"
        fi
        echo ""
    fi

    # Agent-created aliases
    local agent_pack="$HOME/.config/smart-aliases/packs/local/agent-created.json"
    if [[ -f "$agent_pack" ]]; then
        local alias_count=$(jq -r '.aliases | length' "$agent_pack")
        echo "🤖 Agent-Created Aliases: $alias_count"

        if [[ $alias_count -gt 0 ]]; then
            echo ""
            jq -r '.aliases[] | "  \(.name) = \(.command)"' "$agent_pack" | head -10

            if [[ $alias_count -gt 10 ]]; then
                echo "  ... and $((alias_count - 10)) more"
            fi
        fi
        echo ""
    fi
}

# Edit agent configuration
alias-agent-config() {
    local config_file="$HOME/.config/smart-aliases/agent-config.json"

    if [[ ! -f "$config_file" ]]; then
        smart_alias_agent_create_default_config
    fi

    # Use user's preferred editor
    local editor="${EDITOR:-vi}"
    $editor "$config_file"

    # Validate JSON
    if ! jq empty "$config_file" 2>/dev/null; then
        echo "❌ Error: Invalid JSON in config file"
        echo "Please fix the syntax errors"
        return 1
    fi

    echo "✅ Configuration updated"
    echo ""
    echo "Restart your shell or run 'alias-agent-enable' to apply changes"
}

# Clear learned patterns
alias-agent-clear() {
    local patterns_file="$HOME/.config/smart-aliases/command-patterns.json"
    local rejections_file="$HOME/.config/smart-aliases/rejections.json"
    local stats_file="$HOME/.config/smart-aliases/agent-stats.json"

    echo "⚠️  This will clear:"
    echo "  • All learned command patterns"
    echo "  • All rejections"
    echo "  • All statistics"
    echo ""
    echo "Agent-created aliases will NOT be deleted."
    echo ""
    read -q "REPLY?Continue? [y/N] "
    echo ""

    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo '{"patterns": []}' > "$patterns_file"
        echo '{"rejections": []}' > "$rejections_file"
        echo '{"total_suggestions": 0, "accepted": 0, "rejected": 0, "ignored": 0}' > "$stats_file"

        echo "✅ Agent data cleared"
    else
        echo "❌ Cancelled"
    fi
}

# Short aliases
alias aae='alias-agent-enable'
alias aad='alias-agent-disable'
alias aas='alias-agent-status'
alias aast='alias-agent-stats'
alias aac='alias-agent-config'
alias aacl='alias-agent-clear'

# Export functions for bash compatibility
if [[ -z "$ZSH_VERSION" ]]; then
    export -f alias-agent-enable
    export -f alias-agent-disable
    export -f alias-agent-status
    export -f alias-agent-stats
    export -f alias-agent-config
    export -f alias-agent-clear
fi
