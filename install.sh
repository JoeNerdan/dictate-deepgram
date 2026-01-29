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

# Keyboard shortcut setup
setup_gnome_shortcut() {
    local shortcut="$1"
    local name="Dictate"
    local command="$HOME/.local/bin/dictate-deepgram"
    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictate/"

    # Get current custom keybindings
    local current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

    # Check if our binding already exists
    if [[ "$current" == *"dictate"* ]]; then
        echo "Keyboard shortcut already configured"
    else
        # Add our path to the list
        if [[ "$current" == "@as []" ]]; then
            new_bindings="['$path']"
        else
            # Remove trailing ] and add our path
            new_bindings="${current%]*}, '$path']"
        fi
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings"
    fi

    # Configure the shortcut
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path name "$name"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path command "$command"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path binding "$shortcut"

    echo "Keyboard shortcut set: $shortcut"
}

setup_kde_shortcut() {
    local shortcut="$1"
    local command="$HOME/.local/bin/dictate-deepgram"

    # KDE uses kwriteconfig5/6 and kglobalaccel
    if command -v kwriteconfig6 &> /dev/null; then
        KWRITE="kwriteconfig6"
    elif command -v kwriteconfig5 &> /dev/null; then
        KWRITE="kwriteconfig5"
    else
        echo "Warning: Could not find kwriteconfig. Set shortcut manually in System Settings."
        return
    fi

    $KWRITE --file kglobalshortcutsrc --group "dictate-deepgram.desktop" --key "_launch" "$shortcut,none,Dictate"
    $KWRITE --file kglobalshortcutsrc --group "dictate-deepgram.desktop" --key "_k_friendly_name" "Dictate"

    # Create desktop entry for KDE
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/dictate-deepgram.desktop" << DESKTOP
[Desktop Entry]
Name=Dictate
Comment=Voice dictation using Deepgram
Exec=$command
Icon=audio-input-microphone
Type=Application
Categories=Utility;
DESKTOP

    # Reload shortcuts
    if command -v kquitapp6 &> /dev/null; then
        kquitapp6 kglobalaccel && kglobalaccel6 &
    elif command -v kquitapp5 &> /dev/null; then
        kquitapp5 kglobalaccel && kglobalaccel5 &
    fi

    echo "Keyboard shortcut set: $shortcut"
}

# Detect desktop environment and set up shortcut
echo "Setting up keyboard shortcut..."

# Default shortcut
SHORTCUT="<Super>d"

if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_SESSION_DESKTOP" = "gnome" ]; then
    setup_gnome_shortcut "$SHORTCUT"
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$XDG_SESSION_DESKTOP" = "plasma" ]; then
    # KDE uses different format
    setup_kde_shortcut "Meta+D"
else
    echo "Desktop environment not detected. Set keyboard shortcut manually:"
    echo "  Command: $HOME/.local/bin/dictate-deepgram"
    echo "  Suggested shortcut: Super+D"
fi

echo
echo "=== Installation complete ==="
echo "Press Super+D to start/stop dictation."
