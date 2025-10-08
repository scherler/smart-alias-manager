#!/bin/bash
# Generate Alias Efficiency Report
# Analyzes your shell history and aliases to calculate efficiency metrics

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
CONFIG_DIR="${HOME}/.config/smart-aliases"
PACKS_DIR="${CONFIG_DIR}/packs/local"
REPORT_FILE="${CONFIG_DIR}/efficiency-report.md"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required for this script"
    exit 1
fi

echo -e "${BLUE}📊 Generating Alias Efficiency Report...${NC}"
echo ""

# Count aliases from all enabled packs
total_aliases=0
total_functions=0
packs_analyzed=0

if [[ -f "${CONFIG_DIR}/config.json" ]]; then
    enabled_packs=$(jq -r '.enabled_packs[]?' "${CONFIG_DIR}/config.json" 2>/dev/null || echo "")

    for pack_name in $enabled_packs; do
        pack_file="${PACKS_DIR}/${pack_name}.json"
        if [[ -f "$pack_file" ]]; then
            alias_count=$(jq '[.aliases[]?] | length' "$pack_file")
            func_count=$(jq '[.functions[]?] | length' "$pack_file")

            total_aliases=$((total_aliases + alias_count))
            total_functions=$((total_functions + func_count))
            ((packs_analyzed++))
        fi
    done
fi

# Analyze shell history for common patterns
declare -A command_counts
declare -A saved_keystrokes

# Read history (works for both zsh and bash)
if [[ -n "$ZSH_VERSION" ]]; then
    # zsh history
    if [[ -f "$HISTFILE" ]]; then
        while IFS= read -r line; do
            # Extract command (remove timestamp and other metadata)
            cmd=$(echo "$line" | sed 's/^: [0-9]*:[0-9]*;//' | awk '{print $1}')
            if [[ -n "$cmd" ]]; then
                ((command_counts[$cmd]++)) 2>/dev/null || command_counts[$cmd]=1
            fi
        done < <(tail -n 1000 "$HISTFILE" 2>/dev/null)
    fi
elif [[ -n "$BASH_VERSION" ]]; then
    # bash history
    if [[ -f "$HOME/.bash_history" ]]; then
        while IFS= read -r line; do
            cmd=$(echo "$line" | awk '{print $1}')
            if [[ -n "$cmd" ]]; then
                ((command_counts[$cmd]++)) 2>/dev/null || command_counts[$cmd]=1
            fi
        done < <(tail -n 1000 "$HOME/.bash_history" 2>/dev/null)
    fi
fi

# Calculate keystroke savings for common commands
# Check which commands have aliases
total_keystrokes_saved=0
aliased_commands=0

for cmd in "${!command_counts[@]}"; do
    count=${command_counts[$cmd]}

    # Check if this command has an alias
    alias_def=$(alias "$cmd" 2>/dev/null || echo "")

    if [[ -n "$alias_def" ]]; then
        # Extract the full command from alias
        full_command=$(echo "$alias_def" | sed "s/^[^=]*='//;s/'$//")

        # Calculate keystrokes saved
        cmd_length=${#cmd}
        full_length=${#full_command}

        if [[ $full_length -gt $cmd_length ]]; then
            saved_per_use=$((full_length - cmd_length))
            total_saved=$((saved_per_use * count))
            total_keystrokes_saved=$((total_keystrokes_saved + total_saved))
            ((aliased_commands++))
        fi
    fi
done

# Calculate statistics
if [[ $aliased_commands -gt 0 ]]; then
    avg_savings=$((total_keystrokes_saved / aliased_commands))
else
    avg_savings=0
fi

# Estimate time saved (assuming 200ms per keystroke)
time_saved_seconds=$((total_keystrokes_saved / 5))  # ~5 keystrokes per second
hours_per_year=$(echo "scale=1; $time_saved_seconds * 52 / 3600" | bc -l 2>/dev/null || echo "0")

# Generate report
cat > "$REPORT_FILE" <<EOF
# 📊 Alias Efficiency Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Aliases | $total_aliases |
| Total Functions | $total_functions |
| Enabled Packs | $packs_analyzed |
| Aliased Commands Used | $aliased_commands |
| Keystrokes Saved (last 1000 commands) | $total_keystrokes_saved |
| Average Savings per Command | $avg_savings keystrokes |
| Estimated Time Saved | ~$hours_per_year hours/year |

## Efficiency Metrics

### Keystroke Reduction

Based on your last 1000 shell commands:

- **$total_keystrokes_saved** total keystrokes saved
- **$aliased_commands** commands benefit from aliases
- Average **$avg_savings** keystrokes saved per aliased command

### Time Savings

Assuming typical typing speed and command frequency:

- **~$time_saved_seconds seconds** saved in recent session
- **~$hours_per_year hours** saved per year

## Top Commands

### Most Frequently Used Commands

EOF

# Add top 10 commands
echo "| Command | Count | Has Alias |" >> "$REPORT_FILE"
echo "|---------|-------|-----------|" >> "$REPORT_FILE"

count=0
for cmd in "${!command_counts[@]}"; do
    echo "${command_counts[$cmd]} $cmd"
done | sort -rn | head -10 | while read -r freq cmd; do
    has_alias="❌"
    alias "$cmd" &>/dev/null && has_alias="✅"
    echo "| \`$cmd\` | $freq | $has_alias |" >> "$REPORT_FILE"
done

# Add pack breakdown
cat >> "$REPORT_FILE" <<EOF

## Pack Breakdown

EOF

if [[ -f "${CONFIG_DIR}/config.json" ]]; then
    enabled_packs=$(jq -r '.enabled_packs[]?' "${CONFIG_DIR}/config.json" 2>/dev/null || echo "")

    for pack_name in $enabled_packs; do
        pack_file="${PACKS_DIR}/${pack_name}.json"
        if [[ -f "$pack_file" ]]; then
            pack_desc=$(jq -r '.description' "$pack_file")
            alias_count=$(jq '[.aliases[]?] | length' "$pack_file")
            func_count=$(jq '[.functions[]?] | length' "$pack_file")

            cat >> "$REPORT_FILE" <<PACK
### $pack_name

- **Description:** $pack_desc
- **Aliases:** $alias_count
- **Functions:** $func_count

PACK
        fi
    done
fi

# Add recommendations
cat >> "$REPORT_FILE" <<EOF

## Recommendations

### Commands Without Aliases

Consider creating aliases for these frequently used commands:

EOF

# Find top commands without aliases
count=0
for cmd in "${!command_counts[@]}"; do
    if ! alias "$cmd" &>/dev/null; then
        echo "${command_counts[$cmd]} $cmd"
    fi
done | sort -rn | head -5 | while read -r freq cmd; do
    echo "- \`$cmd\` (used $freq times) - Consider: \`alias-new '$cmd'\`" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" <<EOF

### Optimization Tips

1. **Review unused aliases** - Check if all enabled aliases are actually being used
2. **Create shortcuts** - Use \`alias-new\` to create aliases for frequent commands
3. **Share packs** - Export your most useful aliases as packs for team use
4. **Regular updates** - Run this report monthly to track improvements

## Next Steps

\`\`\`bash
# Create a new alias
alias-new 'your-frequent-command'

# List your enabled packs
alias-enable --list

# Disable unused packs
alias-enable --disable pack-name
\`\`\`

---

*Report generated by Smart Alias Manager*
*Run \`generate-efficiency-report.sh\` to update this report*
EOF

echo -e "${GREEN}✅ Report generated: $REPORT_FILE${NC}"
echo ""
echo "View report:"
echo -e "  ${YELLOW}cat $REPORT_FILE${NC}"
echo "  or"
echo -e "  ${YELLOW}less $REPORT_FILE${NC}"
