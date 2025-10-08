#!/bin/bash
# Smart Alias Manager - Sample Aliases
# Common, efficient aliases following the "type less, do more" philosophy

# ============================================
# NAVIGATION & FILE OPERATIONS
# ============================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'
alias h='history'
alias hg='history | grep'

# ============================================
# GIT ALIASES - Most commonly used
# ============================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gb='git branch'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gl='git log --oneline'
alias gf='git fetch'
alias gm='git merge'
alias gr='git remote'
alias grv='git remote -v'

# Git composite commands
alias gac='git add . && git commit'
alias gacm='git add . && git commit -m'
alias gpf='git push --force-with-lease'
alias gundo='git reset --soft HEAD~1'

# ============================================
# DOCKER ALIASES
# ============================================
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias drm='docker rm'
alias drmi='docker rmi'
alias dlog='docker logs'
alias dlogf='docker logs -f'

# Docker compose
alias dcu='docker-compose up'
alias dcud='docker-compose up -d'
alias dcd='docker-compose down'
alias dcr='docker-compose restart'
alias dcl='docker-compose logs'

# Docker cleanup
alias dclean='docker system prune -a'
alias dkill='docker kill $(docker ps -q)'

# ============================================
# KUBERNETES ALIASES
# ============================================
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs'
alias klogf='kubectl logs -f'
alias kex='kubectl exec -it'

# ============================================
# NPM/YARN ALIASES
# ============================================
alias ni='npm install'
alias nis='npm install --save'
alias nisd='npm install --save-dev'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

alias y='yarn'
alias ya='yarn add'
alias yad='yarn add --dev'
alias yr='yarn run'
alias ys='yarn start'
alias yt='yarn test'
alias yb='yarn build'

# ============================================
# PYTHON ALIASES
# ============================================
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze > requirements.txt'

# ============================================
# SYSTEM UTILITIES
# ============================================
alias ports='netstat -tulanp'
alias mem='free -h'
alias cpu='top -bn1 | grep "Cpu(s)"'
alias df='df -h'
alias du='du -h'
alias ps='ps aux'
alias psg='ps aux | grep'
alias kill9='kill -9'

# File operations
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -i'
alias mkdir='mkdir -pv'

# Network
alias myip='curl ifconfig.me'
alias localip='hostname -I'
alias ping='ping -c 5'
alias wget='wget -c'

# ============================================
# PRODUCTIVITY ALIASES
# ============================================
alias reload='source ~/.bashrc'  # Or ~/.zshrc for ZSH
alias edit='${EDITOR:-vim}'
alias search='grep -r'
alias find='find . -name'
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'

# ============================================
# CUSTOM FUNCTIONS AS ALIASES
# ============================================

# Create and enter directory
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract various archive types
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar e "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick backup
backup() { cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"; }

# Find and replace in files
replace() {
    find . -type f -name "$1" -exec sed -i "s/$2/$3/g" {} +
}

# ============================================
# NOTES
# ============================================
# To use these aliases:
# 1. Copy the ones you want to your shell config
# 2. Or source this entire file: source sample-aliases.sh
# 3. Reload your shell: source ~/.bashrc (or ~/.zshrc)
#
# Remember: Keep aliases short for maximum efficiency!
# Use 'alias-new' to create custom aliases interactively
