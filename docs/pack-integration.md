# Integrating Alias Packs with Your Shell

## Quick Integration

### 1. Source the alias-enable Script

Add to your `~/.zshrc`:

```bash
# Smart Alias Manager - Pack System
if [[ -f ~/.config/smart-aliases/alias-enable.sh ]]; then
    source ~/.config/smart-aliases/alias-enable.sh

    # Auto-load enabled packs on shell startup
    alias-autoload
fi
```

### 2. Copy Template Packs

```bash
# Create directories
mkdir -p ~/.config/smart-aliases/packs/{local,community}

# Copy templates
cp /src/smart-alias-manager/packs/templates/*.json ~/.config/smart-aliases/packs/local/

# Copy alias-enable script
cp /src/smart-alias-manager/src/alias-enable.sh ~/.config/smart-aliases/
```

### 3. Install jq

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Check installation
jq --version
```

### 4. Reload Shell

```bash
source ~/.zshrc
# or
,.
```

### 5. Enable Your First Pack

```bash
# Enable git essentials
alias-enable git-essentials

# Verify
alias-enable --list
```

## Integration with cb-alias Plugin

If you're using the cb-alias oh-my-zsh plugin:

### Option 1: Add to Plugin File

Edit `/src/thor/zsh/plugins/cb-alias/cb-alias.plugin.zsh`:

```bash
currentDir=$(dirname ${0})
source $currentDir/export.sh
source $currentDir/hash.sh
autoload -U zmv
source $currentDir/alias-optimized.sh

# Load alias pack system
if [[ -f ~/.config/smart-aliases/alias-enable.sh ]]; then
    source ~/.config/smart-aliases/alias-enable.sh
    alias-autoload
fi
```

### Option 2: Add to .zshrc After Plugin

In your `~/.zshrc`, after oh-my-zsh initialization:

```bash
# Oh My Zsh configuration
plugins=(cb-alias ...)
source $ZSH/oh-my-zsh.sh

# Alias Pack System (after plugins load)
if [[ -f ~/.config/smart-aliases/alias-enable.sh ]]; then
    source ~/.config/smart-aliases/alias-enable.sh
    alias-autoload
fi
```

## Automated Setup Script

Create `~/.config/smart-aliases/setup-packs.sh`:

```bash
#!/bin/bash

echo "🚀 Setting up Smart Alias Manager Pack System..."

# Create directories
mkdir -p ~/.config/smart-aliases/packs/{local,community,cache}

# Copy scripts
if [[ -f /src/smart-alias-manager/src/alias-enable.sh ]]; then
    cp /src/smart-alias-manager/src/alias-enable.sh ~/.config/smart-aliases/
    echo "✅ Copied alias-enable script"
fi

# Copy template packs
if [[ -d /src/smart-alias-manager/packs/templates ]]; then
    cp /src/smart-alias-manager/packs/templates/*.json ~/.config/smart-aliases/packs/local/
    echo "✅ Copied template packs"
fi

# Check jq installation
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found. Install with:"
    echo "   Ubuntu/Debian: sudo apt-get install jq"
    echo "   macOS: brew install jq"
else
    echo "✅ jq is installed"
fi

# Add to .zshrc if not present
if ! grep -q "alias-enable.sh" ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "# Smart Alias Manager - Pack System" >> ~/.zshrc
    echo "if [[ -f ~/.config/smart-aliases/alias-enable.sh ]]; then" >> ~/.zshrc
    echo "    source ~/.config/smart-aliases/alias-enable.sh" >> ~/.zshrc
    echo "    alias-autoload" >> ~/.zshrc
    echo "fi" >> ~/.zshrc
    echo "✅ Added to .zshrc"
else
    echo "✅ Already in .zshrc"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Reload shell: source ~/.zshrc"
echo "  2. Enable a pack: alias-enable git-essentials"
echo "  3. List enabled: alias-enable --list"
```

Then run:
```bash
chmod +x ~/.config/smart-aliases/setup-packs.sh
~/.config/smart-aliases/setup-packs.sh
```

## Testing the Integration

```bash
# 1. Verify alias-enable is available
type alias-enable

# 2. Check help
alias-enable --help

# 3. List available packs
ls ~/.config/smart-aliases/packs/local/

# 4. Enable a pack
alias-enable git-essentials

# 5. Test an alias
gs  # Should show git status

# 6. List enabled packs
alias-enable --list

# 7. Show pack info
alias-enable --info git-essentials
```

## Workflow Example

### Day 1: Setup

```bash
# Install and setup
~/.config/smart-aliases/setup-packs.sh
source ~/.zshrc

# Enable essential packs
alias-enable git-essentials
alias-enable docker-essentials
```

### Day 2: Add Custom Pack

```bash
# Create custom pack
cat > ~/.config/smart-aliases/packs/local/my-work.json <<EOF
{
  "name": "my-work",
  "version": "1.0.0",
  "author": "Me",
  "description": "Work-specific aliases",
  "aliases": [
    {
      "name": "deploy",
      "type": "alias",
      "command": "./deploy.sh production",
      "description": "Deploy to production",
      "category": "work"
    }
  ]
}
EOF

# Enable it
alias-enable my-work

# Test it
deploy
```

### Day 3: Share with Team

```bash
# Push your pack to GitHub
cd ~/.config/smart-aliases/packs/local
git init
git add my-work.json
git commit -m "Add work aliases"
git push origin main

# Share with team
# Team members can now run:
# alias-enable https://raw.githubusercontent.com/you/repo/main/my-work.json
```

## Troubleshooting Integration

### Issue: alias-enable not found

**Solution**: Check sourcing order

```bash
# Add debug output to .zshrc
echo "Loading alias-enable from: ~/.config/smart-aliases/alias-enable.sh"
source ~/.config/smart-aliases/alias-enable.sh
echo "alias-enable loaded successfully"
```

### Issue: Aliases not loading

**Solution**: Check auto-load

```bash
# Manually load packs
alias-autoload

# Check enabled packs
cat ~/.config/smart-aliases/enabled-packs.json
```

### Issue: Packs override existing aliases

**Solution**: Load packs before core aliases

```bash
# In .zshrc, load packs first
source ~/.config/smart-aliases/alias-enable.sh
alias-autoload

# Then load main aliases
source /path/to/alias-optimized.sh
```

## Performance Considerations

### Lazy Loading

For faster shell startup, lazy load packs:

```bash
# In .zshrc
alias-enable() {
    unfunction alias-enable  # Remove this wrapper
    source ~/.config/smart-aliases/alias-enable.sh
    alias-enable "$@"  # Call real function
}
```

### Selective Loading

Only load packs you need:

```bash
# Instead of auto-loading all
# alias-autoload

# Load specific packs
alias-enable git-essentials
alias-enable docker-essentials
```

## Next Steps

1. **Create Your First Pack**: See [packs/README.md](../packs/README.md)
2. **Explore Templates**: Check `packs/templates/` for examples
3. **Share Packs**: Create a GitHub repo with your packs
4. **Join Community**: Share your packs with others!

---

**Type less, do more! 🚀**
