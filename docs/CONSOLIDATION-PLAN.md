# Infrastructure Consolidation Plan

**Date:** 2026-04-09  
**Goal:** Consolidate `/src/thor/zsh` and `/src/thor/bin` into smart-alias-manager  
**Status:** Planning Phase

---

## Executive Summary

The user has two portable infrastructure systems that have evolved over time:
1. **`/src/thor/zsh`** - Oh-My-Zsh based plugin system with 122 aliases + functions
2. **`/src/thor/bin`** - Collection of 50 executables and scripts

**Current Migration Status:** ~80% of aliases already migrated to smart-alias-manager (118/122 aliases)

**Recommendation:** Complete the migration, preserve specialized tools, deprecate dormant binaries.

---

## Current State Analysis

### /src/thor/zsh Structure

**Location:** `/src/thor/zsh`  
**Architecture:** Oh-My-Zsh plugin system with custom plugins

**Plugins:**
1. **cb-alias** - Custom aliases (122 aliases, 1 function)
   - `alias.sh` - Main alias definitions (ALREADY BEING SOURCED by smart-alias-manager)
   - `export.sh` - Environment variables and secrets
   - `hash.sh` - Named directory shortcuts
   - `cb-alias.plugin.zsh` - Plugin loader

2. **cb** - CloudBees custom functions
   - Git helper functions (current_branch, work_in_progress)
   - Pip completion

3. **cb-search** - Web search functions
   - Aliases: google, github, epg, ticket, over, wiki, map, image, duck
   - Function: web_search()

4. **zsh-autosuggestions** - Third-party plugin (keep)

**Key Files:**
- `.zshrc` - Main config (loads plugins, sets theme)
- `themes/cb/` - Custom ZSH theme

**Current Integration:** 
- `.zshrc` loads plugins via Oh-My-Zsh framework
- `alias.sh` is also sourced by smart-alias-manager (lines 190-192)
- Some redundancy exists between old system and new

---

### /src/thor/bin Structure

**Location:** `/src/thor/bin`  
**Size:** 144MB (mostly large binaries)  
**PATH Integration:** Added to PATH via `~/.zshrc`

**Contents:**

#### .bin/ Directory (37 items)
**Large Binaries (130MB) - DORMANT:**
- `opscore` (101MB) - ELF executable, CloudBees OpsCore CLI
- `hoverfly` (14MB) - Go binary, API simulation tool
- `hoverctl` (13MB) - Hoverfly controller
- `ath_links` (5.7MB) - Unknown ELF executable

**Small Scripts & Tools:**
- `battery-limit` (3.1KB) - Battery charge management
- `battery-notify` (5.9KB) - Battery notification daemon
- `gcm` (566B) - Git commit with branch prefix
- `psx` (931B) - Process scanner/killer
- `psxx` (405B) - Process helper
- `gitap` (420B) - Git add patch wrapper
- `gitiv` (780B) - Git interactive viewer
- `kaba` (1.7KB) - Keyboard helper
- `bkp` (355B) - Backup helper
- `cleanUp` (467B) - Cleanup script
- `em` (244B) - Emacs launcher
- `startApps` (924B) - App launcher script
- `pimpPad` (289B) - Text formatting
- Various small helpers (cata, dump.keybindings, load.keybindings, etc.)

**Other:**
- `.config/` - Config directory
- `cv/` - Unknown subdirectory
- `ds4drv/` - PS4 controller driver
- `m90/` - Unknown purpose
- `setup/` - Setup scripts

#### sbin/ Directory (3 items)
**Root/privileged scripts:**
- `blockIp` (456B) - IP blocking script
- `setCbDns` (338B) - DNS configuration
- `startWlan` (52B) - WLAN starter

#### Root Level Files
- `.gitconfig` - Git configuration with 80+ git aliases
- `battery-notify.backup` - Backup of battery script
- `emacs.cb` (1.8KB) - Emacs config
- `.vimrc` (2.0KB) - Vim config
- `_keybindings` (655B) - Keyboard bindings
- `m90.xbindkeysrc` (2.4KB) - X bindings for M90
- `rjsh.xbindkeysrc` (2.8KB) - X bindings for RJSH
- `README` - Setup instructions for symlinks

**Usage Analysis:**
- Only 1 script referenced in current configs: `psx` (used by alias `z-`)
- Large binaries (opscore, hoverfly, hoverctl, ath_links) have NO references
- Git config is actively used (symlinked from `~/.gitconfig`)

---

## Active vs. Dormant Analysis

### ✅ Actively Used - KEEP

**From /src/thor/zsh:**
- ✅ **cb-alias/alias.sh** - 122 aliases (118 already in smart-alias-manager)
- ✅ **cb-alias/export.sh** - Environment variables (API keys, tokens, paths)
- ✅ **cb-alias/hash.sh** - Directory shortcuts (s, c, j, t, b, z)
- ✅ **cb/cb.plugin.zsh** - Git helper functions
- ✅ **cb-search/cb-search.plugin.zsh** - Web search functions
- ✅ **zsh-autosuggestions** - Third-party plugin
- ✅ **themes/cb/** - Custom ZSH theme

**From /src/thor/bin:**
- ✅ **.gitconfig** - 80+ git aliases (CRITICAL - actively used)
- ✅ **psx** - Process scanner (used by alias `z-`)
- ✅ **battery-limit** - Battery management (useful utility)
- ✅ **gcm** - Git commit helper (useful for branch-based workflows)
- ✅ **.vimrc** - Vim configuration
- ✅ **emacs.cb** - Emacs configuration

### ⚠️ Potentially Useful - EVALUATE

**From /src/thor/bin:**
- ⚠️ **gitap** - Git add patch wrapper (may be useful)
- ⚠️ **gitiv** - Git interactive viewer (may be useful)
- ⚠️ **kaba** - Keyboard helper (hardware-specific)
- ⚠️ **bkp** - Backup helper (generic utility)
- ⚠️ **cleanUp** - Cleanup script (needs inspection)
- ⚠️ **startApps** - App launcher (may be desktop-specific)
- ⚠️ **battery-notify** - Battery daemon (useful on laptops)
- ⚠️ **sbin/* scripts** - Root tools (may be hardware/network-specific)
- ⚠️ **xbindkeysrc files** - Keyboard bindings (hardware-specific)

### ❌ Dormant/Unused - DEPRECATE

**From /src/thor/bin:**
- ❌ **opscore** (101MB) - No references, outdated CLI tool
- ❌ **hoverfly** (14MB) - No references, API mocking tool (use docker instead)
- ❌ **hoverctl** (13MB) - No references, companion to hoverfly
- ❌ **ath_links** (5.7MB) - No references, unknown purpose
- ❌ **em** - Emacs launcher (unnecessary, use `emacs` directly)
- ❌ **em.desktop** - Desktop entry (should be in ~/.local/share/applications/)
- ❌ **cata** - Tiny wrapper (57B - probably obsolete)
- ❌ **dump.keybindings** - Debug script (58B)
- ❌ **load.keybindings** - Config loader (148B)
- ❌ **gist.md** - Markdown snippet (52B - should be in docs)
- ❌ **private** - Unknown script (632B)
- ❌ **p** - Unknown script (632B)
- ❌ **pimpPad** - Text formatter (289B - evaluate)
- ❌ **status-p** - Status checker (113B)
- ❌ **svnap** - SVN helper (585B - SVN is obsolete)
- ❌ **svnClean** - SVN cleanup (579B - SVN is obsolete)
- ❌ **add-apt-repository** - System tool (should be in /usr/bin)
- ❌ **hpk-tunnel** - Tunnel script (104B - unknown)
- ❌ **mongodb-dropall.js** - Dangerous script (should be in project, not global)
- ❌ **cv/** - Unknown subdirectory
- ❌ **ds4drv/** - PS4 driver (hardware-specific, rarely used)
- ❌ **m90/** - Unknown purpose
- ❌ **setup/** - Setup scripts (one-time use)

---

## Migration Strategy

### Phase 1: Complete Alias Migration (PRIORITY 1)

**Goal:** Finish migrating remaining 4 aliases from cb-alias to smart-alias-manager

**Unmigrated Aliases:**
1. `clearZshCache` - "rm ~/.zcompdump*"
2. `tmux-help` - "cat ~/.tmux-help.md | less"
3. `xc` - AWS SSO login (bedrock-claude-user profile) - **BROKEN ALIAS** (syntax error)
4. `xy` - AWS SSO login (bedrock-viewer profile)

**Actions:**
```bash
# Add to system.json pack
jq '.aliases += [
  {
    "name": "clearZshCache",
    "type": "alias",
    "command": "rm ~/.zcompdump*",
    "description": "Clear ZSH completion cache",
    "category": "system",
    "enabled": true
  },
  {
    "name": "tmux-help",
    "type": "alias", 
    "command": "cat ~/.tmux-help.md | less",
    "description": "Show tmux help documentation",
    "category": "system",
    "enabled": true
  }
]' ~/.config/smart-aliases/packs/local/system.json > /tmp/system.json.tmp
mv /tmp/system.json.tmp ~/.config/smart-aliases/packs/local/system.json

# Add to misc.json or create aws.json pack
jq '.aliases += [
  {
    "name": "xc",
    "type": "alias",
    "command": "aws sso login --profile cloudbees-bedrock-claude-infra-bedrock-claude-user",
    "description": "AWS SSO login (Claude user)",
    "category": "aws",
    "enabled": true
  },
  {
    "name": "xy",
    "type": "alias",
    "command": "aws sso login --profile cloudbees-bedrock-claude-infra-bedrock-viewer",
    "description": "AWS SSO login (Claude viewer)",
    "category": "aws",
    "enabled": true
  }
]' ~/.config/smart-aliases/packs/local/misc.json > /tmp/misc.json.tmp
mv /tmp/misc.json.tmp ~/.config/smart-aliases/packs/local/misc.json

# Regenerate cache
alias-refresh
```

**Verification:**
```bash
# Test new aliases
clearZshCache
tmux-help
xc  # Should work now
xy
```

---

### Phase 2: Migrate Git Aliases (PRIORITY 1)

**Goal:** Convert .gitconfig aliases to smart-alias-manager format

**Current State:** 
- `.gitconfig` has 80+ git aliases (g, ga, gc, gco, etc.)
- These are git subcommands, not shell aliases
- Already tracked in git config system

**Decision:** **KEEP in .gitconfig**

**Rationale:**
- Git aliases are designed for git subcommands (e.g., `git nb` = `git new-branch`)
- Converting to shell aliases would require prefixing: `alias gnb='git nb'`
- This creates double indirection: `gnb` → `git nb` → `git checkout -b ...`
- Git config aliases are portable across systems (any git installation)
- No duplication needed - current system works well

**Actions:**
- ✅ Keep `.gitconfig` as-is (symlinked to `~/.gitconfig`)
- ✅ Document git aliases in smart-alias-manager docs (cross-reference)
- ❌ Do NOT create duplicate shell aliases

**Documentation Update:**
Create `docs/GIT-ALIASES.md` that references `.gitconfig`:
```markdown
# Git Aliases

Git aliases are defined in `/src/thor/bin/.gitconfig` (symlinked to `~/.gitconfig`).

Run `git la` to list all git aliases.

See `/src/thor/bin/.gitconfig` for full list.
```

---

### Phase 3: Preserve Functions & Complex Logic (PRIORITY 2)

**Goal:** Keep complex shell functions that can't be simple aliases

**Functions to Preserve:**

#### From cb-alias/alias.sh:
1. **`zsh-stats()`** - Command frequency analysis
2. **`rationalise-dot()`** - Smart dot expansion (.. → ../)
3. **`download-core-cm()`** - Maven artifact downloader
4. **`download-core-mm()`** - Maven artifact downloader
5. **`download-core-oc()`** - Maven artifact downloader
6. **`download-core-oc-traditional()`** - Maven artifact downloader
7. **`xx()`** - Maven test debugger
8. **`qq()`** - Combined reviewer command
9. **`weather()`** - Weather lookup
10. **`stats()`** - Shell command statistics
11. **`brightness()`** - Screen brightness control
12. **`screenCast()`** - Screen recording helper

#### From cb/cb.plugin.zsh:
1. **`current_branch()`** - Git current branch (needed by git aliases)
2. **`current_repository()`** - Git repository info
3. **`work_in_progress()`** - WIP commit detector
4. **`_git_log_prettily()`** - Pretty git log

#### From cb-search/cb-search.plugin.zsh:
1. **`web_search()`** - Web search function (used by google, github, etc. aliases)

**Actions:**
```bash
# Create src/functions-library.sh in smart-alias-manager
cat > /src/thor/smart-alias-manager/src/functions-library.sh << 'EOF'
#!/bin/bash
# Complex shell functions that can't be simple aliases
# Sourced by loader.sh

# Function definitions go here...
EOF

# Update src/loader.sh to source functions-library.sh
echo "source \"\${SMART_ALIAS_ROOT}/src/functions-library.sh\"" >> /src/thor/smart-alias-manager/src/loader.sh
```

**Alternative:** Keep functions in cb-alias plugin and continue sourcing it (RECOMMENDED)
- Less duplication
- Preserves existing working system
- smart-alias-manager focuses on aliases, not functions

---

### Phase 4: Preserve Environment Variables (PRIORITY 1)

**Goal:** Keep export.sh for environment configuration

**Current State:**
- `export.sh` contains API keys, tokens, Java/Maven paths, AWS config
- Currently loaded by cb-alias plugin
- Contains sensitive data (should NOT be in git)

**Actions:**
1. ✅ **Keep export.sh in current location** (`/src/thor/zsh/plugins/cb-alias/export.sh`)
2. ✅ **Continue sourcing via cb-alias plugin** (already working)
3. ⚠️ **Security check:** Verify export.sh is in .gitignore
4. ✅ **Document** environment variables in smart-alias-manager

**Security Verification:**
```bash
# Check if export.sh is tracked by git
cd /src/thor/zsh
git check-ignore plugins/cb-alias/export.sh
# Should output: plugins/cb-alias/export.sh (means it's ignored)

# If not ignored, add to .gitignore
echo "plugins/cb-alias/export.sh" >> /src/thor/zsh/.gitignore
```

---

### Phase 5: Preserve Named Directories (PRIORITY 2)

**Goal:** Keep hash.sh for directory shortcuts

**Current State:**
- `hash.sh` defines: s=/src, c=/src/cloudbees, j=/src/jenkins, etc.
- Allows: `cd ~s/project` instead of `cd /src/project`
- Very useful for navigation

**Actions:**
- ✅ Keep hash.sh in current location
- ✅ Continue sourcing via cb-alias plugin
- ✅ Document in smart-alias-manager

**Alternative:** Add to smart-alias-manager
```bash
# Create src/directory-hashes.sh
cat > /src/thor/smart-alias-manager/src/directory-hashes.sh << 'EOF'
# Named directory shortcuts (zsh hash -d)
hash -d s=/src
hash -d c=~s/cloudbees
hash -d j=~s/jenkins
hash -d t=~s/thor
hash -d b=~t/bin
hash -d z=~t/zsh
EOF

# Update loader.sh
```

**Recommendation:** Keep in cb-alias for now (less duplication)

---

### Phase 6: Migrate Useful Scripts (PRIORITY 2)

**Goal:** Move useful standalone scripts to smart-alias-manager

**Scripts to Migrate:**

#### High Priority:
1. **psx** - Process scanner/killer (referenced by alias z-)
2. **battery-limit** - Battery management
3. **gcm** - Git commit with branch prefix
4. **battery-notify** - Battery notification daemon

#### Medium Priority:
5. **gitap** - Git add patch wrapper
6. **gitiv** - Git interactive viewer
7. **bkp** - Backup helper
8. **kaba** - Keyboard helper

**Target Location:** `/src/thor/smart-alias-manager/bin/`

**Actions:**
```bash
# Create bin directory in smart-alias-manager
mkdir -p /src/thor/smart-alias-manager/bin

# Copy useful scripts
cp /src/thor/bin/.bin/psx /src/thor/smart-alias-manager/bin/
cp /src/thor/bin/.bin/battery-limit /src/thor/smart-alias-manager/bin/
cp /src/thor/bin/.bin/gcm /src/thor/smart-alias-manager/bin/
cp /src/thor/bin/.bin/battery-notify /src/thor/smart-alias-manager/bin/

# Make executable
chmod +x /src/thor/smart-alias-manager/bin/*

# Update PATH in loader.sh
echo 'export PATH="${SMART_ALIAS_ROOT}/bin:$PATH"' >> /src/thor/smart-alias-manager/src/loader.sh

# Create pack entries for scripts (optional - can just use PATH)
```

---

### Phase 7: Preserve Config Files (PRIORITY 2)

**Goal:** Keep essential config files, move to proper locations

**Files to Preserve:**

1. **.gitconfig** - Keep in /src/thor/bin, symlink to ~/.gitconfig (ALREADY DONE)
2. **.vimrc** - Move to ~/.vimrc or keep as reference
3. **emacs.cb** - Move to ~/.emacs.d/ or keep as reference
4. **xbindkeysrc files** - Keep in /src/thor/bin (hardware-specific)

**Actions:**
```bash
# Verify .gitconfig symlink
ls -la ~/.gitconfig
# Should point to: /src/thor/bin/.gitconfig

# Optionally move vim/emacs configs
# (Only if not already configured elsewhere)
```

---

### Phase 8: Deprecate Dormant Binaries (PRIORITY 3)

**Goal:** Archive or delete unused large binaries to save 130MB

**Binaries to Remove:**
- opscore (101MB)
- hoverfly (14MB)
- hoverctl (13MB)
- ath_links (5.7MB)

**Actions:**
```bash
# Create archive directory (in case needed later)
mkdir -p /src/thor/bin/.archive

# Move large dormant binaries
mv /src/thor/bin/.bin/opscore /src/thor/bin/.archive/
mv /src/thor/bin/.bin/hoverfly /src/thor/bin/.archive/
mv /src/thor/bin/.bin/hoverctl /src/thor/bin/.archive/
mv /src/thor/bin/.bin/ath_links /src/thor/bin/.archive/

# Add to .gitignore (if in git)
echo ".archive/" >> /src/thor/bin/.gitignore

# After 3 months, if not used, delete:
# rm -rf /src/thor/bin/.archive/
```

**Disk Space Saved:** 130MB

---

### Phase 9: Clean Up Obsolete Scripts (PRIORITY 3)

**Goal:** Remove outdated/unnecessary scripts

**Scripts to Remove:**
- svnap, svnClean (SVN is obsolete)
- em, em.desktop (unnecessary wrappers)
- cata, dump.keybindings, load.keybindings (tiny debug scripts)
- gist.md (should be in docs)
- private, p (unknown, unused)
- add-apt-repository (should be system command)
- mongodb-dropall.js (dangerous, should be project-specific)

**Actions:**
```bash
# Remove obsolete scripts
rm /src/thor/bin/.bin/svnap
rm /src/thor/bin/.bin/svnClean
rm /src/thor/bin/.bin/em
rm /src/thor/bin/.bin/em.desktop
rm /src/thor/bin/.bin/cata
rm /src/thor/bin/.bin/dump.keybindings
rm /src/thor/bin/.bin/load.keybindings
rm /src/thor/bin/.bin/gist.md
rm /src/thor/bin/.bin/private
rm /src/thor/bin/.bin/p
rm /src/thor/bin/.bin/add-apt-repository
rm /src/thor/bin/.bin/mongodb-dropall.js

# Evaluate before removing:
ls -la /src/thor/bin/.bin/pimpPad  # Text formatter
ls -la /src/thor/bin/.bin/status-p  # Status checker
ls -la /src/thor/bin/.bin/hpk-tunnel  # Tunnel script
```

---

### Phase 10: Update Shell Configuration (PRIORITY 1)

**Goal:** Simplify .zshrc to use smart-alias-manager as primary system

**Current .zshrc loads:**
1. Oh-My-Zsh with plugins (cb, cb-alias, cb-search, docker, kubectl, etc.)
2. Smart-alias-manager via loader.sh
3. Custom alias.sh via direct source

**Proposed .zshrc changes:**

```bash
# BEFORE (current):
plugins=(
  autojump 
  cb 
  cb-alias 
  cb-search 
  docker 
  kubectl 
  ssh-agent 
  zsh-autosuggestions 
  per-directory-history
)

# Source custom aliases first (if exists)
if [[ -f "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh" ]]; then
    source "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh"
fi

# Smart Alias Manager - Load alias packs and functions
[[ -f /src/smart-alias-manager/src/loader.sh ]] && source /src/smart-alias-manager/src/loader.sh

# AFTER (proposed):
plugins=(
  autojump 
  cb               # Keep for git helper functions
  cb-alias         # Keep for export.sh, hash.sh, and complex functions
  cb-search        # Keep for web_search() function
  docker           # Oh-My-Zsh plugin
  kubectl          # Oh-My-Zsh plugin
  ssh-agent        # Oh-My-Zsh plugin
  zsh-autosuggestions 
  per-directory-history
)

# Smart Alias Manager (PRIMARY SYSTEM)
# This loads all alias packs from ~/.config/smart-aliases/packs/local/
[[ -f /src/thor/smart-alias-manager/src/loader.sh ]] && source /src/thor/smart-alias-manager/src/loader.sh

# Note: cb-alias plugin still loads export.sh and hash.sh
# This provides environment variables and directory shortcuts
# Complex functions are also preserved in cb-alias
```

**Rationale:**
- Smart-alias-manager becomes primary alias system
- cb-alias plugin kept for environment vars, hashes, and functions
- No need to source alias.sh separately (smart-alias-manager has all aliases)
- Cleaner separation of concerns

**Actions:**
```bash
# Update /src/thor/zsh/.zshrc (user's zsh config)
# Comment out the direct alias.sh sourcing
sed -i 's|^if \[\[ -f "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh" \]\]; then|# if [[ -f "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh" ]]; then|' /src/thor/zsh/.zshrc
sed -i 's|^    source "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh"|#     source "/src/thor/zsh/plugins/cb-alias/alias-optimized.sh"|' /src/thor/zsh/.zshrc
sed -i 's|^fi$|# fi|' /src/thor/zsh/.zshrc

# Update smart-alias-manager path (fix typo if exists)
sed -i 's|/src/smart-alias-manager/src/loader.sh|/src/thor/smart-alias-manager/src/loader.sh|' /src/thor/zsh/.zshrc
```

---

### Phase 11: Archive /src/thor/bin (PRIORITY 3)

**Goal:** After migration, archive or delete /src/thor/bin

**Options:**

1. **Archive Approach** (RECOMMENDED):
   ```bash
   # Rename to indicate archived status
   mv /src/thor/bin /src/thor/bin.archived-2026-04-09
   
   # Update PATH in ~/.zshrc
   # Remove: export PATH="/src/thor/bin:$PATH"
   
   # Keep .gitconfig symlink working
   ln -sf /src/thor/bin.archived-2026-04-09/.gitconfig ~/.gitconfig
   
   # After 6 months, if not needed, delete:
   # rm -rf /src/thor/bin.archived-2026-04-09
   ```

2. **Selective Keep Approach**:
   ```bash
   # Keep only .gitconfig and hardware-specific configs
   mkdir -p /src/thor/config
   mv /src/thor/bin/.gitconfig /src/thor/config/
   mv /src/thor/bin/*.xbindkeysrc /src/thor/config/
   mv /src/thor/bin/.vimrc /src/thor/config/
   mv /src/thor/bin/emacs.cb /src/thor/config/
   
   # Archive the rest
   mv /src/thor/bin /src/thor/bin.archived-2026-04-09
   
   # Symlink .gitconfig
   ln -sf /src/thor/config/.gitconfig ~/.gitconfig
   ```

3. **Keep Minimal Approach** (MOST AGGRESSIVE):
   ```bash
   # Create minimal bin with only essentials
   mkdir -p /src/thor/bin-minimal
   cp /src/thor/bin/.gitconfig /src/thor/bin-minimal/
   
   # Move old bin away
   mv /src/thor/bin /src/thor/bin.archived-2026-04-09
   
   # Rename minimal to bin
   mv /src/thor/bin-minimal /src/thor/bin
   ```

**Recommendation:** Option 1 (Archive Approach) - safest, easy to rollback

---

## Implementation Steps

### Quick Start (30 minutes)

1. **Migrate remaining 4 aliases** (Phase 1)
   ```bash
   cd /src/thor/smart-alias-manager
   # Use alias-new command or edit JSON packs directly
   alias-new  # Add: clearZshCache, tmux-help, xc, xy
   alias-refresh
   ```

2. **Test all aliases work**
   ```bash
   source ~/.zshrc
   clearZshCache
   tmux-help
   xc
   xy
   ```

3. **Update .zshrc** (Phase 10)
   ```bash
   # Comment out direct alias.sh sourcing
   vim /src/thor/zsh/.zshrc
   # Verify smart-alias-manager path is correct
   ```

4. **Create bin/ directory** (Phase 6)
   ```bash
   mkdir -p /src/thor/smart-alias-manager/bin
   cp /src/thor/bin/.bin/psx /src/thor/smart-alias-manager/bin/
   cp /src/thor/bin/.bin/battery-limit /src/thor/smart-alias-manager/bin/
   cp /src/thor/bin/.bin/gcm /src/thor/smart-alias-manager/bin/
   chmod +x /src/thor/smart-alias-manager/bin/*
   
   # Update loader.sh to add bin/ to PATH
   echo 'export PATH="${SMART_ALIAS_ROOT}/bin:$PATH"' >> src/loader.sh
   ```

5. **Test everything**
   ```bash
   source ~/.zshrc
   psx -t bash  # Should work
   battery-limit status  # Should work
   ```

### Full Migration (2-3 hours)

Follow all 11 phases in order:
1. ✅ Phase 1: Complete alias migration (30 min)
2. ✅ Phase 2: Git aliases decision (5 min - keep in .gitconfig)
3. ✅ Phase 3: Functions preservation (30 min)
4. ✅ Phase 4: Environment variables (10 min - verify security)
5. ✅ Phase 5: Named directories (10 min)
6. ✅ Phase 6: Migrate scripts (20 min)
7. ✅ Phase 7: Config files (10 min)
8. ✅ Phase 8: Deprecate binaries (5 min)
9. ✅ Phase 9: Clean up obsolete (10 min)
10. ✅ Phase 10: Update .zshrc (15 min)
11. ✅ Phase 11: Archive /src/thor/bin (10 min)

**Total Time:** 2-3 hours (including testing)

---

## Post-Migration Verification

### Checklist

- [ ] All aliases work: Run `alias-aliases` to list all aliases
- [ ] Git aliases work: Run `git la` to list git aliases
- [ ] Scripts work: Test `psx`, `battery-limit`, `gcm`
- [ ] Environment variables set: Check `echo $JAVA_HOME`, `echo $AWS_PROFILE`
- [ ] Directory hashes work: Test `cd ~s`, `cd ~c`, `cd ~j`
- [ ] Web search functions work: Test `google "test"`, `github "search"`
- [ ] Git functions work: Test `current_branch`, `work_in_progress`
- [ ] Shell startup time: Should be <100ms (test with `time zsh -i -c exit`)

### Performance Test

```bash
# Test shell startup time
time zsh -i -c exit

# Should be:
# - Before optimization: ~200-500ms
# - After optimization: <100ms (with cache.sh)
```

### Rollback Plan

If something breaks:

```bash
# Option 1: Restore old .zshrc
cp /src/thor/zsh/.zshrc.backup /src/thor/zsh/.zshrc
source ~/.zshrc

# Option 2: Re-enable old bin directory
export PATH="/src/thor/bin:$PATH"

# Option 3: Restore old plugin loading
# Edit .zshrc to source alias.sh again
```

---

## Long-Term Maintenance

### Keep
- **smart-alias-manager** - Primary alias system
- **cb-alias plugin** - Environment variables, hashes, functions
- **cb plugin** - Git helper functions
- **cb-search plugin** - Web search functions
- **.gitconfig** - Git aliases

### Archive
- **/src/thor/bin** - After successful migration (6 month retention)

### Remove
- **Large dormant binaries** - After 3 months in archive
- **Obsolete scripts** - After verification not used

### Regular Review
- **Every 6 months:** Review archived files, delete if confirmed unused
- **Every year:** Review all aliases/scripts for obsolescence
- **On shell slowdown:** Profile startup time, optimize packs

---

## Risks & Mitigation

### Risk 1: Breaking Active Workflows
**Mitigation:** 
- Migrate in phases
- Test each phase before proceeding
- Keep rollback plan ready
- Preserve old system for 6 months

### Risk 2: Missing Dependencies
**Mitigation:**
- Test all aliases after migration
- Check for references in .zshrc, .bashrc, scripts
- Keep detailed inventory

### Risk 3: Environment Variable Loss
**Mitigation:**
- Keep export.sh in original location
- Continue sourcing via cb-alias plugin
- Document all environment variables

### Risk 4: Function Breakage
**Mitigation:**
- Keep functions in cb-alias plugin
- Don't convert complex functions to aliases
- Test git helper functions thoroughly

---

## Benefits After Consolidation

### Immediate Benefits
✅ Single source of truth for aliases (smart-alias-manager)  
✅ 130MB disk space saved (removing dormant binaries)  
✅ Simpler .zshrc configuration  
✅ Better organization (packs by category)  
✅ Easier to manage (JSON format, version controlled)

### Long-Term Benefits
✅ Portable across systems (single project to clone)  
✅ Easy to share (JSON packs)  
✅ Better discoverability (`alias-help`, `alias-which`)  
✅ Crash recovery support (smart-alias-manager features)  
✅ AI-enhanced alias suggestions (`alias-analyze`)

---

## Next Steps

1. **Review this plan** - Confirm approach with user
2. **Start with Phase 1** - Migrate remaining 4 aliases (quick win)
3. **Test thoroughly** - Verify aliases work after migration
4. **Continue phases** - Complete migration over next week
5. **Archive old system** - After 1 month of successful usage

---

## Questions for User

1. **Timing:** When do you want to start migration? (Suggest: weekend or Friday afternoon)
2. **Risk tolerance:** Comfortable with archiving /src/thor/bin after migration?
3. **Priority:** Any specific aliases/scripts you use daily that need extra care?
4. **Hardware-specific:** Are xbindkeysrc, kaba, battery-notify still relevant? (What hardware?)
5. **Security:** Should we audit export.sh for outdated/expired API keys?

---

## Appendix: File Inventory

### /src/thor/zsh
```
Total: 4 plugins, 1 theme, 1 config file
- cb-alias/ (4 files: alias.sh, export.sh, hash.sh, plugin.zsh)
- cb/ (1 file: cb.plugin.zsh)
- cb-search/ (1 file: cb-search.plugin.zsh)
- zsh-autosuggestions/ (third-party plugin)
- themes/cb/ (custom theme)
- .zshrc (main config)
```

### /src/thor/bin
```
Total: 50 files, 144MB
- .bin/ (37 items, 144MB)
  - Large binaries: 4 files, 130MB (opscore, hoverfly, hoverctl, ath_links)
  - Scripts: ~25 files, ~30KB
  - Configs: ~8 files
- sbin/ (3 files)
- Config files: .gitconfig, .vimrc, emacs.cb, xbindkeysrc files
- Subdirectories: cv/, ds4drv/, m90/, setup/, .config/
```

### smart-alias-manager (current)
```
Total: 10 packs, 118 aliases
- git.json (15 aliases)
- docker.json (8 aliases)
- maven.json (20 aliases)
- npm-yarn.json (25 aliases)
- jenkins.json (5 aliases)
- jrun.json (1 function)
- system.json (10 aliases)
- misc.json (30 aliases)
- extracted-misc.json (4 aliases)
- reporter.json (10 aliases)
```

---

**Document Version:** 1.0  
**Author:** Claude (GPT-4)  
**Date:** 2026-04-09  
**Status:** Draft - Pending User Review
