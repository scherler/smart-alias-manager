#!/bin/bash
# Extract aliases from alias-optimized.sh and convert to JSON packs

SOURCE_FILE="/src/thor/zsh/plugins/cb-alias/alias-optimized.sh"
OUTPUT_DIR="$HOME/.config/smart-aliases/packs/local"

mkdir -p "$OUTPUT_DIR"

# Create git category pack
cat > "$OUTPUT_DIR/extracted-git.json" <<'EOF'
{
  "name": "extracted-git",
  "version": "1.0.0",
  "author": "Extracted from alias-optimized.sh",
  "description": "Git aliases extracted from your personal configuration",
  "license": "MIT",
  "tags": ["git", "vcs", "extracted"],
  "requires": {
    "commands": ["git"]
  },
  "aliases": [
EOF

# Extract git aliases
first=true
grep "^alias g" "$SOURCE_FILE" | while IFS= read -r line; do
    if [[ "$line" =~ ^alias\ ([^=]+)=\'([^\']+)\'.*#\ (.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        cmd="${BASH_REMATCH[2]}"
        desc="${BASH_REMATCH[3]}"

        [[ "$first" == "false" ]] && echo "," >> "$OUTPUT_DIR/extracted-git.json"
        first=false

        cat >> "$OUTPUT_DIR/extracted-git.json" <<ALIAS
    {
      "name": "$name",
      "type": "alias",
      "command": "$cmd",
      "description": "$desc",
      "category": "git",
      "enabled": true
    }
ALIAS
    fi
done

cat >> "$OUTPUT_DIR/extracted-git.json" <<'EOF'
  ]
}
EOF

echo "Created: $OUTPUT_DIR/extracted-git.json"
