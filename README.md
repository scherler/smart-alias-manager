# 🚀 Smart Alias Manager

**A powerful shell alias management system with AI-enhanced suggestions**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/yourusername/smart-alias-manager)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-orange.svg)](https://github.com/yourusername/smart-alias-manager)

## ✨ Features

- **🤖 AI-Powered Suggestions**: Smart 2-3 letter alias recommendations based on command patterns
- **📊 Command Analysis**: Analyze your shell history to identify optimization opportunities
- **🔍 Intelligent Search**: Find existing aliases quickly with keyword search
- **⚡ Interactive Creation**: Create new aliases with smart, conflict-free suggestions
- **📚 Self-Documenting**: Built-in help system for all your aliases
- **🎯 Efficiency First**: Following the "type less, do more" philosophy

## 🎬 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/smart-alias-manager.git
cd smart-alias-manager

# Install
./install.sh

# Start using
ah          # Show help
an 'git status'  # Create new alias
af git      # Find git aliases
aa          # Analyze your command usage
```

## 📦 Installation

### Automatic Installation

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/smart-alias-manager/main/install.sh | bash
```

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/smart-alias-manager.git ~/.smart-alias-manager
```

2. Add to your shell configuration (`~/.bashrc`, `~/.zshrc`, etc.):
```bash
# Smart Alias Manager
source ~/.smart-alias-manager/src/alias-manager.sh
```

3. Reload your shell:
```bash
source ~/.bashrc  # or ~/.zshrc
```

## 🔧 Core Commands

All commands have short 2-letter aliases for maximum efficiency:

| Command | Alias | Description |
|---------|-------|-------------|
| `alias-help` | `ah` | Show help and list aliases |
| `alias-new` | `an` | Create new alias interactively |
| `alias-find` | `af` | Search for aliases by keyword |
| `alias-which` | `aw` | Show command expansion |
| `alias-analyze` | `aa` | Analyze command history |

## 📖 Usage Examples

### Creating a New Alias

```bash
$ an 'docker ps -a'
📝 Creating alias for: docker ps -a

💡 Suggested aliases (based on command pattern):
  ✅ dp (available)
  ✅ dps (available)
  ❌ da (taken: 'docker attach')
  📝 Or enter a custom alias name

Choose alias name: dpa
✅ Alias created successfully!

📌 New alias: dpa = 'docker ps -a'
```

### Finding Aliases

```bash
$ af git
🔍 Searching for aliases containing 'git'...

  📌 g = 'git'
  📌 gs = 'git status'
  📌 ga = 'git add'
  📌 gc = 'git commit'
  📌 gp = 'git push'
```

### Analyzing Command Usage

```bash
$ aa
📊 Analyzing Command History...
================================

🔝 Top 20 Most Used Commands:
  47× git status ⚠️ (no alias)
  23× docker ps -a ⚠️ (no alias)
  19× kubectl get pods ✅ (aliased)
  ...

💡 OPTIMIZATION SUGGESTIONS:

📝 Long commands that could benefit from aliases:
  12× git commit -m "update"
     → Suggested alias: gcm
  8× docker-compose up -d
     → Suggested alias: dcu
```

## 🤝 Claude AI Integration

This project includes Claude configuration for enhanced alias suggestions. When using with Claude:

1. Claude can analyze your command patterns
2. Suggest optimal 2-3 letter aliases
3. Learn from your workflow to propose custom aliases
4. Generate category-specific alias sets

### Using with Claude

```bash
# Ask Claude to optimize your aliases
"Claude, analyze my shell history and suggest optimal aliases"

# Get suggestions for specific workflows
"Claude, create aliases for my Kubernetes workflow" 

# Learn from patterns
"Claude, what are my most used git commands without aliases?"
```

## 🎯 Optimization Philosophy

### The "Type Less, Do More" Principle

- **1 letter**: Reserved for most frequent base commands (g=git, d=docker)
- **2 letters**: Common operations (gs=git status, dp=docker ps)
- **3 letters**: Specific frequent tasks (gaa=git add --all)
- **4+ letters**: Complex or dangerous operations

### Best Practices

1. **Keep it Short**: Aim for 2-3 character aliases
2. **Be Consistent**: Use patterns (g* for git, d* for docker)
3. **Document Well**: Add descriptions to complex aliases
4. **Avoid Conflicts**: Check existing aliases before creating
5. **Regular Analysis**: Run `aa` weekly to find optimization opportunities

## 📁 Project Structure

```
smart-alias-manager/
├── src/
│   ├── alias-manager.sh    # Core functions
│   └── alias-analyzer.sh   # Analysis utilities
├── examples/
│   └── sample-aliases.sh    # Example configurations
├── templates/
│   ├── git-aliases.sh       # Git workflow aliases
│   ├── docker-aliases.sh    # Docker aliases
│   └── k8s-aliases.sh       # Kubernetes aliases
├── docs/
│   └── USAGE.md            # Detailed documentation
├── install.sh              # Installation script
└── .claude.json           # Claude AI configuration
```

## 🚀 Advanced Features

### Custom Alias Storage

```bash
# Set custom alias file location
export ALIAS_CONFIG_FILE="$HOME/.config/aliases/my-aliases.sh"
```

### Batch Alias Creation

```bash
# Create multiple aliases from history
aa | grep "no alias" | while read line; do
  cmd=$(echo $line | sed 's/.*× //' | sed 's/ ⚠️.*//')
  an "$cmd"
done
```

### Export/Import Aliases

```bash
# Export current aliases
alias > my-aliases-backup.sh

# Import aliases
source my-aliases-backup.sh
```

## 🤖 AI-Enhanced Features

The Claude integration provides:

- **Pattern Recognition**: Identifies your command usage patterns
- **Smart Suggestions**: Context-aware alias recommendations
- **Workflow Optimization**: Creates cohesive alias sets for specific tasks
- **Conflict Resolution**: Prevents and resolves alias conflicts
- **Learning Mode**: Improves suggestions based on your usage

## 📊 Statistics

Track your efficiency gains:

```bash
# Before optimization
Average keystrokes per command: 28

# After optimization with aliases
Average keystrokes per command: 4

# Efficiency gain: 85.7%
```

## 🐛 Troubleshooting

### Common Issues

**Aliases not persisting across sessions**
- Ensure you've added `source ~/.smart-alias-manager/src/alias-manager.sh` to your shell config

**Command not found errors**
- Check that functions are exported: `export -f alias-help`

**Conflicts with existing aliases**
- Use `af <name>` to check for conflicts before creating

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the efficiency principles of vim and tmux
- Built with the power of Claude AI
- Thanks to all contributors and users

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/smart-alias-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/smart-alias-manager/discussions)
- **Email**: your.email@example.com

---

**Remember**: Every keystroke saved is a moment earned. Type less, do more! 🚀
