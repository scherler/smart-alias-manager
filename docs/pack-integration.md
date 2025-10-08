# Integrating Smart Alias Manager with Your Shell

This guide shows how to integrate the Smart Alias Manager pack system into your shell environment.

## Quick Installation

The easiest way to install is using the provided install script:

```bash
# Clone repository
git clone https://github.com/scherler/smart-alias-manager.git /src/smart-alias-manager

# Run installer
cd /src/smart-alias-manager
./src/install.sh
```

The installer will:
- ✅ Check for dependencies (jq)
- ✅ Create config directory structure
- ✅ Generate config.json
- ✅ Add 2-line integration to your shell config
- ✅ Set up pack directories with .gitignore protection

## Manual Installation

If you prefer manual setup:

### 1. Create Directory Structure

```bash
mkdir -p ~/.config/smart-aliases/packs/{local,community,cache}
```

### 2. Create config.json

```bash
cat > ~/.config/smart-aliases/config.json <<'EOF'
{
  "version": "1.0.0",
  "enabled_packs": [],
  "settings": {
    "auto_load": true,
    "show_loading_messages": true,
    "check_requirements": true,
    "allow_url_packs": true
  }
}
EOF
```

### 3. Add to Shell Config

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Smart Alias Manager - Load alias packs and functions
[[ -f /src/smart-alias-manager/src/loader.sh ]] && source /src/smart-alias-manager/src/loader.sh
```

That's it! Just **2 lines** for complete integration.

### 4. Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install jq python3

# macOS
brew install jq python3

# Verify
jq --version
python3 --version
```

### 5. Reload Shell

```bash
source ~/.zshrc
# or for bash
source ~/.bashrc
```

## Extract Your Existing Aliases

If you have existing aliases, extract them to JSON packs:

```bash
# Auto-detect alias file
python3 /src/smart-alias-manager/src/extract-aliases.py

# Or specify source file
python3 /src/smart-alias-manager/src/extract-aliases.py ~/.zshrc

# Or specify both source and output
python3 /src/smart-alias-manager/src/extract-aliases.py /path/to/aliases.sh /output/dir
```

This will create JSON packs in `~/.config/smart-aliases/packs/local/`.

## Enable Packs

```bash
# List available packs
ls ~/.config/smart-aliases/packs/local/

# Enable a pack
alias-enable extracted-git

# List enabled packs
alias-enable --list

# Show pack details
alias-enable --info extracted-git
```

## Integration Examples

### With Oh My Zsh

Add after oh-my-zsh initialization in `~/.zshrc`:

```bash
# Oh My Zsh
plugins=(git docker kubectl ...)
source $ZSH/oh-my-zsh.sh

# Smart Alias Manager - Load alias packs and functions
[[ -f /src/smart-alias-manager/src/loader.sh ]] && source /src/smart-alias-manager/src/loader.sh
```

### With Custom Plugin Structure

If you have a custom plugin directory:

```bash
# Your custom plugins
for plugin in ~/.zsh/plugins/*/*.plugin.zsh; do
    source "$plugin"
done

# Smart Alias Manager - Load alias packs and functions
[[ -f /src/smart-alias-manager/src/loader.sh ]] && source /src/smart-alias-manager/src/loader.sh
```

### Bash Integration

Add to `~/.bashrc`:

```bash
# Smart Alias Manager - Load alias packs and functions
if [ -f /src/smart-alias-manager/src/loader.sh ]; then
    source /src/smart-alias-manager/src/loader.sh
fi
```

## Configuration

### Customize Pack Loading

Edit `~/.config/smart-aliases/config.json`:

```json
{
  "version": "1.0.0",
  "enabled_packs": [
    "extracted-git",
    "extracted-docker",
    "my-custom-pack"
  ],
  "settings": {
    "auto_load": true,
    "show_loading_messages": false,
    "check_requirements": true,
    "allow_url_packs": true
  }
}
```

**Settings:**
- `auto_load`: Automatically load enabled packs on shell startup
- `show_loading_messages`: Show "📦 Loading pack..." messages
- `check_requirements`: Validate pack requirements before loading
- `allow_url_packs`: Allow loading packs from URLs

### Silent Loading

To hide loading messages:

```json
{
  "settings": {
    "show_loading_messages": false
  }
}
```

## Creating Custom Packs

### 1. Create Pack File

Create `~/.config/smart-aliases/packs/local/my-pack.json`:

```json
{
  "name": "my-pack",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "My personal aliases",
  "license": "MIT",
  "tags": ["personal", "work"],
  "requires": {
    "zsh": ">=5.0"
  },
  "aliases": [
    {
      "name": "deploy",
      "type": "alias",
      "command": "./deploy.sh production",
      "description": "Deploy to production",
      "category": "work",
      "enabled": true
    }
  ]
}
```

### 2. Enable Your Pack

```bash
alias-enable my-pack
```

### 3. Reload

```bash
alias-enable --reload
# or
source ~/.zshrc
```

## Loading Packs from URLs

Share packs across teams:

```bash
# Load from GitHub
alias-enable https://raw.githubusercontent.com/user/repo/main/pack.json

# Pack is cached in ~/.config/smart-aliases/packs/cache/
```

## Troubleshooting

### Packs Not Loading

```bash
# Check config
cat ~/.config/smart-aliases/config.json

# Check if loader.sh is sourced
type alias-enable

# Reload shell
source ~/.zshrc

# Check for errors
alias-enable --list
```

### jq Errors

```bash
# Validate pack JSON
jq empty ~/.config/smart-aliases/packs/local/*.json

# If errors, regenerate packs
python3 /src/smart-alias-manager/src/extract-aliases.py
```

### Commands Not Found

```bash
# Verify loader.sh location
ls -la /src/smart-alias-manager/src/loader.sh

# Check if path is correct in .zshrc
grep "loader.sh" ~/.zshrc

# Make sure you've reloaded
source ~/.zshrc
```

## Advanced Usage

### Conditional Loading

Load different packs based on hostname:

```bash
# In ~/.zshrc, before loader.sh
if [[ "$(hostname)" == "work-laptop" ]]; then
    # Configure for work
    jq '.enabled_packs = ["work-aliases", "git", "docker"]' \
        ~/.config/smart-aliases/config.json > tmp && \
        mv tmp ~/.config/smart-aliases/config.json
fi

# Smart Alias Manager - Load alias packs and functions
[[ -f /src/smart-alias-manager/src/loader.sh ]] && source /src/smart-alias-manager/src/loader.sh
```

### Performance Optimization

For faster shell startup, disable loading messages:

```bash
# Edit config.json
jq '.settings.show_loading_messages = false' \
    ~/.config/smart-aliases/config.json > tmp && \
    mv tmp ~/.config/smart-aliases/config.json
```

### Generate Efficiency Report

Track your alias usage:

```bash
# Generate report
/src/smart-alias-manager/src/generate-efficiency-report.sh

# View report
cat ~/.config/smart-aliases/efficiency-report.md
```

## Migration from Old Setup

If you were using the old manual copy approach:

### 1. Remove Old Files

```bash
# Remove manually copied scripts
rm ~/.config/smart-aliases/alias-enable.sh
rm ~/.config/smart-aliases/functions.sh
rm ~/.config/smart-aliases/setup-packs.sh
```

### 2. Update .zshrc

Replace old configuration:

```bash
# OLD (remove this)
if [[ -f ~/.config/smart-aliases/alias-enable.sh ]]; then
    source ~/.config/smart-aliases/alias-enable.sh
    alias-autoload
fi

# NEW (use this)
[[ -f /src/smart-alias-manager/src/loader.sh ]] && source /src/smart-alias-manager/src/loader.sh
```

### 3. Reload

```bash
source ~/.zshrc
```

## Next Steps

- 📖 Read [Alias Pack Guide](packs.md)
- 📋 Review [JSON Schema](alias-pack-schema.md)
- 🚀 Check [jrun Usage](jrun-usage.md)
- 💡 Create your first alias with `alias-new`

---

*For more information, see the [main README](../README.md)*
