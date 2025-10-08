#!/bin/zsh
# Enhanced Jenkins Run Function
# Unified command for running Jenkins with maven or java
# Includes port checking and auto-fallback

check_port() {
    local port=$1
    # Check if port is in use using lsof or nc
    if command -v lsof &> /dev/null; then
        lsof -i :$port -sTCP:LISTEN -t &> /dev/null
        return $?
    elif command -v nc &> /dev/null; then
        nc -z localhost $port &> /dev/null
        return $?
    else
        # Fallback: check /proc/net/tcp (Linux)
        if [[ -f /proc/net/tcp ]]; then
            local hex_port=$(printf '%04X' $port)
            grep -q ":${hex_port} " /proc/net/tcp
            return $?
        fi
    fi
    return 1  # Assume port is free if we can't check
}

find_available_port() {
    local start_port=$1
    local max_attempts=10
    local current_port=$start_port

    for ((i=0; i<max_attempts; i++)); do
        if ! check_port $current_port; then
            echo $current_port
            return 0
        fi
        ((current_port++))
    done

    return 1  # No available port found
}

jrun() {
    local port="8080"
    local product=""
    local mode="maven"  # Default to maven mode (mvn hpi:run)
    local products_dir="/src/jenkins/unified-release/products"
    local auto_port=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --java|-j)
                mode="java"
                shift
                ;;
            --maven|-m)
                mode="maven"
                shift
                ;;
            --auto-port|-a)
                auto_port=true
                shift
                ;;
            --help|-h)
                echo "🚀 Jenkins Run - Unified launcher for Jenkins products"
                echo ""
                echo "Usage: jrun [OPTIONS] [PORT] [PRODUCT]"
                echo ""
                echo "Options:"
                echo "  -j, --java        Use java -jar mode (for built wars)"
                echo "  -m, --maven       Use mvn hpi:run mode (default)"
                echo "  -a, --auto-port   Auto-find available port if busy"
                echo "  -h, --help        Show this help message"
                echo ""
                echo "Arguments:"
                echo "  PORT              Port number (default: 8080)"
                echo "  PRODUCT           Product name (core-cm, core-mm, core-oc, etc.)"
                echo ""
                echo "Examples:"
                echo "  jrun                    # Interactive selection, maven mode, port 8080"
                echo "  jrun 9090               # Port 9090, interactive product selection"
                echo "  jrun core-oc            # Product core-oc, port 8080"
                echo "  jrun 9090 core-cm       # Port 9090, product core-cm"
                echo "  jrun -j core-oc         # Java mode, core-oc, port 8080"
                echo "  jrun -a 8080 core-oc    # Auto-find port if 8080 is busy"
                echo ""
                echo "Products:"
                echo "  core-cm               - CloudBees Core - Managed Master"
                echo "  core-mm               - CloudBees Core - Managed Master"
                echo "  core-oc               - CloudBees Core - Operations Center"
                echo "  core-oc-traditional   - CloudBees Core - OC Traditional"
                echo "  core-cc               - CloudBees Core - Client Controller"
                return 0
                ;;
            *)
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    port="$1"
                else
                    product="$1"
                fi
                shift
                ;;
        esac
    done

    # Check if port is available
    if check_port $port; then
        echo "⚠️  Port $port is already in use!"

        if $auto_port; then
            echo "🔍 Looking for available port..."
            local new_port=$(find_available_port $port)
            if [[ $? -eq 0 ]]; then
                port=$new_port
                echo "✅ Found available port: $port"
            else
                echo "❌ Could not find an available port (tried $port-$((port+9)))"
                echo ""
                echo "💡 Options:"
                echo "   1. Stop the process using port $port"
                echo "   2. Try a different port manually: jrun <port> [product]"
                echo "   3. Use --auto-port flag: jrun -a $port [product]"
                return 1
            fi
        else
            echo ""
            echo "💡 Options:"
            echo "   1. Stop the process using port $port:"
            echo "      lsof -ti :$port | xargs kill -9"
            echo "   2. Try a different port: jrun <port> [product]"
            echo "   3. Auto-find available port: jrun -a $port [product]"
            return 1
        fi
    fi

    # If no product specified, show interactive selection
    if [[ -z "$product" ]]; then
        echo "🚀 Available Jenkins products:"
        local products=(core-cm core-mm core-oc core-oc-traditional core-cc)
        local i=1
        for p in "${products[@]}"; do
            if [[ -d "$products_dir/$p" ]]; then
                echo "  $i) $p"
            else
                echo "  $i) $p (not found)"
            fi
            ((i++))
        done
        echo ""
        echo -n "Select product (1-${#products[@]}): "
        read choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le ${#products[@]} ]]; then
            product="${products[$choice]}"
        else
            echo "❌ Invalid selection"
            return 1
        fi
    fi

    # Validate product directory
    if [[ ! -d "$products_dir/$product" ]]; then
        echo "❌ Product directory not found: $products_dir/$product"
        echo ""
        echo "Available products:"
        for p in "$products_dir"/core-*(/N); do
            echo "  - $(basename $p)"
        done
        return 1
    fi

    # Build the WAR path
    local war_file="$products_dir/$product/target/${product}.war"

    # Check if WAR exists for java mode
    if [[ "$mode" == "java" ]] && [[ ! -f "$war_file" ]]; then
        echo "❌ WAR file not found: $war_file"
        echo ""
        echo "💡 Build the project first:"
        echo "   cd $products_dir/$product"
        echo "   mvn clean install -DskipTests"
        return 1
    fi

    # Display run information
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 Starting Jenkins"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Product:  $product"
    echo "🔧 Mode:     $mode"
    echo "🌐 Port:     $port"
    if [[ "$mode" == "java" ]]; then
        echo "📄 WAR:      $war_file"
    fi
    echo "🏠 Home:     ./target"
    echo ""
    echo "🔗 URL:      http://localhost:$port"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Execute the appropriate command
    if [[ "$mode" == "java" ]]; then
        java -DJENKINS_HOME=./target -jar "$war_file" --httpPort=$port
    else
        # Maven mode
        mvn hpi:run \
            -DJENKINS_HOME=./target \
            -DwebAppFile="$war_file" \
            -Dport="$port"
    fi
}

# Shorter aliases for common scenarios
alias jr='jrun'                           # Short form
alias jrj='jrun --java'                   # Java mode
alias jrm='jrun --maven'                  # Maven mode (explicit)
alias jra='jrun --auto-port'              # Auto-port mode

# Legacy compatibility (deprecated, but kept for transition)
alias mroc='jrun core-oc'                 # Operations Center on default port
