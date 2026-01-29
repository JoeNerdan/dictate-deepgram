#!/bin/bash
set -e

echo "=== dictate-deepgram installer ==="
echo

# Detect package manager
if command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
    INSTALL_CMD="sudo dnf install -y"
    PACKAGES="xdotool portaudio-devel"
elif command -v apt &> /dev/null; then
    PKG_MGR="apt"
    INSTALL_CMD="sudo apt install -y"
    PACKAGES="xdotool libportaudio2 portaudio19-dev"
elif command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    PACKAGES="xdotool portaudio"
else
    echo "Warning: Could not detect package manager."
    echo "Please manually install: xdotool, portaudio"
    INSTALL_CMD=""
fi

# Install system dependencies
if [ -n "$INSTALL_CMD" ]; then
    echo "Installing system dependencies ($PKG_MGR)..."
    $INSTALL_CMD $PACKAGES
    echo
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --user deepgram-sdk pyaudio
echo

# API key setup
CONFIG_FILE="$HOME/.config/deepgram-api-key"
if [ -f "$CONFIG_FILE" ]; then
    echo "API key already configured at $CONFIG_FILE"
else
    echo "Get your API key at: https://console.deepgram.com/"
    echo
    read -p "Enter your Deepgram API key (or press Enter to skip): " API_KEY
    if [ -n "$API_KEY" ]; then
        mkdir -p "$HOME/.config"
        echo "$API_KEY" > "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        echo "API key saved to $CONFIG_FILE"
    else
        echo "Skipped. Set DEEPGRAM_API_KEY env var or create $CONFIG_FILE later."
    fi
fi
echo

# Install script
echo "Installing dictate-deepgram to ~/.local/bin/..."
mkdir -p "$HOME/.local/bin"

# Get the script - either from local dir or download from GitHub
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/dictate-deepgram" ]; then
    cp "$SCRIPT_DIR/dictate-deepgram" "$HOME/.local/bin/"
else
    curl -fsSL https://raw.githubusercontent.com/JoeNerdan/dictate-deepgram/main/dictate-deepgram \
        -o "$HOME/.local/bin/dictate-deepgram"
fi
chmod +x "$HOME/.local/bin/dictate-deepgram"

# Check PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo
    echo "Note: Add ~/.local/bin to your PATH:"
    echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
fi

echo
echo "=== Installation complete ==="
echo "Run 'dictate-deepgram' to start dictating."
echo "Run it again (or press Ctrl+C) to stop."
