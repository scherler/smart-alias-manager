# Smart Alias Agent Mode - Quick Start

## What is Agent Mode?

Agent Mode is an intelligent command interceptor that learns from your shell usage and suggests aliases for frequently repeated commands. It runs in the background and only activates for commands longer than 8 characters that aren't already aliased.

## Quick Start

### 1. Enable Agent Mode

```bash
aae    # or: alias-agent-enable
```

### 2. Use Your Shell Normally

The agent silently learns from your commands. When you type a command 3+ times, it will offer to create an alias:

```bash
$ docker ps -a | grep running
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Smart Alias Suggestion
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Command: docker ps -a | grep running

Suggestions:
  [1] Create alias: dps='docker ps -a | grep running'
  [2] Just run command
  [3] Never suggest for this pattern

Choose [1-3] (5s timeout):
```

### 3. Make Your Choice

- Press `1` - Create the alias and use it
- Press `2` - Just run the command this time
- Press `3` - Never suggest for this pattern again
- Wait 5s - Auto-runs the command

## Key Features

### Smart Detection

✅ **Alias Enforcement (Always Active):**
- Detects when you type long form of a command that has a short alias
- Example: Type `yarn` → Agent suggests using `y` instead
- Works for any command length
- Instant reminder, no frequency tracking needed

✅ **New Alias Creation (For Long Commands):**
- Commands longer than 8 characters
- Not starting with an existing alias
- Seen 3+ times in your usage

❌ **Skipped:**
- Short commands (`ls`, `cd`, `ys`)
- Commands starting with aliases
- Sensitive commands (containing password, token, etc.)
- Patterns you've rejected

### Zero Impact

- No overhead for short commands or aliases
- 5-second timeout (auto-runs if ignored)
- Async learning in background
- Disabled by default

### Privacy Safe

- All data stored locally in `~/.config/smart-aliases/`
- No network requests
- No command logging for sensitive keywords
- You control what gets suggested

## Commands

```bash
# Enable/Disable
aae                # Enable agent mode
aad                # Disable agent mode

# Status & Stats
aas                # Show current status
aast               # Show detailed statistics

# Configuration
aac                # Edit configuration
aacl               # Clear all learned patterns

# Help
ah                 # Show all commands
```

## Configuration

Edit agent settings:

```bash
aac                # Opens ~/.config/smart-aliases/agent-config.json
```

Key settings:
- `min_command_length`: Minimum chars to analyze (default: 8)
- `min_frequency`: How many times before suggesting (default: 3)
- `prompt_timeout`: Seconds before auto-run (default: 5)
- `skip_patterns`: Commands to never analyze
- `sensitive_keywords`: Words that trigger skip

## Examples

### Example 1: Alias Enforcement (Use Existing Short Alias)

```bash
# You type:
$ yarn

# Agent reminds you:
💡 Alias suggestion: Use 'y' instead of 'yarn'
   (saves 3 characters)

# Next time use:
$ y
```

This works for all your existing aliases: `yarn`→`y`, `yarn start`→`ys`, `yarn build`→`yb`, etc.

### Example 2: Creating New Alias (Docker Command)

```bash
# You type this 3 times:
$ docker ps -a | grep running

# Agent suggests:
💡 Create alias: dps='docker ps -a | grep running'

# You accept, now you can use:
$ dps
```

### Example 3: Git Log

```bash
# You type this repeatedly:
$ git log --oneline --graph --decorate

# Agent suggests:
💡 Create alias: glg='git log --oneline --graph --decorate'

# You accept and use:
$ glg
```

### Example 4: kubectl

```bash
# You type often:
$ kubectl get pods --namespace=production

# Agent suggests:
💡 Create alias: kgp='kubectl get pods --namespace=production'
```

## View Your Stats

See what the agent has learned:

```bash
$ aast
Smart Alias Agent - Detailed Statistics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Overall Statistics
  Total suggestions shown: 15
  Accepted (created alias): 10
  Rejected (never show): 2
  Ignored (just ran): 3
  Acceptance rate: 67%

📝 Learned Patterns: 47
Top 5 frequent commands:
  12x: docker ps -a
  8x: kubectl get pods
  7x: git log --oneline --graph
  5x: find . -name "*.js"
  4x: npm run build && npm start

🤖 Agent-Created Aliases: 10
  dps = docker ps -a
  kgp = kubectl get pods
  glg = git log --oneline --graph
  ...
```

## Files & Storage

All agent data is stored in:

```bash
~/.config/smart-aliases/
├── agent-config.json          # Settings
├── command-patterns.json      # Learned commands & frequency
├── rejections.json            # Never-suggest-again list
├── agent-stats.json           # Statistics
└── packs/local/
    └── agent-created.json     # Auto-created aliases
```

## FAQ

### Q: Will it slow down my shell?

No! Short commands and existing aliases have zero overhead. Only commands >8 chars that aren't aliases get analyzed (~5-10ms).

### Q: What if I don't want a suggestion?

Press `3` to never see it again, or just wait 5 seconds and it auto-runs.

### Q: Can I disable it temporarily?

```bash
aad    # Disable
aae    # Re-enable later
```

### Q: What happens to auto-created aliases?

They're saved in `~/.config/smart-aliases/packs/local/agent-created.json` and loaded like any other alias pack. You can edit or delete them with standard alias commands.

### Q: Does it track sensitive commands?

No! Commands containing `password`, `token`, `secret`, `key`, etc. are automatically skipped.

### Q: Can I customize what gets skipped?

Yes! Edit config with `aac` and modify `skip_patterns` and `sensitive_keywords`.

## Disable Agent Mode

```bash
aad    # Disable agent mode

# Or edit config:
aac
# Set "enabled": false
```

## Troubleshooting

### Agent not working?

1. Check if enabled: `aas`
2. Verify jq installed: `command -v jq`
3. Check shell: `echo $ZSH_VERSION` (must be zsh currently)

### Want to reset everything?

```bash
aacl    # Clear all learned patterns (keeps agent-created aliases)
```

### Want to delete all agent-created aliases?

```bash
rm ~/.config/smart-aliases/packs/local/agent-created.json
alias-refresh
```

## Tips

1. **Start with it disabled** - Learn smart-alias-manager first, then enable agent mode
2. **Review your stats** - Run `aast` weekly to see what's being suggested
3. **Customize skip patterns** - Add your frequently-typed-but-don't-want-aliased commands
4. **Accept good suggestions** - The agent learns your acceptance rate and adapts

## Next Steps

- Read the full design doc: `docs/SMART-COMMAND-AGENT-DESIGN.md`
- Enable agent mode: `aae`
- Use your shell normally
- Watch the magic happen!

---

**Requires:** zsh, jq
**Status:** MVP (v1.0)
**Feedback:** Create an issue or discussion
