# Alias Pack JSON Schema

## Overview

Alias packs are JSON files that define reusable sets of aliases and functions that can be shared, versioned, and dynamically loaded.

## Schema Structure

```json
{
  "name": "string",
  "version": "string (semver)",
  "author": "string",
  "description": "string",
  "repository": "string (optional)",
  "homepage": "string (optional)",
  "license": "string (optional)",
  "tags": ["array", "of", "strings"],
  "requires": {
    "zsh": ">=5.0",
    "commands": ["git", "docker"]
  },
  "aliases": [
    {
      "name": "string",
      "type": "alias|function|global",
      "command": "string (for aliases)",
      "body": "string (for functions)",
      "description": "string",
      "category": "string",
      "enabled": true,
      "conflicts": ["array of conflicting alias names"]
    }
  ],
  "functions": [
    {
      "name": "string",
      "body": "multiline string",
      "description": "string",
      "category": "string",
      "dependencies": ["other function names"]
    }
  ]
}
```

## Field Descriptions

### Pack Metadata

- **name**: Unique identifier for the pack (e.g., "git-aliases", "docker-essentials")
- **version**: Semantic version (e.g., "1.0.0")
- **author**: Author name or email
- **description**: Brief description of what aliases this pack provides
- **repository**: Optional Git repository URL
- **homepage**: Optional documentation URL
- **license**: License identifier (e.g., "MIT")
- **tags**: Keywords for searching (e.g., ["git", "productivity"])

### Requirements

- **requires.zsh**: Minimum zsh version (e.g., ">=5.0")
- **requires.commands**: Array of required commands that must be installed

### Alias Definition

- **name**: Alias name (e.g., "gs", "gaa")
- **type**: One of:
  - `alias`: Standard alias
  - `function`: Shell function
  - `global`: Global alias (expands anywhere in command line)
- **command**: The command string for aliases
- **body**: The function body for functions
- **description**: Human-readable description
- **category**: Grouping category (e.g., "git", "docker", "system")
- **enabled**: Whether this alias is enabled by default (default: true)
- **conflicts**: Array of alias names that conflict (will warn on load)

## Example: Git Essentials Pack

```json
{
  "name": "git-essentials",
  "version": "1.0.0",
  "author": "Smart Alias Manager",
  "description": "Essential Git aliases for maximum productivity",
  "license": "MIT",
  "tags": ["git", "vcs", "productivity"],
  "requires": {
    "zsh": ">=5.0",
    "commands": ["git"]
  },
  "aliases": [
    {
      "name": "g",
      "type": "alias",
      "command": "git",
      "description": "Base git command",
      "category": "git",
      "enabled": true
    },
    {
      "name": "gs",
      "type": "alias",
      "command": "git status",
      "description": "Show working tree status",
      "category": "git",
      "enabled": true
    },
    {
      "name": "gaa",
      "type": "alias",
      "command": "git add --all",
      "description": "Add all files to staging",
      "category": "git",
      "enabled": true
    },
    {
      "name": "gcm",
      "type": "alias",
      "command": "git commit -m",
      "description": "Commit with inline message",
      "category": "git",
      "enabled": true
    },
    {
      "name": "gfa",
      "type": "alias",
      "command": "git fetch --all",
      "description": "Fetch all remotes",
      "category": "git",
      "enabled": true
    }
  ]
}
```

## Example: Docker Pack with Functions

```json
{
  "name": "docker-essentials",
  "version": "1.0.0",
  "author": "Smart Alias Manager",
  "description": "Docker shortcuts and cleanup utilities",
  "license": "MIT",
  "tags": ["docker", "containers"],
  "requires": {
    "commands": ["docker"]
  },
  "aliases": [
    {
      "name": "d",
      "type": "alias",
      "command": "docker",
      "description": "Docker command",
      "category": "docker"
    },
    {
      "name": "dps",
      "type": "alias",
      "command": "docker ps",
      "description": "List running containers",
      "category": "docker"
    }
  ],
  "functions": [
    {
      "name": "docker-cleanup",
      "body": "docker stop $(docker ps -q) 2>/dev/null\ndocker system prune -af --volumes",
      "description": "Stop all containers and clean up Docker system",
      "category": "docker"
    }
  ]
}
```

## Directory Structure

```
~/.config/smart-aliases/
├── config.json              # Main configuration
├── enabled-packs.json       # List of enabled packs
└── packs/
    ├── local/               # User's custom packs
    │   ├── my-aliases.json
    │   └── work-aliases.json
    ├── community/           # Downloaded community packs
    │   ├── git-essentials.json
    │   ├── docker-essentials.json
    │   └── jenkins-helpers.json
    └── cache/               # Cached remote packs
        └── [url-hash].json
```

## Loading Priority

1. Core aliases (from alias-optimized.sh)
2. Local packs (from `~/.config/smart-aliases/packs/local/`)
3. Community packs (from `~/.config/smart-aliases/packs/community/`)
4. Remote packs (cached from URLs)

Later packs override earlier ones if there are conflicts.

## Usage with alias-enable

```bash
# Enable a local pack
alias-enable my-aliases

# Enable a pack from URL
alias-enable https://example.com/aliases/git-extended.json

# Enable from GitHub (shorthand)
alias-enable github:user/repo/aliases.json

# List enabled packs
alias-enable --list

# Disable a pack
alias-enable --disable my-aliases

# Show pack info
alias-enable --info git-essentials

# Search available packs
alias-enable --search docker
```

## Validation Rules

1. **Unique Names**: No two aliases in the same pack can have the same name
2. **Valid Commands**: Commands must be executable or valid shell syntax
3. **Function Syntax**: Function bodies must be valid zsh syntax
4. **Version Format**: Must follow semver (X.Y.Z)
5. **Dependencies**: Referenced dependencies must exist

## Security Considerations

1. **Remote Packs**: Prompt user before loading from URL
2. **Code Review**: Show function bodies before enabling
3. **Checksum**: Validate integrity of remote packs
4. **Sandboxing**: Test functions in subshell before loading

## Migration from alias-optimized.sh

The `alias-extract` command can convert existing aliases to pack format:

```bash
# Extract all aliases
alias-extract > ~/.config/smart-aliases/packs/local/my-core-aliases.json

# Extract specific category
alias-extract --category git > git-pack.json

# Extract to separate packs by category
alias-extract --split-by-category
```

---

**Type less, do more! 🚀**
