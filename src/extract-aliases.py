#!/usr/bin/env python3
"""
Extract aliases and functions from shell alias files and convert to JSON packs.
Organizes by category: git, docker, maven, npm/yarn, system, etc.

Usage:
    extract-aliases.py [source_file] [output_dir]

Arguments:
    source_file: Path to shell file containing aliases (default: ~/.aliases or ~/.zshrc)
    output_dir:  Directory to save JSON packs (default: ~/.config/smart-aliases/packs/local)
"""

import json
import re
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Default paths
DEFAULT_SOURCE_FILES = [
    Path.home() / ".aliases",
    Path.home() / ".zshrc",
    Path.home() / ".bashrc",
]
DEFAULT_OUTPUT_DIR = Path.home() / ".config/smart-aliases/packs/local"

# Category mappings based on alias prefix or keywords
CATEGORIES = {
    'git': {'prefix': ['g'], 'keywords': ['git']},
    'docker': {'prefix': ['d'], 'keywords': ['docker']},
    'maven': {'prefix': ['m'], 'keywords': ['mvn', 'maven']},
    'npm-yarn': {'prefix': ['y', 'n'], 'keywords': ['npm', 'yarn', 'node']},
    'system': {'prefix': ['c', 'v', 'b', 'l'], 'keywords': ['cd', 'vim', 'ls', 'bat']},
    'jenkins': {'prefix': ['j'], 'keywords': ['jenkins', 'jrun']},
}

def determine_category(name: str, command: str) -> str:
    """Determine the category of an alias based on name and command."""

    # Check git
    if name.startswith('g') and ('git' in command or name in ['g', 'gs', 'ga', 'gc', 'gp', 'gb', 'gd', 'gf', 'gl', 'gu']):
        return 'git'

    # Check docker
    if name.startswith('d') and ('docker' in command or name.startswith('d') and len(name) <= 4):
        return 'docker'

    # Check maven
    if name.startswith('m') and ('mvn' in command or 'maven' in command):
        return 'maven'

    # Check npm/yarn
    if 'yarn' in command or 'npm' in command or name in ['y', 'ys', 'yt', 'ya', 'yb', 'yad', 'ni', 'nr', 'ns', 'nt', 'nu', 'nb', 'nis', 'nisd']:
        return 'npm-yarn'

    # Check jenkins
    if 'jenkins' in command or 'hpi:run' in command or name.startswith('j') and len(name) <= 3:
        return 'jenkins'

    # Check system
    if name in ['c', 'v', 'b', 'l', 'll', 'la', 'ls', 'lsa', 'md', 'rd', ',.']:
        return 'system'

    # Check navigation
    if name in ['-', '..', '...', '....', '.....', '......'] or re.match(r'^\d$', name):
        return 'navigation'

    # Global aliases
    if name in ['G', 'L', 'E', 'D', 'I', 'R', 'T', 'X', 'NT', 'NV']:
        return 'global'

    # Default
    return 'misc'

def extract_aliases(source_file: str) -> Dict[str, List[Dict]]:
    """Extract all aliases from source file and categorize them."""

    aliases_by_category = {}

    with open(source_file, 'r') as f:
        for line in f:
            line = line.strip()

            # Match alias lines: alias name='command' # description
            match = re.match(r"^alias\s+([^=]+)='([^']+)'(?:\s*#\s*(.+))?", line)

            if match:
                name = match.group(1)
                command = match.group(2).replace('"', '\\"')  # Escape quotes for JSON
                description = match.group(3) or f"{name} command"

                category = determine_category(name, command)

                alias_obj = {
                    "name": name,
                    "type": "alias",
                    "command": command,
                    "description": description,
                    "category": category,
                    "enabled": True
                }

                if category not in aliases_by_category:
                    aliases_by_category[category] = []

                aliases_by_category[category].append(alias_obj)

    return aliases_by_category

def extract_functions(source_file: str) -> Dict[str, List[Dict]]:
    """Extract all functions from source file and categorize them."""

    functions_by_category = {}

    with open(source_file, 'r') as f:
        content = f.read()

    # Match function definitions
    # Pattern 1: function name { ... }
    pattern1 = r'function\s+([a-z_][a-z0-9_-]*)\s*\{([^}]+)\}'
    # Pattern 2: name() { ... }
    pattern2 = r'([a-z_][a-z0-9_-]*)\(\)\s*\{([^}]+)\}'

    for pattern in [pattern1, pattern2]:
        for match in re.finditer(pattern, content, re.MULTILINE | re.DOTALL):
            name = match.group(1)
            body = match.group(2).strip()

            # Skip helper functions for alias system itself
            if name in ['alias-help', 'alias-which', 'alias-find', 'alias-new', 'alias-analyze',
                       'check_port', 'find_available_port', 'jrun']:
                continue

            # Determine category
            if 'docker' in body.lower():
                category = 'docker'
            elif 'mvn' in body or 'maven' in body:
                category = 'maven'
            elif 'git' in body:
                category = 'git'
            elif 'jenkins' in body.lower():
                category = 'jenkins'
            else:
                category = 'misc'

            func_obj = {
                "name": name,
                "body": body,
                "description": f"{name} function",
                "category": category
            }

            if category not in functions_by_category:
                functions_by_category[category] = []

            functions_by_category[category].append(func_obj)

    return functions_by_category

def create_pack(category: str, aliases: List[Dict], functions: List[Dict], output_dir: Path) -> str:
    """Create a JSON pack file for a category."""

    # Category metadata
    metadata = {
        'git': {
            'name': 'extracted-git',
            'description': 'Git aliases extracted from personal configuration',
            'tags': ['git', 'vcs'],
            'commands': ['git']
        },
        'docker': {
            'name': 'extracted-docker',
            'description': 'Docker aliases and functions from personal config',
            'tags': ['docker', 'containers'],
            'commands': ['docker']
        },
        'maven': {
            'name': 'extracted-maven',
            'description': 'Maven and Jenkins build aliases',
            'tags': ['maven', 'jenkins', 'build'],
            'commands': ['mvn']
        },
        'npm-yarn': {
            'name': 'extracted-npm-yarn',
            'description': 'NPM and Yarn package manager shortcuts',
            'tags': ['npm', 'yarn', 'javascript'],
            'commands': ['npm', 'yarn']
        },
        'system': {
            'name': 'extracted-system',
            'description': 'System utilities and shell helpers',
            'tags': ['system', 'shell', 'utils'],
            'commands': []
        },
        'navigation': {
            'name': 'extracted-navigation',
            'description': 'Directory navigation shortcuts',
            'tags': ['navigation', 'cd'],
            'commands': []
        },
        'jenkins': {
            'name': 'extracted-jenkins',
            'description': 'Jenkins-specific development shortcuts',
            'tags': ['jenkins', 'development'],
            'commands': []
        },
        'global': {
            'name': 'extracted-global',
            'description': 'Global aliases (expand anywhere)',
            'tags': ['global', 'aliases'],
            'commands': []
        },
        'misc': {
            'name': 'extracted-misc',
            'description': 'Miscellaneous aliases and functions',
            'tags': ['misc', 'other'],
            'commands': []
        }
    }

    meta = metadata.get(category, {
        'name': f'extracted-{category}',
        'description': f'{category.title()} aliases',
        'tags': [category],
        'commands': []
    })

    pack = {
        "name": meta['name'],
        "version": "1.0.0",
        "author": "Extracted from alias-optimized.sh",
        "description": meta['description'],
        "license": "MIT",
        "tags": meta['tags'] + ["extracted", "personal"],
        "requires": {
            "zsh": ">=5.0"
        },
        "aliases": aliases
    }

    if meta['commands']:
        pack["requires"]["commands"] = meta['commands']

    if functions:
        pack["functions"] = functions

    output_file = output_dir / f"{meta['name']}.json"

    with open(output_file, 'w') as f:
        json.dump(pack, f, indent=2)

    return str(output_file)

def find_source_file() -> Optional[Path]:
    """Find the first existing default source file."""
    for source in DEFAULT_SOURCE_FILES:
        if source.exists():
            return source
    return None

def print_usage():
    """Print usage information."""
    print(__doc__)
    print("\nExamples:")
    print("  extract-aliases.py")
    print("  extract-aliases.py ~/.aliases")
    print("  extract-aliases.py /path/to/aliases.sh /path/to/output")
    print("\nDefault source file search order:")
    for i, source in enumerate(DEFAULT_SOURCE_FILES, 1):
        print(f"  {i}. {source}")

def main():
    """Main extraction process."""

    # Parse command-line arguments
    source_file = None
    output_dir = DEFAULT_OUTPUT_DIR

    if len(sys.argv) > 1:
        if sys.argv[1] in ['-h', '--help']:
            print_usage()
            sys.exit(0)
        source_file = Path(sys.argv[1])
        if not source_file.exists():
            print(f"❌ Error: Source file not found: {source_file}")
            sys.exit(1)
    else:
        # Try to find a default source file
        source_file = find_source_file()
        if not source_file:
            print("❌ Error: No alias file found in default locations:")
            for source in DEFAULT_SOURCE_FILES:
                print(f"   - {source}")
            print("\nPlease specify a source file:")
            print("  extract-aliases.py /path/to/your/aliases.sh")
            sys.exit(1)

    if len(sys.argv) > 2:
        output_dir = Path(sys.argv[2])

    print("🔍 Extracting aliases and functions...")
    print(f"📄 Source: {source_file}")
    print(f"📁 Output: {output_dir}")
    print()

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Extract aliases
    print("⚙️  Extracting aliases...")
    aliases_by_category = extract_aliases(str(source_file))

    # Extract functions
    print("⚙️  Extracting functions...")
    functions_by_category = extract_functions(str(source_file))

    # Create pack files
    print()
    print("📦 Creating pack files:")

    all_categories = set(aliases_by_category.keys()) | set(functions_by_category.keys())

    total_aliases = 0
    total_functions = 0

    for category in sorted(all_categories):
        aliases = aliases_by_category.get(category, [])
        functions = functions_by_category.get(category, [])

        if aliases or functions:
            output_file = create_pack(category, aliases, functions, output_dir)
            print(f"  ✅ {category:15} → {len(aliases):2} aliases, {len(functions)} functions")
            print(f"     {output_file}")

            total_aliases += len(aliases)
            total_functions += len(functions)

    print()
    print(f"✨ Extraction complete!")
    print(f"   Total: {total_aliases} aliases, {total_functions} functions")
    print(f"   Created {len(all_categories)} pack files in {output_dir}")
    print()
    print("💡 Next steps:")
    print("   1. Review the generated packs")
    print("   2. Enable a pack: alias-enable extracted-git")
    print("   3. List enabled: alias-enable --list")

if __name__ == "__main__":
    main()
