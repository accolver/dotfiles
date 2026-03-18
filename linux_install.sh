#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

backup_and_link() {
    local source="$1"
    local target="$2"
    
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            current_target=$(readlink -f "$target")
            if [ "$current_target" = "$source" ]; then
                echo "  Already linked: $source -> $target"
                return 0
            fi
        fi
        echo "  Backing up existing $target"
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/"
    fi
    
    echo "  Linking $source -> $target"
    ln -sf "$source" "$target"
}

echo "=== Setting up .zshrc ==="
backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

echo ""
echo "=== Setting up .config directories ==="
mkdir -p "$HOME/.config"

CONFIG_DIRS=(
    "bat"
    "ghostty"
    "git"
    "ncspot"
    "nvim"
    "themes"
    "yazi"
)

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$DOTFILES_DIR/config/$dir" ]; then
        backup_and_link "$DOTFILES_DIR/config/$dir" "$HOME/.config/$dir"
    else
        echo "  Warning: $DOTFILES_DIR/config/$dir not found, skipping"
    fi
done

echo ""
echo "=== Setting up OpenCode config ==="
if [ -d "$HOME/.config/opencode" ]; then
    if [ -L "$HOME/.config/opencode" ]; then
        rm "$HOME/.config/opencode"
    else
        echo "  Backing up existing opencode config"
        mkdir -p "$BACKUP_DIR"
        mv "$HOME/.config/opencode" "$BACKUP_DIR/"
    fi
fi
cp -R "$DOTFILES_DIR/config/opencode" "$HOME/.config/opencode"

echo ""
echo "=== Setting up secrets file ==="
if [ ! -f "$HOME/.zshrc.local" ]; then
    cp "$DOTFILES_DIR/.zshrc.local.template" "$HOME/.zshrc.local"
    echo "  Created .zshrc.local from template"
    echo "  IMPORTANT: Open ~/.zshrc.local and fill in your secrets!"
else
    echo "  .zshrc.local already exists"
fi

echo ""
echo "=== Installing nerd fonts ==="
mkdir -p ~/.local/share/fonts
cd /tmp
for font in Hack Meslo NerdFontsSymbolsOnly; do
  curl -fLo "nerd-fonts-${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
  unzip -o "nerd-fonts-${font}.zip" -d ~/.local/share/fonts
  rm "nerd-fonts-${font}.zip"
done
rm -rf /home/linuxbrew/.linuxbrew/var/cache/fontconfig 2>/dev/null || true
fc-cache -f -v || true
cd "$DOTFILES_DIR"

echo "=== Installing system packages via apt ==="
sudo apt update
sudo apt install -y playerctl steam-devices

echo "=== Installing gcloud CLI ==="
if ! command -v gcloud &> /dev/null; then
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google-cloud-sdk.gpg
  echo "deb [signed-by=/usr/share/keyrings/google-cloud-sdk.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
  sudo apt update && sudo apt install -y google-cloud-cli
fi

echo "=== Running brew bundle ==="
brew bundle install --file="$DOTFILES_DIR/Brewfile_linux"

echo "=== Installing Flatpak apps ==="
flatpak install -y flathub \
  com.google.AndroidStudio \
  com.bitwarden.desktop \
  com.brave.Browser \
  com.usebruno.Bruno \
  io.dbeaver.DBeaverCommunity \
  com.discordapp.Discord \
  dev.lapce.lapce \
  md.obsidian.Obsidian \
  org.signal.Signal \
  com.spotify.Client \
  com.valvesoftware.Steam \
  com.sublimetext.three \
  org.telegram.desktop \
  com.todoist.Todoist \
  org.videolan.VLC \
  org.wezfurlong.wezterm \
  dev.zed.Zed \
  com.usebottles.bottles

echo "=== Setup complete ==="
