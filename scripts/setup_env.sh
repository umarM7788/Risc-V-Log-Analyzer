#!/bin/bash

set -euo pipefail

echo "========================================"
echo " RISC-V Log Analyzer Environment Setup"
echo "========================================"

echo
echo "Checking required tools..."
echo


REQUIRED_TOOLS=(
    bash
    grep
    awk
    sed
    sort
    uniq
    wc
    mkdir
    git
    make
)


MISSING=()


for tool in "${REQUIRED_TOOLS[@]}"; do

    if command -v "$tool" >/dev/null 2>&1; then

        VERSION=$(command -v "$tool")

        echo "[OK]      $tool -> $VERSION"

    else

        echo "[MISSING] $tool"

        MISSING+=("$tool")

    fi

done


echo


if (( ${#MISSING[@]} > 0 )); then

    echo "Some required tools are missing:"
    echo

    for tool in "${MISSING[@]}"; do
        echo "  - $tool"
    done

    echo
    echo "Please install the missing tools and run setup again."

    exit 1

fi


echo "All required tools are installed."
echo "Environment check completed successfully."

exit 0