# Alias Packs

## Overview

Alias packs are shareable, modular collections of aliases and functions that extend your shell environment. They enable:

- **Modularity**: Organize aliases by tool or workflow
- **Shareability**: Import packs from URLs or GitHub
- **Versioning**: Track versions and updates
- **Flexibility**: Enable/disable packs as needed

## Quick Start

### 1. Install jq (required)

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Fedora
sudo dnf install jq
```

### 2. Enable Your First Pack

```bash
# Copy templates to local packs directory
cp templates/*.json ~/.config/smart-aliases/packs/local/

# Enable git essentials
alias-enable git-essentials
```

### 3. Verify It Worked

```bash
# List enabled packs
alias-enable --list

# Test an alias
gs  # Should show git status
```

## Directory Structure

```
~/.config/smart-aliases/
├── config.json                 # Main configuration
├── enabled-packs.json          # List of enabled packs
└── packs/
    ├── local/                  # Your custom packs
    │   ├── my-aliases.json
    │   └── work-helpers.json
    ├── community/              # Downloaded community packs
    │   ├── git-essentials.json
    │   ├── docker-essentials.json
    │   └── maven-jenkins.json
    └── cache/                  # Cached remote packs
        └── [url-hash].json
```

## Available Template Packs

### git-essentials.json
**19 aliases** for Git productivity
- `gs` → git status
- `gaa` → git add --all
- `gcm` → git commit -m
- `gfa` → git fetch --all
- And more...

### docker-essentials.json
**8 aliases + 1 function** for Docker management
- `dps` → docker ps
- `dka` → kill all containers
- `docker-cleanup` → complete cleanup function

### maven-jenkins.json
**8 aliases + 1 function** for Maven/Jenkins dev
- `mics` → mvn clean install -DskipTests
- `mr` → mvn hpi:run
- `xx` → debug test function

## Usage

### Enable a Pack

```bash
# Enable local pack
alias-enable git-essentials

# Enable from URL
alias-enable https://raw.githubusercontent.com/user/repo/main/pack.json

# Enable from GitHub (shorthand coming soon)
alias-enable github:user/repo/aliases.json
```

### List Enabled Packs

```bash
alias-enable --list
# or
alias-enable -l
```

Output:
```
📋 Enabled Alias Packs:

  ✓ git-essentials (v1.0.0)
    Essential Git aliases for maximum productivity

  ✓ docker-essentials (v1.0.0)
    Docker shortcuts and container management
```

### Show Pack Info

```bash
alias-enable --info git-essentials
```

Output:
```
📦 Pack Information
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name:        git-essentials
Version:     1.0.0
Author:      Smart Alias Manager
License:     MIT
Description: Essential Git aliases for maximum productivity

Contents:    19 aliases, 0 functions

Aliases:
  g → git
  gs → git status
  gaa → git add --all
  ...
```

### Disable a Pack

```bash
alias-enable --disable git-essentials
```

### Search for Packs

```bash
alias-enable --search docker
```

### Reload All Packs

```bash
alias-enable --reload
```

## Creating Custom Packs

### Method 1: Copy a Template

```bash
cd ~/.config/smart-aliases/packs/local
cp ../templates/git-essentials.json my-custom-git.json

# Edit with your favorite editor
vim my-custom-git.json

# Enable it
alias-enable my-custom-git
```

### Method 2: Create from Scratch

Create `~/.config/smart-aliases/packs/local/my-pack.json`:

```json
{
  "name": "my-pack",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "My personal aliases",
  "license": "MIT",
  "tags": ["custom", "personal"],
  "requires": {
    "commands": ["git", "docker"]
  },
  "aliases": [
    {
      "name": "gp",
      "type": "alias",
      "command": "git push",
      "description": "Push to remote",
      "category": "git",
      "enabled": true
    }
  ],
  "functions": [
    {
      "name": "my-function",
      "body": "echo 'Hello from my function'",
      "description": "Example function",
      "category": "custom"
    }
  ]
}
```

Then enable:
```bash
alias-enable my-pack
```

## Pack JSON Schema

See [alias-pack-schema.md](../docs/alias-pack-schema.md) for complete schema documentation.

### Minimal Pack

```json
{
  "name": "minimal-pack",
  "version": "1.0.0",
  "author": "Me",
  "description": "Minimal example",
  "aliases": [
    {
      "name": "hi",
      "type": "alias",
      "command": "echo 'Hello!'",
      "description": "Say hello",
      "category": "fun"
    }
  ]
}
```

## Sharing Packs

### Via GitHub

1. Create a repository
2. Add your pack JSON file
3. Share the raw GitHub URL:

```bash
alias-enable https://raw.githubusercontent.com/yourusername/your-repo/main/my-pack.json
```

### Via Gist

1. Create a GitHub Gist with your pack JSON
2. Get the raw URL
3. Share it:

```bash
alias-enable https://gist.githubusercontent.com/user/id/raw/pack.json
```

### Via Your Own Server

Host the JSON file anywhere and share the URL:

```bash
alias-enable https://yoursite.com/packs/awesome-aliases.json
```

## Best Practices

### 1. Organize by Tool/Workflow

Create separate packs for different tools:
- `git-personal.json` - Your Git workflow
- `docker-dev.json` - Docker development
- `work-specific.json` - Work-related aliases

### 2. Use Descriptive Names

Good:
- `git-essentials`
- `docker-cleanup`
- `maven-jenkins-dev`

Bad:
- `pack1`
- `aliases`
- `stuff`

### 3. Document Everything

Always include:
- Clear descriptions for each alias
- Author information
- Version numbers
- Tags for searchability

### 4. Check for Conflicts

Use the `conflicts` field:
```json
{
  "name": "p",
  "command": "git push",
  "conflicts": ["python", "perl"]
}
```

### 5. Version Your Packs

Follow semantic versioning:
- `1.0.0` - Initial release
- `1.1.0` - Add new aliases (minor)
- `2.0.0` - Breaking changes (major)

## Troubleshooting

### Pack Won't Load

```bash
# Check if jq is installed
jq --version

# Validate JSON syntax
jq empty ~/.config/smart-aliases/packs/local/my-pack.json

# Check pack info
alias-enable --info my-pack
```

### Alias Not Working

```bash
# Reload packs
alias-enable --reload

# Or reload shell config
,.

# Check if alias exists
type my-alias
```

### Conflict with Existing Alias

```bash
# Check what an alias currently does
type gs

# Disable conflicting pack
alias-enable --disable conflicting-pack

# Or unalias manually
unalias gs
```

## Integration with Smart Alias Manager

Packs work seamlessly with existing Smart Alias Manager commands:

```bash
# Find aliases from packs
alias-find docker

# Show alias expansion
alias-which dps

# Get help on any alias
alias-help gs
```

## Advanced Usage

### Conditional Loading

Create environment-specific packs:

```bash
# ~/.config/smart-aliases/packs/local/work.json
# Only enable at work

if [[ "$WORK_ENV" == "true" ]]; then
    alias-enable work
fi
```

### Dynamic Packs from Environment

```bash
# Load pack based on project
if [[ -f ./.alias-pack.json ]]; then
    alias-enable ./.alias-pack.json
fi
```

### Pack Collections

Create meta-packs that reference other packs:

```json
{
  "name": "full-stack-dev",
  "dependencies": [
    "git-essentials",
    "docker-essentials",
    "node-dev",
    "python-dev"
  ]
}
```

## Contributing

Want to contribute packs?

1. Create your pack following the schema
2. Test thoroughly
3. Submit to community collection
4. Share the URL!

## Examples in the Wild

Coming soon: Community pack registry at:
`https://smart-alias-manager.github.io/packs/`

---

**Type less, do more! 🚀**
