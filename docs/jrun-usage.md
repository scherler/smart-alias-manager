# jrun - Unified Jenkins Launcher

## Overview

`jrun` is an enhanced command that unifies running Jenkins products with automatic port checking, preventing bind exceptions and providing clear feedback about what's running where.

## Key Features

✅ **Port Checking** - Automatically detects if a port is in use
✅ **Auto Port Finding** - Finds next available port automatically
✅ **Dual Mode** - Supports both Maven (`mvn hpi:run`) and Java (`java -jar`) modes
✅ **Interactive Selection** - Choose product interactively if not specified
✅ **Clear Output** - Shows exactly what's running on which port
✅ **Smart Defaults** - Sensible defaults for quick launches

## Basic Usage

### Syntax
```bash
jrun [OPTIONS] [PORT] [PRODUCT]
```

### Quick Examples

```bash
# Interactive selection (default maven mode, port 8080)
jrun

# Specific product on default port 8080
jrun core-oc

# Specific port with interactive product selection
jrun 9090

# Specific port and product
jrun 9090 core-cm

# Java mode (uses java -jar instead of maven)
jrun -j core-oc

# Auto-find available port if 8080 is busy
jrun -a core-oc

# Maven mode (explicit)
jrun -m core-oc
```

## Options

| Option | Short | Description |
|--------|-------|-------------|
| `--java` | `-j` | Use `java -jar` mode (for built wars) |
| `--maven` | `-m` | Use `mvn hpi:run` mode (default) |
| `--auto-port` | `-a` | Auto-find available port if specified port is busy |
| `--help` | `-h` | Show help message |

## Products

| Product | Description |
|---------|-------------|
| `core-cm` | CloudBees Core - Client Master |
| `core-mm` | CloudBees Core - Managed Master |
| `core-oc` | CloudBees Core - Operations Center |
| `core-cc` | CloudBees Core - Client Controller |

## Short Aliases

For even faster typing:

| Alias | Equivalent | Description |
|-------|-----------|-------------|
| `jr` | `jrun` | Short form |
| `jrj` | `jrun --java` | Java mode |
| `jrm` | `jrun --maven` | Maven mode (explicit) |
| `jra` | `jrun --auto-port` | Auto-port mode |

## Usage Scenarios

### Scenario 1: Port Already in Use

**Without auto-port:**
```bash
$ jrun core-oc
⚠️  Port 8080 is already in use!

💡 Options:
   1. Stop the process using port 8080:
      lsof -ti :8080 | xargs kill -9
   2. Try a different port: jrun <port> [product]
   3. Auto-find available port: jrun -a 8080 [product]
```

**With auto-port:**
```bash
$ jrun -a core-oc
⚠️  Port 8080 is already in use!
🔍 Looking for available port...
✅ Found available port: 8081

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Starting Jenkins
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Product:  core-oc
🔧 Mode:     maven
🌐 Port:     8081
🏠 Home:     ./target

🔗 URL:      http://localhost:8081
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Scenario 2: Interactive Product Selection

```bash
$ jrun
🚀 Available Jenkins products:
  1) core-cm ✓
  2) core-mm ✓
  3) core-oc ✓
  4) core-cc (not found)

Select product (1-4): 3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Starting Jenkins
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Product:  core-oc
🔧 Mode:     maven
🌐 Port:     8080
🏠 Home:     ./target

🔗 URL:      http://localhost:8080
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Scenario 3: Java Mode for Built WARs

```bash
$ jrun -j 8090 core-oc

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Starting Jenkins
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Product:  core-oc
🔧 Mode:     java
🌐 Port:     8090
📄 WAR:      /src/jenkins/unified-release/products/core-oc/target/core-oc.war
🏠 Home:     ./target

🔗 URL:      http://localhost:8090
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Comparison: Old vs New

### Old Way (`mroc`)

```bash
# Fixed command, no flexibility
alias mroc='mr -DJENKINS_HOME=./target -DwebAppFile=/src/jenkins/unified-release/products/core-oc/target/core-oc.war -Dport=8080'

# Problems:
# - No port checking
# - Hardcoded to core-oc
# - Fixed to port 8080
# - No error handling
# - Bind exception if port busy
```

### New Way (`jrun`)

```bash
# Flexible, smart, prevents errors
jrun -a core-oc

# Advantages:
# ✅ Port checking
# ✅ Auto-find available port
# ✅ Works with any product
# ✅ Choose maven or java mode
# ✅ Clear feedback
# ✅ Prevents bind exceptions
```

## Migration Guide

### For Users of `mroc`

The `mroc` alias now uses `jrun` internally:

```bash
# Old (still works for compatibility)
mroc

# New equivalent
jrun core-oc

# New with auto-port
jrun -a core-oc

# New with custom port
jrun 9090 core-oc
```

### Command Mapping

| Old Command | New Equivalent | Improvement |
|------------|----------------|-------------|
| `mroc` | `jrun core-oc` | Port checking, flexibility |
| `mr -Dport=9090 ...` | `jrun 9090 core-oc` | Much shorter |
| `java -jar ... --httpPort=8080` | `jrun -j core-oc` | Port checking, clarity |

## Tips & Tricks

### 1. Run Multiple Instances

Use auto-port to run multiple products simultaneously:

```bash
# Terminal 1
jrun -a core-oc          # Gets 8080

# Terminal 2
jrun -a core-cm          # Gets 8081 (auto-found)

# Terminal 3
jrun -a core-mm          # Gets 8082 (auto-found)
```

### 2. Quick Help

```bash
# Show help anytime
jrun --help
jrun -h
```

### 3. Check What's Running

```bash
# List processes on ports
lsof -i :8080
lsof -i :8081-8090

# Kill specific port
lsof -ti :8080 | xargs kill -9
```

### 4. Use Short Aliases

```bash
# Instead of typing jrun every time
jr                    # Same as jrun
jr -a core-oc        # Auto-port
jrj core-oc          # Java mode
jra core-oc          # Auto-port mode
```

## Technical Details

### Port Checking Methods

`jrun` uses multiple methods to check port availability (in order of preference):

1. **lsof** - Most reliable on macOS/Linux
2. **nc** (netcat) - Fallback if lsof not available
3. **/proc/net/tcp** - Linux-specific fallback

### Port Finding Algorithm

When auto-port is enabled:
1. Check requested port
2. If busy, try port+1
3. Continue up to port+9 (10 attempts)
4. Report error if no port found in range

### Environment Variables

The function uses:
- `products_dir="/src/jenkins/unified-release/products"` - Can be customized

## Troubleshooting

### Port Check Not Working

If port checking doesn't work on your system:

```bash
# Ensure you have lsof or nc installed
which lsof
which nc

# Install if missing (Ubuntu/Debian)
sudo apt-get install lsof netcat

# Install if missing (macOS)
brew install lsof netcat
```

### Product Not Found

```bash
$ jrun core-xyz
❌ Product directory not found: /src/jenkins/unified-release/products/core-xyz

Available products:
  - core-cm
  - core-mm
  - core-oc
```

**Solution**: Check product name spelling or verify the product exists.

### WAR File Missing (Java Mode)

```bash
$ jrun -j core-oc
❌ WAR file not found: /src/jenkins/unified-release/products/core-oc/target/core-oc.war

💡 Build the project first:
   cd /src/jenkins/unified-release/products/core-oc
   mvn clean install -DskipTests
```

**Solution**: Build the product first with maven.

## See Also

- [Efficiency Report](../efficiency-report.md) - Full usage analysis
- [Alias Help System](../README.md#usage) - Using `ah`, `aw`, `af` commands
- [Smart Alias Manager](../README.md) - Main documentation

---

**Type less, do more! 🚀**
