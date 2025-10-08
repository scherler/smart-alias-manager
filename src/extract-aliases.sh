#!/bin/bash
# Wrapper script for extract-aliases.py
# Extract aliases from shell files and convert to JSON packs
#
# Usage:
#   extract-aliases.sh [source_file] [output_dir]
#
# Examples:
#   extract-aliases.sh                              # Auto-detect source file
#   extract-aliases.sh ~/.aliases                   # Specify source file
#   extract-aliases.sh /path/to/aliases.sh /output  # Specify both

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/extract-aliases.py"

# Check if Python script exists
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    echo "❌ Error: extract-aliases.py not found at $PYTHON_SCRIPT"
    exit 1
fi

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 is required to run this script"
    echo "Please install Python 3"
    exit 1
fi

# Pass all arguments to Python script
python3 "$PYTHON_SCRIPT" "$@"
