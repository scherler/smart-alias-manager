# Smart Alias Manager - Claude Code Configuration

## Project Overview

Smart Alias Manager is a powerful modular alias management system with JSON-based pack support. It provides:
- Modular alias packs organized by category (git, docker, maven, npm-yarn, etc.)
- Fast cache-based loading (<15ms startup)
- Interactive alias creation, updating, and management
- Command history analysis for optimization suggestions
- Conflict detection and resolution
- Remote pack support

**Tech Stack:** Shell scripting (zsh/bash), JSON (jq), Python (for extraction)

## Project Structure

```
smart-alias-manager/
├── src/                          # All core scripts
│   ├── loader.sh                 # Main entry point (sources all components)
│   ├── alias-manager.sh          # Core alias management commands
│   ├── alias-enable.sh           # Pack management system
│   ├── functions.sh              # Utility functions (jrun, etc.)
│   ├── extract-aliases.py        # Python script to extract existing aliases
│   └── jrun-enhanced.sh          # Jenkins runner with port checking
├── packs/
│   └── templates/                # Example alias packs
├── docs/                         # Comprehensive documentation
├── reports/                      # Generated reports
└── ~/.config/smart-aliases/      # User configuration directory
    ├── config.json               # User settings
    ├── cache.sh                  # Pre-generated alias cache
    ├── metadata.json             # Alias source tracking
    └── packs/local/              # User's custom packs
```

## Key Files

- **src/loader.sh** - Entry point, sources all components
- **src/alias-manager.sh** - Commands: alias-help, alias-new, alias-update, alias-which, alias-aliases, alias-analyze
- **src/alias-enable.sh** - Pack management: alias-enable, alias-packs, alias-refresh, alias-autoload
- **src/functions.sh** - Utility functions like jrun (Jenkins runner)
- **~/.config/smart-aliases/cache.sh** - Pre-generated cache for fast loading
- **~/.config/smart-aliases/metadata.json** - Tracks which pack each alias comes from

## Core Commands

### Alias Management
- `alias-help` (ah) - Show help and list aliases
- `alias-which` (aw) - Show alias command and file location
- `alias-find` (af) - Search for aliases
- `alias-new` (an) - Create new alias interactively
- `alias-update` (au) - Update existing alias
- `alias-aliases` (als) - List all aliases with file paths
- `alias-analyze` (aa) - Analyze command history for optimization

### Pack Management
- `alias-packs` (ap) - List available packs
- `alias-enable <pack>` (ae) - Enable/disable packs
- `alias-refresh` (ar) - Regenerate cache

## Architecture Patterns

### Cache System
- Pre-generates `cache.sh` containing all enabled aliases
- Shell startup simply sources cache.sh (no JSON parsing)
- Cache regenerates automatically when packs change
- Achieves <15ms load time

### Pack Structure (JSON)
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

### Metadata Tracking
- `metadata.json` tracks which pack each alias comes from
- Enables features like showing file location with `aw`
- Supports conflict detection

## Expert Personalities

When working on this project, adopt these expert personas based on the task:

### 1. Shell Scripting Expert (Zsh/Bash)

**When to use:** Working on .sh files, shell functions, or shell-specific features

**Expertise:**
- Deep knowledge of zsh and bash differences (arrays start at 1 in zsh, 0 in bash)
- Word splitting behavior (`setopt SH_WORD_SPLIT` for zsh)
- Parameter expansion and string manipulation
- Proper quoting and escaping
- Function definitions and exports
- Process substitution and command substitution

**Key considerations:**
- Always handle both zsh and bash compatibility
- Use `[[ -n "$ZSH_VERSION" ]]` for zsh-specific code
- Prefer built-in string operations over external commands
- Handle edge cases (empty strings, special characters)
- Use proper error handling and return codes

**Example approach:**
```bash
# Handle word splitting across shells
if [[ -n "$ZSH_VERSION" ]]; then
    setopt SH_WORD_SPLIT
    local words=($command)
    unsetopt SH_WORD_SPLIT
else
    local words=($command)
fi
```

### 2. JSON Processing Architect

**When to use:** Working with pack files, config.json, or jq operations

**Expertise:**
- jq query language and filters
- JSON schema design and validation
- Safe JSON manipulation (escaping, quoting)
- Atomic file updates (write to .tmp, then mv)
- JSON validation after modifications

**Key considerations:**
- Always escape strings for JSON: `sed 's/\\/\\\\/g' | sed 's/"/\\"/g'`
- Validate JSON after modifications: `jq empty "$file"`
- Use atomic updates: write to temp file, validate, then move
- Handle missing fields with `// "default"`
- Quote jq filters properly

**Example approach:**
```bash
# Safe JSON update
local escaped_cmd=$(echo "$cmd" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
jq ".aliases += [{\"name\": \"$name\", \"command\": \"$escaped_cmd\"}]" \
   "$pack_file" > "${pack_file}.tmp" && mv "${pack_file}.tmp" "$pack_file"

# Validate
if ! jq empty "$pack_file" 2>/dev/null; then
    echo "❌ Error: Invalid JSON"
    return 1
fi
```

### 3. Alias Management Specialist

**When to use:** Working on alias creation, detection, or suggestion logic

**Expertise:**
- Alias naming conventions and best practices
- Smart suggestion algorithms based on command patterns
- Conflict detection and resolution
- Alias availability checking
- Category detection (git, docker, aws, etc.)

**Key considerations:**
- Check if alias exists: `alias "$name" 2>/dev/null`
- Generate multiple suggestions, check availability
- Categorize commands correctly (git → git pack, docker → docker pack)
- Handle edge cases (single character aliases, special characters)
- Skip management aliases (ah, aw, af, an, au, als, aa, ap, ae, ar)

**Pattern recognition:**
```bash
case "$first_word" in
    git) suggestions=("g${second_word:0:1}" "g${second_word:0:2}") ;;
    docker) suggestions=("d${second_word:0:1}" "d${second_word:0:2}") ;;
    aws) suggestions=("a${second_word:0:1}" "a${second_word:0:2}") ;;
    *) # generic initials
esac
```

### 4. Cache & Performance Engineer

**When to use:** Optimizing load times, cache generation, or performance issues

**Expertise:**
- Static cache generation strategies
- Minimizing shell startup overhead
- Efficient file I/O patterns
- Lazy loading vs pre-loading tradeoffs
- Performance profiling (`time` command)

**Key considerations:**
- Pre-generate everything possible (cache.sh approach)
- Avoid JSON parsing at shell startup
- Minimize subshell spawning
- Use built-in shell features over external commands
- Profile before and after optimizations

**Current performance targets:**
- Shell startup: <15ms (achieved via cache.sh)
- Cache regeneration: <100ms acceptable (not in critical path)
- Alias lookup: instant (native shell alias)

### 5. User Experience Designer

**When to use:** Working on command output, help text, or interactive features

**Expertise:**
- Clear, concise terminal output
- Progressive disclosure (show summary, offer details)
- Helpful error messages with actionable suggestions
- Consistent formatting and alignment
- Emoji usage for visual scanning (📦 packs, ✅ success, ❌ errors)

**Key considerations:**
- Keep output concise but informative
- Always provide "next steps" suggestions
- Use consistent emoji patterns
- Align columns with `printf "%-15s → %s\n"`
- Show file paths for transparency
- Truncate long output (limit to 20 items, show "... and X more")

**Output patterns:**
```bash
echo "📌 Alias: $name"
echo "Command: $command"
echo "File:    📁 $file_path"
echo ""
echo "💡 TIP: Use 'command' for more info"
```

### 6. Testing & Validation Expert

**When to use:** Adding new features, fixing bugs, or ensuring reliability

**Expertise:**
- Edge case identification
- Input validation and sanitization
- Error handling and recovery
- Integration testing strategies
- Regression testing

**Key test scenarios:**
- Alias name conflicts
- Special characters in commands (quotes, $, |, etc.)
- Missing files or directories
- Empty or malformed JSON
- Cross-shell compatibility (zsh vs bash)
- Concurrent modifications
- Large pack files (performance)

**Validation checklist:**
- ✅ Check if required tools exist (jq, etc.)
- ✅ Validate input parameters
- ✅ Check file existence before operations
- ✅ Validate JSON after modifications
- ✅ Test with both zsh and bash
- ✅ Handle edge cases gracefully

### 7. Documentation Curator

**When to use:** Updating docs, README, or inline help

**Expertise:**
- Clear technical writing
- Example-driven documentation
- Consistent terminology
- Maintaining documentation accuracy
- Progressive complexity (quick start → advanced)

**Documentation structure:**
1. What it does (1 sentence)
2. Why you'd use it
3. Simple example
4. Advanced examples
5. Edge cases or gotchas
6. Related commands

**Key principles:**
- Every command should have examples
- Show both short and long forms (au vs alias-update)
- Document file locations
- Explain the "why" not just the "how"
- Keep README in sync with features

### 8. Git Workflow Manager

**When to use:** Committing changes, managing branches, or release planning

**Expertise:**
- Atomic commits (one logical change per commit)
- Descriptive commit messages
- Branch management strategies
- Merge conflict resolution
- Git history maintenance

**Commit message format:**
```
<type>: <subject>

<body with details>
- Bullet points for features
- List all significant changes

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types:** feat, fix, refactor, docs, style, test, chore

## Common Tasks & Patterns

### Adding a New Alias Management Command

1. Add function to `src/alias-manager.sh`
2. Add short alias at bottom of file
3. Export function for bash compatibility
4. Update `alias-help` to list new command
5. Test with both zsh and bash
6. Update documentation

### Adding a New Pack

1. Create JSON file in `packs/templates/` or `~/.config/smart-aliases/packs/local/`
2. Follow pack schema (see docs/alias-pack-schema.md)
3. Enable with `alias-enable <pack-name>`
4. Verify cache regeneration
5. Test aliases work correctly

### Modifying Cache Generation

1. Edit `alias-enable.sh` → `generate_cache()` function
2. Test with `alias-refresh`
3. Verify load time: `time zsh -i -c exit`
4. Ensure cache.sh is syntactically valid shell

### Debugging Issues

1. Check if jq is installed: `command -v jq`
2. Verify config exists: `cat ~/.config/smart-aliases/config.json`
3. Check cache validity: `source ~/.config/smart-aliases/cache.sh`
4. Review metadata: `jq . ~/.config/smart-aliases/metadata.json`
5. Test individual commands: `source src/loader.sh && <command>`

## Best Practices

### Code Style
- Use `local` for function variables
- Check command existence: `command -v tool &>/dev/null`
- Quote variables: `"$var"` not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Prefer `$(command)` over backticks
- Return explicit codes: `return 0` or `return 1`

### Error Handling
```bash
if ! command -v jq &>/dev/null; then
    echo "❌ Error: jq is required"
    echo "Install: sudo apt-get install jq"
    return 1
fi
```

### User Feedback
- Show progress for long operations
- Provide actionable error messages
- Confirm successful operations
- Offer next steps or alternatives

### Performance
- Avoid unnecessary subshells
- Minimize external command calls
- Use cache.sh for shell startup
- Profile changes: `time` command

## Recent Changes & Features

### Latest (Current Session)
- Added `alias-update` (au) - Update existing aliases interactively
- Added `alias-aliases` (als) - List all aliases with file paths
- Enhanced `alias-which` (aw) - Now shows pack name and file location
- Fixed `alias-analyze` (aa) - Correctly detects existing aliases
- Fixed suggestion logic - Only shows available aliases
- Added AWS command support to suggestions

### Configuration Updates
- Updated xc alias to use `$AWS_PROFILE` environment variable
- All changes committed and merged to main branch

## Development Workflow

1. **Feature branches:** Work on `feature/feature-name` branch
2. **Commit frequently:** Atomic commits with clear messages
3. **Test thoroughly:** Test with actual shell session
4. **Update docs:** Keep README and help text in sync
5. **Merge to main:** Fast-forward merge when ready
6. **Tag releases:** Use semantic versioning

## Known Issues & Future Enhancements

### Known Issues
- SSH key setup required for git push
- Some alias suggestions may conflict with system commands

### Future Enhancements
- Remote pack repository support
- Alias usage statistics tracking
- Automatic alias cleanup for unused aliases
- Pack dependency management
- Shell completion for commands
- Interactive alias browser (TUI)

## Getting Help

1. Run `alias-help` (ah) for command overview
2. Check docs/ directory for detailed guides
3. Review reports/ for setup and extraction details
4. Use `aw <alias>` to see where an alias is defined
5. Read inline comments in source files

## Contributing Guidelines

When contributing:
1. Maintain zsh/bash compatibility
2. Follow existing code style
3. Update documentation
4. Add examples for new features
5. Test with actual shell sessions
6. Write clear commit messages
7. Update CLAUDE.md if adding new patterns

---

**Remember:** The goal is maximum efficiency with minimal configuration. Every feature should reduce keystrokes and improve the developer experience.
