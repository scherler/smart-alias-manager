#!/usr/bin/env bash
# Smart Alias Manager - Installation Script
# Automatically sets up the alias management system for your shell
# Compatible with bash and zsh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="${HOME}/.smart-alias-manager"

# Detect shell type
detect_shell() {
    # First check the SHELL environment variable
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_TYPE="zsh"
        SHELL_CONFIG="${HOME}/.zshrc"
    elif [[ -n "$ZSH_VERSION" ]]; then
        SHELL_TYPE="zsh"
        SHELL_CONFIG="${HOME}/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        SHELL_TYPE="bash"
        SHELL_CONFIG="${HOME}/.bashrc"
    else
        # Try to detect from SHELL variable
        case "$SHELL" in
            */zsh)
                SHELL_TYPE="zsh"
                SHELL_CONFIG="${HOME}/.zshrc"
                ;;
            */bash)
                SHELL_TYPE="bash"
                SHELL_CONFIG="${HOME}/.bashrc"
                ;;
            *)
                # Default to zsh if /usr/bin/zsh exists
                if [[ -f "/usr/bin/zsh" ]]; then
                    SHELL_TYPE="zsh"
                    SHELL_CONFIG="${HOME}/.zshrc"
                else
                    echo -e "${RED}Unable to detect shell type${NC}"
                    echo "Please set SHELL_CONFIG manually and run again"
                    exit 1
                fi
                ;;
        esac
    fi
}

# Print banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║      Smart Alias Manager v1.0.0       ║"
    echo "║   Type less, do more with aliases!    ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if already installed
check_existing() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}⚠️  Smart Alias Manager is already installed at $INSTALL_DIR${NC}"
        echo -n "Do you want to reinstall/update? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled"
            exit 0
        fi
        echo "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
}

# Clone or copy repository
install_files() {
    echo -e "${GREEN}📦 Installing Smart Alias Manager...${NC}"
    
    # Check if we're in the repo directory
    if [ -f "src/alias-manager.sh" ]; then
        # We're in the repo, copy files
        echo "Installing from local repository..."
        mkdir -p "$INSTALL_DIR"
        cp -r src examples templates docs README.md .claude.json "$INSTALL_DIR/" 2>/dev/null || true
    else
        # Clone from GitHub (update with your actual repo URL)
        echo "Cloning from GitHub..."
        git clone https://github.com/yourusername/smart-alias-manager.git "$INSTALL_DIR"
    fi
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR/src/alias-manager.sh" 2>/dev/null || true
}

# Setup shell configuration
setup_shell_config() {
    echo -e "${GREEN}🔧 Configuring $SHELL_TYPE...${NC}"
    
    # Backup existing config
    if [ -f "$SHELL_CONFIG" ]; then
        cp "$SHELL_CONFIG" "${SHELL_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backed up existing config to ${SHELL_CONFIG}.backup.*"
    fi
    
    # Check if already configured
    if grep -q "Smart Alias Manager" "$SHELL_CONFIG" 2>/dev/null; then
        echo "Configuration already exists in $SHELL_CONFIG"
        # Remove old configuration to replace with new one
        sed -i.tmp '/# ============================================/,/export ALIAS_CONFIG_FILE=/d' "$SHELL_CONFIG"
        rm -f "${SHELL_CONFIG}.tmp"
    fi
    
    # Add configuration to shell config with proper zsh/bash compatibility
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        cat >> "$SHELL_CONFIG" << 'EOF'

# ============================================
# Smart Alias Manager
# ============================================
# Powerful alias management system with AI-enhanced suggestions

# Source custom aliases first (if exists)
if [[ -f "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh" ]]; then
    source "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh"
fi

EOF
        cat >> "$SHELL_CONFIG" << EOF
# Source Smart Alias Manager
if [[ -f "$INSTALL_DIR/src/alias-manager.sh" ]]; then
    source "$INSTALL_DIR/src/alias-manager.sh"
fi

# Custom alias file location (optional)
export ALIAS_CONFIG_FILE="\${HOME}/.config/smart-aliases/aliases.sh"
EOF
    else
        cat >> "$SHELL_CONFIG" << EOF

# ============================================
# Smart Alias Manager
# ============================================
# Powerful alias management system with AI-enhanced suggestions
if [ -f "$INSTALL_DIR/src/alias-manager.sh" ]; then
    source "$INSTALL_DIR/src/alias-manager.sh"
fi

# Custom alias file location (optional)
export ALIAS_CONFIG_FILE="\${HOME}/.config/smart-aliases/aliases.sh"
EOF
    fi
    echo "Added configuration to $SHELL_CONFIG"
    
    # Add note about custom aliases
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        echo -e "${BLUE}ℹ️  Configured to source your custom aliases from:${NC}"
        echo "   /src/thor/zsh/plugins/cb-alias/alias-optimized.sh"
    fi
}

# Create alias storage directory
setup_alias_storage() {
    echo -e "${GREEN}📁 Setting up alias storage...${NC}"
    
    ALIAS_DIR="${HOME}/.config/smart-aliases"
    mkdir -p "$ALIAS_DIR"
    
    # Create initial aliases file if it doesn't exist
    if [ ! -f "$ALIAS_DIR/aliases.sh" ]; then
        cat > "$ALIAS_DIR/aliases.sh" << 'EOF'
# Smart Alias Manager - User Aliases
# This file contains your custom aliases
# Created on: $(date)

# Example aliases (uncomment to use):
# alias ll='ls -la'
# alias ..='cd ..'
# alias ...='cd ../..'

# Your aliases will be added below by the alias-new command:

EOF
        echo "Created alias storage at $ALIAS_DIR/aliases.sh"
    fi
}

# Create example aliases based on detected tools
create_examples() {
    echo -e "${GREEN}📝 Creating example aliases...${NC}"
    
    EXAMPLE_FILE="$INSTALL_DIR/examples/detected-aliases.sh"
    mkdir -p "$INSTALL_DIR/examples"
    
    cat > "$EXAMPLE_FILE" << 'EOF'
# Auto-detected tool aliases
# Based on tools found on your system

EOF
    
    # Check for common tools and add aliases
    if command -v git &> /dev/null; then
        cat >> "$EXAMPLE_FILE" << 'EOF'
# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'

EOF
    fi
    
    if command -v docker &> /dev/null; then
        cat >> "$EXAMPLE_FILE" << 'EOF'
# Docker aliases
alias d='docker'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias drm='docker rm'

EOF
    fi
    
    if command -v kubectl &> /dev/null; then
        cat >> "$EXAMPLE_FILE" << 'EOF'
# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kaf='kubectl apply -f'

EOF
    fi
    
    echo "Created example aliases based on detected tools"
}

# Test installation
test_installation() {
    echo -e "${GREEN}🧪 Testing installation...${NC}"
    
    # For zsh, we need to test differently
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        # Test in a zsh subshell
        zsh -c "source '$INSTALL_DIR/src/alias-manager.sh' && type alias-help" &> /dev/null
        if [[ $? -eq 0 ]]; then
            echo "✅ alias-help function loaded"
        else
            echo "⚠️  alias-help function not found (will be available after reloading shell)"
        fi
        
        zsh -c "source '$INSTALL_DIR/src/alias-manager.sh' && type ah" &> /dev/null
        if [[ $? -eq 0 ]]; then
            echo "✅ Short aliases (ah) loaded"
        else
            echo "⚠️  Short aliases not found (will be available after reloading shell)"
        fi
        
        # Check if custom alias file exists
        if [[ -f "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh" ]]; then
            echo "✅ Custom alias file found"
        else
            echo "⚠️  Custom alias file not found at /src/thor/zsh/plugins/cb-alias/alias-optimized.sh"
        fi
    else
        # Original bash test
        source "$INSTALL_DIR/src/alias-manager.sh"
        
        if type alias-help &> /dev/null; then
            echo "✅ alias-help function loaded"
        else
            echo "❌ alias-help function not found"
            return 1
        fi
        
        if type ah &> /dev/null; then
            echo "✅ Short aliases (ah) loaded"
        else
            echo "❌ Short aliases not found"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✅ Installation test completed!${NC}"
}

# Print success message
print_success() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   🎉 Installation Complete! 🎉        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Smart Alias Manager has been installed successfully!"
    echo ""
    echo -e "${BLUE}📚 Quick Start Guide:${NC}"
    echo ""
    echo "1. Reload your shell configuration:"
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        echo -e "   ${YELLOW}source ~/.zshrc${NC}"
        echo "   or simply:"
        echo -e "   ${YELLOW}exec zsh${NC}"
    else
        echo -e "   ${YELLOW}source $SHELL_CONFIG${NC}"
    fi
    echo ""
    echo "2. Try these commands:"
    echo -e "   ${YELLOW}ah${NC}              # Show help and list aliases"
    echo -e "   ${YELLOW}an 'git status'${NC} # Create a new alias"
    echo -e "   ${YELLOW}af git${NC}          # Find git-related aliases"
    echo -e "   ${YELLOW}aa${NC}              # Analyze your command history"
    
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        echo ""
        echo "📦 Your custom aliases are integrated from:"
        echo -e "   ${YELLOW}/src/thor/zsh/plugins/cb-alias/alias-optimized.sh${NC}"
    fi
    echo ""
    echo "3. Check the examples:"
    echo -e "   ${YELLOW}cat $INSTALL_DIR/examples/detected-aliases.sh${NC}"
    echo ""
    echo "4. Read the documentation:"
    echo -e "   ${YELLOW}cat $INSTALL_DIR/README.md${NC}"
    echo ""
    echo -e "${GREEN}Type less, do more! 🚀${NC}"
}

# Main installation flow
main() {
    print_banner
    detect_shell
    
    echo "Detected shell: $SHELL_TYPE"
    echo "Configuration file: $SHELL_CONFIG"
    echo ""
    
    check_existing
    install_files
    setup_shell_config
    setup_alias_storage
    create_examples
    
    if test_installation; then
        print_success
    else
        echo -e "${RED}⚠️  Installation completed but tests failed${NC}"
        echo "Please check the installation manually"
        exit 1
    fi
}

# Run main function
main "$@"
