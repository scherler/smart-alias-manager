# Claude Code Instructions for Smart Alias Manager

## Testing Requirements

**CRITICAL: Always test changes before completion**

When modifying shell configuration files (`.zshrc`, `.bashrc`, alias files, etc.), you MUST test them by sourcing the file:

```bash
# Test zsh configuration
zsh -n ~/.zshrc  # Check syntax without execution
source ~/.zshrc  # Actually source the file

# Test bash configuration
bash -n ~/.bashrc  # Check syntax
source ~/.bashrc

# Test specific alias files
zsh -n /path/to/alias-file.sh
source /path/to/alias-file.sh
```

### Why This Matters

Simple sourcing catches:
- Syntax errors (missing quotes, brackets, etc.)
- Undefined variables
- Command not found errors
- Logic errors in functions
- Parsing issues in complex aliases

### Testing Workflow

1. **Before** marking a task complete, source the modified file
2. If errors occur, fix them immediately
3. Re-test until the file sources cleanly
4. Only then mark the task as completed

### Example

```bash
# After editing ~/.zshrc
echo "Testing changes..."
zsh -n ~/.zshrc && echo "✅ Syntax OK" || echo "❌ Syntax error"
source ~/.zshrc && echo "✅ Sourced successfully" || echo "❌ Source failed"
```

## Code Quality

- Preserve existing formatting and style
- Add comments for complex logic
- Follow shell scripting best practices
- Quote variables to prevent word splitting
- Use `set -e` in scripts where appropriate
