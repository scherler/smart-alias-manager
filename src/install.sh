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
    echo "║   JSON-based Pack System Edition      ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check dependencies
check_dependencies() {
    echo -e "${GREEN}🔍 Checking dependencies...${NC}"

    local missing_deps=()

    # Check for jq (required for JSON pack management)
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
        echo -e "${YELLOW}⚠️  jq is required for JSON pack management${NC}"
    else
        echo "✅ jq found"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}❌ Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "   - $dep"
        done
        echo ""
        echo "Please install missing dependencies:"
        echo -e "${YELLOW}  Ubuntu/Debian: sudo apt-get install jq${NC}"
        echo -e "${YELLOW}  macOS: brew install jq${NC}"
        echo ""
        echo -n "Continue anyway? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled"
            exit 1
        fi
    fi
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
    if [ -f "src/loader.sh" ]; then
        # We're in the repo, copy files
        echo "Installing from local repository..."
        mkdir -p "$INSTALL_DIR"
        cp -r src docs reports packs README.md .gitignore "$INSTALL_DIR/" 2>/dev/null || true
        cp -r examples "$INSTALL_DIR/" 2>/dev/null || true
    else
        # Clone from GitHub
        echo "Cloning from GitHub..."
        git clone https://github.com/scherler/smart-alias-manager.git "$INSTALL_DIR"
    fi

    # Make scripts executable
    chmod +x "$INSTALL_DIR/src/"*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR/src/extract-aliases.py" 2>/dev/null || true

    echo "✅ Files installed to $INSTALL_DIR"
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
        # Use more specific markers: start with "# Smart Alias Manager" comment
        # and end after the loader.sh source line
        sed -i.tmp '/# ============================================/,/^# Smart Alias Manager/d; /Smart Alias Manager - Load alias packs/,/source.*loader\.sh/d' "$SHELL_CONFIG"
        rm -f "${SHELL_CONFIG}.tmp"
    fi
    
    # Add configuration to shell config with proper zsh/bash compatibility
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        cat >> "$SHELL_CONFIG" << EOF

# ============================================
# Smart Alias Manager
# ============================================
# Powerful alias management system with JSON-based packs

# Smart Alias Manager - Load alias packs and functions
[[ -f $INSTALL_DIR/src/loader.sh ]] && source $INSTALL_DIR/src/loader.sh
EOF
    else
        cat >> "$SHELL_CONFIG" << EOF

# ============================================
# Smart Alias Manager
# ============================================
# Powerful alias management system with JSON-based packs
if [ -f "$INSTALL_DIR/src/loader.sh" ]; then
    source "$INSTALL_DIR/src/loader.sh"
fi
EOF
    fi
    echo "Added configuration to $SHELL_CONFIG"
}

# Create alias storage directory and config
setup_alias_storage() {
    echo -e "${GREEN}📁 Setting up alias pack system...${NC}"

    ALIAS_DIR="${HOME}/.config/smart-aliases"
    PACKS_DIR="${ALIAS_DIR}/packs"

    # Create directory structure
    mkdir -p "${PACKS_DIR}/local"
    mkdir -p "${PACKS_DIR}/community"
    mkdir -p "${PACKS_DIR}/cache"

    # Create config.json if it doesn't exist
    if [ ! -f "${ALIAS_DIR}/config.json" ]; then
        cat > "${ALIAS_DIR}/config.json" << 'EOF'
{
  "version": "1.0.0",
  "user": {
    "name": "user",
    "shell": "zsh"
  },
  "paths": {
    "packs_dir": "${HOME}/.config/smart-aliases/packs",
    "local_packs": "${HOME}/.config/smart-aliases/packs/local",
    "community_packs": "${HOME}/.config/smart-aliases/packs/community",
    "cache_dir": "${HOME}/.config/smart-aliases/packs/cache"
  },
  "enabled_packs": [],
  "settings": {
    "auto_load": true,
    "show_loading_messages": true,
    "check_requirements": true,
    "allow_url_packs": true
  }
}
EOF
        echo "✅ Created config.json"
    fi

    # Create .gitignore files to protect user data
    if [ ! -f "${PACKS_DIR}/local/.gitignore" ]; then
        echo "# Ignore all extracted and user-created packs" > "${PACKS_DIR}/local/.gitignore"
        echo "extracted-*.json" >> "${PACKS_DIR}/local/.gitignore"
        echo "*.json" >> "${PACKS_DIR}/local/.gitignore"
        echo "✅ Created .gitignore for local packs"
    fi

    if [ ! -f "${PACKS_DIR}/cache/.gitignore" ]; then
        echo "# Ignore all cached packs" > "${PACKS_DIR}/cache/.gitignore"
        echo "*.json" >> "${PACKS_DIR}/cache/.gitignore"
        echo "✅ Created .gitignore for cached packs"
    fi

    echo "✅ Pack system directories created at ${PACKS_DIR}"
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

    # Check if config.json was created
    if [[ -f "${HOME}/.config/smart-aliases/config.json" ]]; then
        echo "✅ config.json created"
    else
        echo "❌ config.json not found"
        return 1
    fi

    # Check pack directories
    if [[ -d "${HOME}/.config/smart-aliases/packs/local" ]]; then
        echo "✅ Pack directories created"
    else
        echo "❌ Pack directories not found"
        return 1
    fi

    # For zsh, test in subshell
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        # Test loader.sh
        if zsh -c "source '$INSTALL_DIR/src/loader.sh' 2>/dev/null && type alias-enable" &> /dev/null; then
            echo "✅ alias-enable function loaded"
        else
            echo "⚠️  alias-enable function not found (will be available after reloading shell)"
        fi

        # Test alias-new
        if zsh -c "source '$INSTALL_DIR/src/loader.sh' 2>/dev/null && type alias-new" &> /dev/null; then
            echo "✅ alias-new function loaded"
        else
            echo "⚠️  alias-new function not found (will be available after reloading shell)"
        fi
    else
        # Bash test
        if command -v jq &> /dev/null; then
            source "$INSTALL_DIR/src/loader.sh" 2>/dev/null

            if type alias-enable &> /dev/null; then
                echo "✅ alias-enable function loaded"
            else
                echo "⚠️  alias-enable function not found"
            fi

            if type alias-new &> /dev/null; then
                echo "✅ alias-new function loaded"
            else
                echo "⚠️  alias-new function not found"
            fi
        else
            echo "⚠️  Skipping function tests (jq not installed)"
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
    echo "2. Extract your existing aliases to JSON packs:"
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        echo -e "   ${YELLOW}python3 $INSTALL_DIR/src/extract-aliases.py ~/.zshrc${NC}"
    else
        echo -e "   ${YELLOW}python3 $INSTALL_DIR/src/extract-aliases.py ~/.bashrc${NC}"
    fi
    echo "   Or if you have a separate aliases file:"
    echo -e "   ${YELLOW}python3 $INSTALL_DIR/src/extract-aliases.py /path/to/your/aliases.sh${NC}"
    echo ""
    echo "3. Try these commands:"
    echo -e "   ${YELLOW}alias-enable --list${NC}         # List enabled packs"
    echo -e "   ${YELLOW}alias-enable extracted-git${NC}  # Enable a pack"
    echo -e "   ${YELLOW}alias-new 'git status'${NC}      # Create a new alias"
    echo -e "   ${YELLOW}alias-enable --info git${NC}     # Show pack details"
    echo ""
    echo "4. Check the examples and templates:"
    echo -e "   ${YELLOW}ls $INSTALL_DIR/packs/templates/${NC}"
    echo ""
    echo "5. Read the documentation:"
    echo -e "   ${YELLOW}cat $INSTALL_DIR/README.md${NC}"
    echo -e "   ${YELLOW}cat $INSTALL_DIR/docs/packs.md${NC}"
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

    check_dependencies
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
