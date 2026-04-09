# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Alias Manager is a modular shell alias management system with JSON-based packs and an intelligent agent mode that learns from command usage patterns.

**Tech Stack:** Shell (zsh/bash), JSON (jq), Python (for extraction)

**Key Features:**
- Modular JSON-based alias packs with conflict detection
- Cache-based loading (<15ms startup)
- Agent mode: Command interceptor that learns patterns and suggests aliases
- Cross-shell compatibility (zsh and bash)

## Project Structure

```
src/
├── loader.sh              # Entry point - sources all components
├── alias-manager.sh       # Core commands: alias-new, alias-update, alias-which, etc.
├── alias-enable.sh        # Pack management: enable/disable/refresh
├── functions.sh           # Utility functions (jrun, port checking)
├── command-interceptor.sh # Agent mode: preexec hook for command interception
├── agent-commands.sh      # Agent commands: enable/disable/stats
└── extract-aliases.py     # Extract existing aliases to JSON packs

~/.config/smart-aliases/   # User config (created on first run)
├── config.json            # Enabled packs and settings
├── cache.sh               # Pre-generated alias cache (auto-generated)
├── metadata.json          # Alias source tracking
├── agent-config.json      # Agent mode configuration
└── packs/local/           # User's custom packs
```

## Essential Commands

### Development & Testing

```bash
# Load the system in a test shell
source src/loader.sh

# Test individual functions
source src/alias-manager.sh && alias-help

# Test pack loading
source src/alias-enable.sh && alias-packs

# Regenerate cache (after modifying packs)
alias-refresh

# Validate JSON pack structure
jq empty packs/templates/git-essentials.json
```

### Testing Shell Compatibility

**CRITICAL:** All changes must work in both zsh and bash.

```bash
# Test in zsh
zsh -c "source src/loader.sh && alias-new 'git status'"

# Test in bash
bash -c "source src/loader.sh && alias-new 'git status'"
```

**Key differences to handle:**
- Array indexing: zsh starts at 1, bash starts at 0
- Word splitting: zsh requires `setopt SH_WORD_SPLIT`
- Use `[[ -n "$ZSH_VERSION" ]]` for zsh-specific code
- Test both shells for every PR

### User Commands (for reference)

```bash
# Alias management
alias-help (ah)           # List all commands
alias-new (an)            # Create new alias interactively
alias-which (aw)          # Show alias command and source
alias-analyze (aa)        # Analyze history for suggestions

# Pack management
alias-packs (ap)          # List available packs
alias-enable <pack> (ae)  # Enable/disable packs
alias-refresh (ar)        # Regenerate cache

# Agent mode (learning mode)
alias-agent-enable (aae)  # Enable command learning
alias-agent-status (aas)  # Show agent status
alias-agent-stats (aast)  # Show learning statistics
```

## Critical Architecture Patterns

### 1. Cache System (Performance-Critical)

**How it works:**
1. JSON packs are parsed once during `alias-enable` or `alias-refresh`
2. All enabled aliases are pre-generated into `~/.config/smart-aliases/cache.sh`
3. Shell startup sources `cache.sh` directly (no JSON parsing)
4. Achieves <15ms load time

**Implementation:** `src/alias-enable.sh` → `generate_cache()` function

**When modifying:**
- Test cache generation: `alias-refresh && cat ~/.config/smart-aliases/cache.sh`
- Verify syntax: `zsh -n ~/.config/smart-aliases/cache.sh`
- Profile load time: `time zsh -i -c exit`

### 2. Agent Mode (Command Interception)

**Architecture:**
- Uses zsh's `preexec_functions` hook to intercept commands before execution
- Tracks command patterns in `~/.config/smart-aliases/command-patterns.json`
- Analyzes frequency and suggests aliases for commands seen 3+ times
- Also detects when user types long form of existing aliases

**Key files:**
- `src/command-interceptor.sh` - Hook implementation
- `src/agent-commands.sh` - User-facing commands (enable/disable/stats)

**How it works:**
1. `preexec` hook fires before each command
2. Command is analyzed (length, frequency, existing aliases)
3. If eligible, prompt user to create alias (5s timeout)
4. Stats tracked in `agent-stats.json`

**Critical behavior:**
- Skips commands <8 chars, sensitive keywords, or already aliased
- Zero overhead for short commands (early return)
- Respects user rejections (stored in `rejections.json`)

**Initialize:** Automatic via `loader.sh` → `smart_alias_agent_init()`

### 3. JSON Pack Schema

```json
{
  "name": "git",
  "version": "1.0.0",
  "description": "Git shortcuts",
  "aliases": [
    {
      "name": "gs",
      "type": "alias",
      "command": "git status",
      "description": "Show git status",
      "category": "git",
      "enabled": true
    }
  ]
}
```

**Validation:** Always run `jq empty <file>` after modifications

### 4. Metadata Tracking

`metadata.json` tracks which pack each alias came from, enabling:
- `alias-which <name>` to show source file
- Conflict detection across packs
- Selective pack disable (removes only that pack's aliases)

## Shell Compatibility Requirements

### Zsh-Specific Code Patterns

```bash
# Array access (zsh is 1-indexed)
if [[ -n "$ZSH_VERSION" ]]; then
    first="${array[1]}"
else
    first="${array[0]}"
fi

# Word splitting
if [[ -n "$ZSH_VERSION" ]]; then
    setopt SH_WORD_SPLIT
    words=($command)
    unsetopt SH_WORD_SPLIT
else
    words=($command)
fi
```

### Function Exports (Bash Compatibility)

```bash
# Define function
my_function() {
    echo "hello"
}

# Export for bash (no-op in zsh)
if [[ -z "$ZSH_VERSION" ]]; then
    export -f my_function
fi
```

## Common Development Tasks

### Adding a New Alias Management Command

1. Add function to `src/alias-manager.sh`
2. Add short alias at bottom of file: `alias an='alias-new'`
3. Export for bash: `[[ -z "$ZSH_VERSION" ]] && export -f alias-new`
4. Update `alias-help` function to document it
5. Test in both zsh and bash
6. Update this CLAUDE.md if non-obvious

### Modifying Cache Generation

1. Edit `src/alias-enable.sh` → `generate_cache()` function
2. Test: `alias-refresh && source ~/.config/smart-aliases/cache.sh`
3. Verify all aliases work: `type <alias-name>`
4. Profile: `time zsh -i -c exit` (should be <15ms)

### Adding Agent Mode Features

1. Hook logic: `src/command-interceptor.sh` → `smart_alias_agent_hook()`
2. Config schema: `smart_alias_agent_create_default_config()`
3. Stats tracking: Update `agent-stats.json` structure
4. Test: `aae` (enable), type commands, verify suggestions appear

## Code Style & Safety

### Required Patterns

```bash
# Check command exists before use
if ! command -v jq &>/dev/null; then
    echo "❌ Error: jq is required"
    return 1
fi

# Atomic JSON updates (validate before overwrite)
jq '.field = "value"' file.json > file.json.tmp
if jq empty file.json.tmp 2>/dev/null; then
    mv file.json.tmp file.json
else
    echo "❌ Invalid JSON"
    rm file.json.tmp
    return 1
fi

# Local variables in functions
my_function() {
    local var1="value"
    local var2="value"
}

# Use [[ ]] for conditions, quote variables
if [[ -n "$var" && -f "$file" ]]; then
    echo "Valid"
fi
```

### Alias Name Validation

Use `validate_alias_name()` from `src/alias-manager.sh` to prevent:
- Shell special characters (`$|&;<>(){}[]'"` etc.)
- Shell keywords (if, then, for, etc.)
- Starting with `-` or digits
- Empty strings, `.`, `..`

## Debugging

```bash
# Check configuration
cat ~/.config/smart-aliases/config.json

# Verify cache
cat ~/.config/smart-aliases/cache.sh | grep "alias gs"

# Check metadata
jq . ~/.config/smart-aliases/metadata.json

# View agent stats
jq . ~/.config/smart-aliases/agent-stats.json

# Agent debug logs
tail -f /tmp/smart-alias-debug.log

# Test individual functions
source src/loader.sh && alias-which gs
```

## Testing Strategy

**Manual testing approach:**
1. Source `loader.sh` in test shell
2. Run command and verify output
3. Check generated files (`cache.sh`, `metadata.json`, etc.)
4. Test edge cases (special characters, missing files, etc.)
5. Test in both zsh and bash

**Integration testing:**
1. Fresh shell: `zsh -i` or `bash -i`
2. Verify aliases loaded: `type <alias>`
3. Test pack enable/disable cycle
4. Test agent mode (if enabled)

## Known Patterns & Conventions

### Emoji Usage

- 📦 Packs
- ✅ Success
- ❌ Error
- ⚠️ Warning
- 💡 Tip/Suggestion
- 🚀 Starting/Running
- 📁 File path

### Function Naming

- `alias-*` - User-facing commands (exported, aliased)
- `smart_alias_*` - Internal functions (not exported)
- Snake_case for internal, kebab-case for user commands

### File Locations

- User config: `~/.config/smart-aliases/`
- Project packs: `packs/templates/`
- User packs: `~/.config/smart-aliases/packs/local/`
- Cache: `~/.config/smart-aliases/cache.sh` (auto-generated)

## Dependencies

**Required:**
- `jq` - JSON processing (all pack operations)
- `zsh` or `bash` - Shell environment

**Optional:**
- `python3` - For `extract-aliases.py` (one-time extraction)
- `lsof` or `nc` - For port checking in `jrun` function

## Documentation

- `README.md` - User-facing documentation
- `docs/AGENT-MODE-README.md` - Agent mode quick start
- `docs/SMART-COMMAND-AGENT-DESIGN.md` - Agent architecture
- `docs/alias-pack-schema.md` - JSON schema reference
- `reports/` - Generated reports (efficiency, setup, etc.)

---

**Key Principle:** Maximum efficiency with minimal configuration. Every feature should reduce keystrokes and improve developer experience.
