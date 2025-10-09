# 🚀 Smart Alias Manager

**A powerful modular alias management system with JSON-based pack support**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/scherler/smart-alias-manager)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-zsh-orange.svg)](https://github.com/scherler/smart-alias-manager)

## ✨ Features

- **📦 Modular Packs**: Organize aliases in shareable JSON packs
- **🔄 Auto-Loading**: Automatically load enabled packs on shell startup
- **⚡ Lightning Fast**: <15ms startup with static cache system
- **🛡️ Conflict Detection**: Smart conflict resolution with suggestions
- **🌐 Remote Packs**: Load alias packs from URLs
- **⚡ Enhanced jrun**: Jenkins runner with smart port checking
- **🎯 Efficiency First**: 80%+ keystroke reduction
- **📊 Analytics**: Built-in efficiency reporting and tracking
- **🔍 Smart Search**: Find and manage aliases easily

## 🎬 Quick Start

```bash
# Clone the repository
git clone https://github.com/scherler/smart-alias-manager.git /src/smart-alias-manager

# Add to your ~/.zshrc (just 2 lines!)
[[ -f /src/smart-alias-manager/src/loader.sh ]] && source /src/smart-alias-manager/src/loader.sh

# Reload shell
source ~/.zshrc

# Start using
alias-packs             # List all available packs
alias-enable git        # Enable the git pack
gs                      # git status (from git pack)
```

## 📦 Installation

### Prerequisites

```bash
# Install jq (required for pack management)
sudo apt-get install jq    # Ubuntu/Debian
brew install jq            # macOS
```

### Automatic Setup

1. **Clone repository**:
   ```bash
   git clone https://github.com/scherler/smart-alias-manager.git /src/smart-alias-manager
   ```

2. **Add to shell** (add to `~/.zshrc`):
   ```bash
   # Smart Alias Manager - Load alias packs and functions
   [[ -f /src/smart-alias-manager/src/loader.sh ]] && source /src/smart-alias-manager/src/loader.sh
   ```

3. **Create config** (automatic on first run):
   ```bash
   # Config created at: ~/.config/smart-aliases/config.json
   ```

4. **Extract your existing aliases**:
   ```bash
   python3 /src/smart-alias-manager/src/extract-aliases.py
   ```

That's it! Just **2 lines in .zshrc** for complete setup.

## 🎯 Core Concepts

### Alias Packs

Organize your aliases into modular JSON packs:

```json
{
  "name": "git-essentials",
  "version": "1.0.0",
  "description": "Essential Git shortcuts",
  "aliases": [
    {
      "name": "gs",
      "command": "git status",
      "description": "Show git status"
    }
  ]
}
```

### Configuration

Single config file at `~/.config/smart-aliases/config.json`:

```json
{
  "enabled_packs": [
    "git",
    "maven",
    "docker"
  ],
  "settings": {
    "auto_load": true,
    "show_loading_messages": true
  }
}
```

## 🔧 Command Reference

### Pack Management

| Command | Shortcut | Description |
|---------|----------|-------------|
| `alias-packs` | `ap` | List all available packs (enabled/disabled) |
| `alias-enable <pack>` | `ae` | Enable a pack with conflict detection |
| `alias-enable --disable <pack>` | | Disable a pack |
| `alias-enable --info <pack>` | | Show detailed pack information |
| `alias-enable --list` | | List only enabled packs |
| `alias-enable --search <query>` | | Search for packs by name/description |
| `alias-enable --conflicts` | | Show conflict history |
| `alias-refresh` | `ar` | Regenerate alias cache (fast reload) |

### Creating Aliases

```bash
alias-new <command> [description]   # Create new alias interactively
```

**Features**:
- ✅ Smart category detection (git, docker, maven, npm-yarn, etc.)
- ✅ Intelligent alias name suggestions
- ✅ Automatic JSON pack integration
- ✅ Duplicate detection and overwrite protection

**Examples**:
```bash
# Create git alias
alias-new "git status -v" "Verbose git status"
# Suggests: gs, gst, gsv

# Create docker alias
alias-new "docker ps -a" "List all containers"
# Suggests: dp, dps, dpa

# Create custom alias
alias-new "kubectl get pods --all-namespaces"
# Suggests: kgp, kg, kge
```

The new alias is saved to the appropriate JSON pack (`extracted-git.json`, `extracted-docker.json`, etc.) and immediately available in your current session.

### Enhanced jrun

```bash
jrun                    # Interactive mode
jrun core-oc            # Run specific product
jrun 9090 core-cm       # Custom port
jrun -a core-oc         # Auto-find available port
jrun -j core-oc         # Java mode (java -jar)
jrun --help             # Show all options
```

**Features**:
- ✅ Port checking (prevents bind exceptions)
- ✅ Auto-find available port
- ✅ Maven (`mvn hpi:run`) or Java (`java -jar`) modes
- ✅ Interactive product selection
- ✅ Clear status output

## 📖 Documentation

### Getting Started
- **[Installation & Setup](docs/pack-integration.md)** - Detailed installation guide
- **[Alias Packs Guide](docs/packs.md)** - Creating and using alias packs
- **[jrun Usage](docs/jrun-usage.md)** - Enhanced Jenkins runner guide

### Reference
- **[JSON Pack Schema](docs/alias-pack-schema.md)** - Pack file format specification

### Reports
- **[Efficiency Report](reports/efficiency-report.md)** - Your current efficiency metrics
- **[Extraction Report](reports/EXTRACTION-COMPLETE.md)** - Alias extraction results
- **[Setup Report](reports/SETUP-COMPLETE.md)** - Installation completion summary
- **[Cleanup Report](reports/CLEANUP-COMPLETE.md)** - Structure cleanup details
- **[Feature Overview](reports/ALIAS-PACKS-FEATURE.md)** - Complete feature documentation

## 📁 Project Structure

```
smart-alias-manager/
├── src/                      # All scripts
│   ├── loader.sh            # Main entry point
│   ├── alias-enable.sh      # Pack manager
│   ├── functions.sh         # Core functions (jrun, etc.)
│   ├── extract-aliases.py   # Extract aliases to packs
│   └── install.sh           # Installation script
├── docs/                     # Documentation
│   ├── packs.md             # Pack usage guide
│   ├── jrun-usage.md        # jrun documentation
│   ├── alias-pack-schema.md # JSON schema
│   └── pack-integration.md  # Setup guide
├── reports/                  # Generated reports
│   ├── efficiency-report.md
│   ├── EXTRACTION-COMPLETE.md
│   └── SETUP-COMPLETE.md
├── packs/
│   └── templates/           # Example packs
│       ├── git-essentials.json
│       ├── docker-essentials.json
│       └── maven-jenkins.json
├── examples/
│   └── sample-aliases.sh    # Example configurations
├── LICENSE
└── README.md                # This file
```

### User Configuration

```
~/.config/smart-aliases/
├── config.json              # Your configuration
├── cache.sh                 # Pre-generated alias cache (auto-generated)
├── metadata.json            # Alias source tracking
├── conflicts.log            # Conflict resolution history
└── packs/
    ├── local/               # Your custom packs
    ├── community/           # Downloaded packs
    └── cache/               # Cached remote packs
```

## 🚀 Usage Examples

### Enable Packs

```bash
# List all available packs with status
alias-packs  # or: ap

# Enable a pack
alias-enable git  # or: ae git

# Show pack details
alias-enable --info git

# List only enabled packs
alias-enable --list

# Refresh cache after manual changes
alias-refresh  # or: ar
```

### Create Custom Pack

```bash
# Create pack file
cat > ~/.config/smart-aliases/packs/local/my-aliases.json <<'EOF'
{
  "name": "my-aliases",
  "version": "1.0.0",
  "description": "My personal shortcuts",
  "aliases": [
    {
      "name": "deploy",
      "command": "./deploy.sh production",
      "description": "Deploy to production"
    }
  ]
}
EOF

# Enable it
alias-enable my-aliases
```

### Load Pack from URL

```bash
# Load from GitHub
alias-enable https://raw.githubusercontent.com/user/repo/main/pack.json

# Reload all packs
alias-enable --reload
```

### Use Enhanced jrun

```bash
# Interactive selection
jrun

# With port checking
jrun core-oc
# ⚠️  Port 8080 is already in use!
# 💡 Options:
#    1. Stop the process using port 8080
#    2. Try a different port: jrun <port> [product]
#    3. Auto-find available port: jrun -a 8080 [product]

# Auto-find available port
jrun -a core-oc
# ✅ Found available port: 8081
# 🚀 Starting Jenkins on port 8081
```

## 📊 Efficiency Metrics

**Your Current Stats** (from extraction):

- **104 aliases** organized into 8 packs
- **6 core functions** (jrun, docker-cleanup, etc.)
- **~82% keystroke reduction**
- **~15,540 keystrokes saved per week**
- **~40 hours saved per year**

See [efficiency report](reports/efficiency-report.md) for details.

## ⚡ Performance & Optimization

### Lightning-Fast Startup

The system uses a **static cache** approach for instant shell startup:

- **Pre-generated cache**: All aliases are pre-computed into `cache.sh`
- **Zero parsing**: No JSON parsing at startup
- **<15ms load time**: Typical startup in 13-15 milliseconds
- **Auto-regeneration**: Cache updates automatically when packs change

**How it works**:
1. When you enable/disable packs, the cache is regenerated
2. Shell startup simply sources the pre-generated `cache.sh` file
3. Use `alias-refresh` to manually rebuild the cache if needed

### Conflict Detection

Smart conflict resolution protects your existing aliases:

```bash
# Example conflict scenario
alias-enable docker  # You already have a custom 'dkc' alias

# System detects conflict:
⚠️  CONFLICTS DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The following aliases in 'docker' conflict with existing aliases:

  ❌ dkc
     Current (custom): docker compose
     New     (docker): docker system prune

     💡 Suggested alternatives:
        - dkc2 (available)
        - dkcp (available)

Options:
  1. Skip - Don't load conflicting aliases (safe)
  2. Override - Replace existing aliases with new ones
  3. Cancel - Don't enable this pack

Choose [1/2/3] (default: 1):
```

**Features**:
- Detects command differences (not just name conflicts)
- Suggests alternative names
- Logs all conflicts to `~/.config/smart-aliases/conflicts.log`
- View history with `alias-enable --conflicts`

## 🎯 Best Practices

1. **Organize by Category**: Create separate packs for git, docker, maven, etc.
2. **Use Descriptive Names**: Clear pack and alias names
3. **Document Everything**: Add descriptions to all aliases
4. **Version Control**: Keep your custom packs in git
5. **Share with Team**: Host packs on GitHub for team use
6. **Regular Updates**: Run extraction periodically to update packs

## 🐛 Troubleshooting

### Common Issues

**jq not installed**
```bash
sudo apt-get install jq  # Ubuntu/Debian
brew install jq          # macOS
```

**Packs not loading**
```bash
# Check config
cat ~/.config/smart-aliases/config.json

# Reload shell
source ~/.zshrc

# Check for errors
alias-enable --list
```

**Aliases not working**
```bash
# Verify alias loaded
type gs

# Reload packs
alias-enable --reload
```

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Contributing Packs

Share your alias packs:
1. Create pack in JSON format
2. Test thoroughly
3. Submit PR or share URL
4. Add to community directory

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for maximum efficiency and minimal configuration
- Inspired by modular package management systems
- Powered by jq for JSON processing

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/scherler/smart-alias-manager/issues)
- **Documentation**: See [docs/](docs/) directory
- **Reports**: See [reports/](reports/) directory

---

**Remember**: Every keystroke saved is a moment earned. Type less, do more! 🚀
