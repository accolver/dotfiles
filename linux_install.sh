#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

backup_and_link() {
    local source="$1"
    local target="$2"
    
    if [ -L "$target" ]; then
        current_target=$(readlink -f "$target")
        if [ "$current_target" = "$source" ]; then
            echo "  Already linked: $source -> $target"
            return 0
        fi
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "  Backing up existing $target"
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/"
    fi
    
    echo "  Linking $source -> $target"
    ln -sf "$source" "$target"
}

copy_dir_if_changed() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        current_target=$(readlink -f "$target")
        if [ "$current_target" = "$source" ]; then
            echo "  Already linked: $source -> $target"
            return 0
        fi
    fi

    if [ -d "$target" ] && diff -qr "$source" "$target" >/dev/null 2>&1; then
        echo "  $target already up to date"
        return 0
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "  $target already exists and differs; leaving it unchanged"
        echo "  Remove it manually if you want a fresh copy from $source"
        return 0
    fi

    echo "  Copying $source -> $target"
    cp -R "$source" "$target"
}

install_nerd_font() {
    local font="$1"
    local marker="$HOME/.local/share/fonts/.dotfiles-${font}-installed"

    if [ -f "$marker" ]; then
        echo "  $font Nerd Font already installed"
        return 0
    fi

    curl -fLo "nerd-fonts-${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
    unzip -o "nerd-fonts-${font}.zip" -d "$HOME/.local/share/fonts"
    rm -f "nerd-fonts-${font}.zip"
    touch "$marker"
}

echo "=== Setting up home-directory dotfiles ==="
backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

echo ""
echo "=== Setting up tmuxinator configs ==="
mkdir -p "$HOME/.tmuxinator"
for file in "$DOTFILES_DIR"/.tmuxinator/*.yml; do
    if [ -f "$file" ]; then
        backup_and_link "$file" "$HOME/.tmuxinator/$(basename "$file")"
    fi
done

echo ""
echo "=== Setting up .config directories ==="
mkdir -p "$HOME/.config"

CONFIG_DIRS=(
    "bat"
    "ghostty"
    "git"
    "ncspot"
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
echo "=== Setting up Neovim config ==="
# Neovim is managed as a full-directory symlink so local config edits stay
# connected to this repo. Plugin data/cache remain in Neovim's stdpath dirs.
if [ -d "$DOTFILES_DIR/config/nvim" ]; then
    backup_and_link "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
else
    echo "  Warning: $DOTFILES_DIR/config/nvim not found, skipping"
fi

echo ""
echo "=== Setting up Herdr config ==="
# Herdr stores runtime sockets/sessions in ~/.config/herdr, so symlink only
# the static config and helper script instead of the whole directory.
if [ -f "$DOTFILES_DIR/config/herdr/config.toml" ] && [ -f "$DOTFILES_DIR/config/herdr/smart-pane-nav.sh" ]; then
    mkdir -p "$HOME/.config/herdr"
    backup_and_link "$DOTFILES_DIR/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    backup_and_link "$DOTFILES_DIR/config/herdr/smart-pane-nav.sh" "$HOME/.config/herdr/smart-pane-nav.sh"
else
    echo "  Warning: Herdr static config files not found, skipping"
fi

echo ""
echo "=== Building bat theme cache ==="
if command -v bat &> /dev/null; then
    bat cache --build
    echo "  bat theme cache built."
else
    echo "  bat not found, skipping cache build (will be built after brew install)"
fi

echo ""
echo "=== Setting up OpenCode config ==="
copy_dir_if_changed "$DOTFILES_DIR/config/opencode" "$HOME/.config/opencode"

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
mkdir -p "$HOME/.local/share/fonts"
cd /tmp
for font in Hack Meslo NerdFontsSymbolsOnly; do
  install_nerd_font "$font"
done
rm -rf /home/linuxbrew/.linuxbrew/var/cache/fontconfig 2>/dev/null || true
fc-cache -f -v || true
cd "$DOTFILES_DIR"

echo "=== Installing system packages via apt ==="
sudo apt update
sudo apt install -y playerctl steam-devices

echo "=== Installing gcloud CLI ==="
if ! command -v gcloud &> /dev/null; then
  if [ ! -f /usr/share/keyrings/google-cloud-sdk.gpg ]; then
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google-cloud-sdk.gpg
  fi
  if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
    echo "deb [signed-by=/usr/share/keyrings/google-cloud-sdk.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
  fi
  sudo apt update && sudo apt install -y google-cloud-cli
else
  echo "  gcloud already installed"
fi

echo "=== Running brew bundle ==="
brew bundle install --file "$DOTFILES_DIR/Brewfile_linux"

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
