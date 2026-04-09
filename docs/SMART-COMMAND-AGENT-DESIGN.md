# Smart Command Agent - Design Document

## Overview

An intelligent command interceptor that analyzes commands before execution, proposes alias optimizations, and learns from user patterns.

## User Flow

```
User types: docker ps -a | grep running
           ↓
Agent intercepts (command > 8 chars, not starting with alias)
           ↓
Analyze with smart-alias-manager
           ↓
Propose: "💡 Alias suggestion: dps='docker ps -a | grep running'"
         "[1] Create alias 'dps' and use it"
         "[2] Just run command"
         "[3] Never suggest for this pattern"
           ↓
User presses: 1, 2, or 3
           ↓
Execute accordingly
```

## Design Principles

### 1. Non-Intrusive
- Only analyze commands > 8 characters
- Skip if command starts with known alias
- User can disable globally or per-pattern
- Zero latency for simple commands

### 2. Smart Detection

**Skip analysis if:**
- Command length ≤ 8 chars (e.g., `ls -la`, `ys`, `yb`)
- Starts with known alias (check cache.sh)
- Matches skip patterns (configured by user)
- Contains sensitive data (passwords, tokens)

**Analyze if:**
- Command > 8 chars AND not an alias
- Repeats frequently (seen 3+ times in history)
- Complex pipeline or long options

### 3. Learning System
- Track command frequency
- Suggest aliases for frequently repeated commands
- Learn from user rejections (never suggest again)
- Improve suggestions based on acceptance rate

## Architecture

### Components

```
┌─────────────────────────────────────────────────┐
│           Shell Hook (preexec)                  │
│  - Intercepts command before execution          │
│  - Checks eligibility for analysis              │
└─────────────────┬───────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────┐
│         Command Analyzer                        │
│  - Check if alias exists                        │
│  - Generate suggestions                         │
│  - Check frequency in history                   │
└─────────────────┬───────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────┐
│         Suggestion Engine                       │
│  - Rank suggestions by quality                  │
│  - Check availability                           │
│  - Format for display                           │
└─────────────────┬───────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────┐
│         Interactive Prompt                      │
│  - Show suggestion(s)                           │
│  - Get user choice (1/2/3)                      │
│  - Execute accordingly                          │
└─────────────────────────────────────────────────┘
```

### File Structure

```
src/
├── agent-mode.sh              # Main agent logic
├── command-interceptor.sh     # Shell hook integration
├── suggestion-engine.sh       # Suggestion generation
└── learning-tracker.sh        # Track patterns and rejections

~/.config/smart-aliases/
├── agent-config.json          # Agent settings
├── command-patterns.json      # Learned patterns
├── rejections.json            # Never suggest again
└── stats.json                 # Usage statistics
```

## Implementation Details

### 1. Shell Hook Integration

**For Zsh:**
```bash
# In ~/.zshrc after sourcing smart-aliases
if [[ "$SMART_ALIAS_AGENT" == "enabled" ]]; then
    preexec_functions+=(smart_alias_agent_hook)
fi
```

**For Bash:**
```bash
# In ~/.bashrc after sourcing smart-aliases
if [[ "$SMART_ALIAS_AGENT" == "enabled" ]]; then
    trap 'smart_alias_agent_hook "$BASH_COMMAND"' DEBUG
fi
```

### 2. Eligibility Check

```bash
smart_alias_agent_hook() {
    local cmd="$1"

    # Skip if disabled
    [[ "$SMART_ALIAS_AGENT" != "enabled" ]] && return 0

    # Skip if command too short
    [[ ${#cmd} -le 8 ]] && return 0

    # Skip if starts with known alias
    local first_word="${cmd%% *}"
    if alias "$first_word" &>/dev/null; then
        return 0
    fi

    # Skip if in skip list
    if is_skipped_pattern "$cmd"; then
        return 0
    fi

    # Skip sensitive patterns (contains password, token, etc.)
    if [[ "$cmd" =~ (password|token|secret|key) ]]; then
        return 0
    fi

    # Analyze command
    analyze_and_suggest "$cmd"
}
```

### 3. Analysis Logic

```bash
analyze_and_suggest() {
    local cmd="$1"

    # Check if alias already exists
    local existing_alias=$(alias_which_exact "$cmd")
    if [[ -n "$existing_alias" ]]; then
        echo "💡 Alias exists: $existing_alias → $cmd"
        return 0
    fi

    # Check frequency in history
    local frequency=$(count_in_history "$cmd")

    # Only suggest if seen multiple times
    if [[ $frequency -lt 3 ]]; then
        # Track for future
        record_command "$cmd"
        return 0
    fi

    # Generate suggestions
    local suggestions=$(generate_suggestions "$cmd")

    # Show interactive prompt
    show_suggestion_prompt "$cmd" "$suggestions"
}
```

### 4. Interactive Prompt

```bash
show_suggestion_prompt() {
    local cmd="$1"
    local suggestions="$2"

    echo ""
    echo "💡 Smart Alias Suggestion"
    echo "─────────────────────────"
    echo "Command: $cmd"
    echo ""
    echo "Suggestions:"

    local idx=1
    while IFS= read -r suggestion; do
        echo "  [$idx] Create alias: $suggestion"
        ((idx++))
    done <<< "$suggestions"

    echo "  [$idx] Just run command"
    ((idx++))
    echo "  [$idx] Never suggest for this pattern"
    echo ""

    # Read user choice with timeout
    local choice
    read -t 5 -p "Choose [1-$idx] (5s timeout): " choice || choice=$((idx-1))

    case "$choice" in
        1)
            # Create first suggestion and use it
            local alias_name="${suggestions%%=*}"
            create_alias_and_execute "$alias_name" "$cmd"
            ;;
        $((idx-1)))
            # Just run
            ;;
        $idx)
            # Never suggest again
            add_to_rejections "$cmd"
            ;;
    esac
}
```

### 5. Learning & Statistics

**command-patterns.json:**
```json
{
  "patterns": [
    {
      "command": "docker ps -a | grep running",
      "count": 5,
      "first_seen": "2025-11-08T20:00:00Z",
      "last_seen": "2025-11-08T23:00:00Z",
      "suggested": false
    }
  ]
}
```

**rejections.json:**
```json
{
  "rejections": [
    {
      "pattern": "git log --oneline --graph",
      "rejected_at": "2025-11-08T22:00:00Z",
      "reason": "user_choice"
    }
  ]
}
```

**stats.json:**
```json
{
  "total_suggestions": 15,
  "accepted": 10,
  "rejected": 3,
  "ignored": 2,
  "acceptance_rate": 0.67,
  "top_patterns": [
    {"command": "docker ps -a", "count": 12},
    {"command": "kubectl get pods", "count": 8}
  ]
}
```

## Configuration

### Agent Config (~/.config/smart-aliases/agent-config.json)

```json
{
  "enabled": true,
  "min_command_length": 8,
  "min_frequency": 3,
  "prompt_timeout": 5,
  "skip_patterns": [
    "^cd ",
    "^ls ",
    "^cat ",
    "^echo "
  ],
  "sensitive_keywords": [
    "password",
    "token",
    "secret",
    "key",
    "api_key"
  ],
  "suggestion_limit": 3
}
```

### Enable/Disable

```bash
# Enable agent mode
export SMART_ALIAS_AGENT=enabled

# Disable agent mode
export SMART_ALIAS_AGENT=disabled

# Or use command
alias-agent-enable    # Enable
alias-agent-disable   # Disable
alias-agent-status    # Show status
```

## Commands

### New Commands

```bash
alias-agent-enable (aae)     # Enable agent mode
alias-agent-disable (aad)    # Disable agent mode
alias-agent-status (aas)     # Show status and stats
alias-agent-stats (aast)     # Show detailed statistics
alias-agent-config (aac)     # Edit agent config
alias-agent-clear (aacl)     # Clear learned patterns
```

### Integration with Existing Commands

```bash
# alias-analyze (aa) - Enhanced
aa                           # Show suggestions + agent stats
aa --patterns               # Show learned patterns
aa --rejections             # Show rejected patterns

# alias-new (an) - Enhanced
an                          # Interactive creation (existing)
an --from-pattern <cmd>     # Create from learned pattern
```

## Performance Considerations

### 1. Fast Path for Simple Commands
```bash
# No overhead for:
- Commands ≤ 8 chars
- Known aliases
- Skip patterns

# Minimal overhead (~5-10ms) for:
- Eligibility check
- Alias lookup
- Pattern matching
```

### 2. Async Processing
```bash
# Don't block command execution
- Record command in background
- Update stats asynchronously
- Analyze patterns in idle time
```

### 3. Cache Optimization
```bash
# Cache alias lookups
- Load all aliases once at startup
- Check in-memory hash table
- No disk I/O per command
```

## Edge Cases

### 1. Command Starting with Alias
```bash
# User types: ys something extra
# Action: Skip analysis (starts with alias 'ys')
```

### 2. Very Long Command
```bash
# User types: 200 character command
# Action: Analyze, but suggest abbreviation not full replacement
```

### 3. Command with Secrets
```bash
# User types: curl -H "Authorization: Bearer token123"
# Action: Skip analysis (contains sensitive keyword)
```

### 4. Rapid Typing
```bash
# User types multiple commands quickly
# Action: Queue analysis, don't interrupt flow
```

## Security & Privacy

### 1. Sensitive Data Protection
- Never log commands containing: password, token, secret, key
- Never suggest aliases for sensitive patterns
- Clear text storage (no obfuscation needed for local files)

### 2. User Control
- Easy enable/disable
- Per-pattern rejection
- Clear rejection list
- Export/import settings

## Future Enhancements

### Phase 1 (MVP)
- [x] Design document
- [ ] Basic hook implementation
- [ ] Eligibility checking
- [ ] Simple suggestion engine
- [ ] Interactive prompt

### Phase 2
- [ ] Learning system
- [ ] Statistics tracking
- [ ] Pattern analysis
- [ ] Smart suggestions based on frequency

### Phase 3
- [ ] Machine learning suggestions
- [ ] Context-aware suggestions (pwd, git repo, etc.)
- [ ] Suggestion sharing (opt-in)
- [ ] Integration with oh-my-zsh/prezto

### Phase 4
- [ ] AI-powered suggestions (local LLM)
- [ ] Natural language alias names
- [ ] Automatic pack suggestions
- [ ] Team alias sharing

## Testing Strategy

### Unit Tests
- Eligibility checking logic
- Pattern matching
- Suggestion generation
- Statistics calculation

### Integration Tests
- Shell hook integration (zsh/bash)
- End-to-end command flow
- Config loading/saving
- Stats persistence

### Performance Tests
- Hook overhead measurement
- Cache effectiveness
- Large history handling
- Concurrent command processing

## Rollout Plan

### Step 1: Opt-in Alpha
- Disabled by default
- Early adopter testing
- Gather feedback

### Step 2: Refinement
- Fix bugs from alpha
- Improve suggestions
- Optimize performance

### Step 3: Opt-out Beta
- Enabled by default (with easy disable)
- Broader user base
- Collect statistics (anonymized)

### Step 4: GA Release
- Stable, well-tested
- Documentation complete
- Migration guide for existing users

## Success Metrics

- Acceptance rate > 60%
- Average time saved > 5 seconds per session
- Zero latency impact for simple commands
- User satisfaction > 4/5

---

**Status**: Design phase
**Next Steps**: Review with user, implement MVP
**Estimated Effort**: 3-4 weeks for Phase 1

