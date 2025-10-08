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
        echo "  ah (alias-help)  - Show this help or get specific alias info"
        echo "  aw (alias-which) - Show command expansion for an alias"
        echo "  af (alias-find)  - Search for aliases by keyword"
        echo "  an (alias-new)   - Create new alias interactively"
        echo "  aa (alias-analyze) - Analyze command history for optimization"
        echo ""
        echo "📊 YOUR ALIASES:"
        # List user's aliases grouped by category
        local git_aliases=$(alias | grep "^g" | head -5)
        local docker_aliases=$(alias | grep "^d" | head -5)
        local system_aliases=$(alias | grep -v "^[gd]" | head -10)
        
        if [[ -n "$git_aliases" ]]; then
            echo ""
            echo "🔷 GIT ALIASES (sample):"
            echo "$git_aliases" | while read line; do
                echo "  ${line%%=*}"
            done
        fi
        
        if [[ -n "$docker_aliases" ]]; then
            echo ""
            echo "🔷 DOCKER ALIASES (sample):"
            echo "$docker_aliases" | while read line; do
                echo "  ${line%%=*}"
            done
        fi
        
        if [[ -n "$system_aliases" ]]; then
            echo ""
            echo "🔷 SYSTEM ALIASES (sample):"
            echo "$system_aliases" | while read line; do
                echo "  ${line%%=*}"
            done
        fi
        
        echo ""
        echo "💡 TIP: Use 'alias-help <name>' for specific alias info"
        echo "💡 TIP: Use 'alias-find <keyword>' to search aliases"
        echo "💡 TIP: Use 'alias-analyze' to get optimization suggestions"
    else
        # Show specific alias info
        local alias_def=$(alias "$1" 2>/dev/null)
        if [[ -n "$alias_def" ]]; then
            echo "📌 Alias: $1"
            echo "Command: ${alias_def#*=}"
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
        echo "Usage: alias-new <command>"
        echo "Creates a new alias with smart suggestions"
        echo ""
        echo "Examples:"
        echo "  alias-new 'git status --short'"
        echo "  alias-new 'docker ps -a'"
        echo "  alias-new 'kubectl get pods --all-namespaces'"
        return
    fi
    
    local command="$1"
    local alias_file="${ALIAS_CONFIG_FILE:-$HOME/.aliases}"
    
    echo "📝 Creating alias for: $command"
    echo ""
    
    # Generate smart suggestions based on command
    local suggestions=()
    local words=($command)
    local first_word="${words[0]}"
    
    # Smart suggestions based on command type
    case "$first_word" in
        git)
            local git_cmd="${words[1]}"
            suggestions+=("g${git_cmd:0:1}")
            suggestions+=("g${git_cmd:0:2}")
            if [[ "${#words[@]}" -gt 2 ]]; then
                suggestions+=("g${git_cmd:0:1}${words[2]:0:1}")
            fi
            ;;
        docker)
            if [[ "${words[1]}" == "compose" ]]; then
                suggestions+=("dc${words[2]:0:1}")
                suggestions+=("dc${words[2]:0:2}")
            else
                suggestions+=("d${words[1]:0:1}")
                suggestions+=("d${words[1]:0:2}")
            fi
            ;;
        kubectl|k)
            suggestions+=("k${words[1]:0:1}")
            suggestions+=("k${words[1]:0:2}")
            if [[ "${#words[@]}" -gt 2 ]]; then
                suggestions+=("k${words[1]:0:1}${words[2]:0:1}")
            fi
            ;;
        npm)
            suggestions+=("n${words[1]:0:1}")
            suggestions+=("n${words[1]:0:2}")
            ;;
        yarn)
            suggestions+=("y${words[1]:0:1}")
            suggestions+=("y${words[1]:0:2}")
            ;;
        *)
            # Generic suggestions using initials
            local initials=""
            for word in "${words[@]:0:3}"; do
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
    
    # Set the alias in current session
    alias "$chosen_alias"="$command"
    
    # Save to alias file
    echo "alias $chosen_alias='$command'" >> "$alias_file"
    
    echo "✅ Alias created successfully!"
    echo ""
    echo "📌 New alias: $chosen_alias = '$command'"
    echo ""
    echo "💡 The alias is now active in your current session"
    echo "💡 To make it permanent, it's been added to: $alias_file"
    echo "💡 Make sure to source this file in your shell config"
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
