#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
LINKS_ONLY=0

if [ "${1:-}" = "--links-only" ]; then
    LINKS_ONLY=1
    shift
fi

if [ "$#" -gt 0 ]; then
    echo "Usage: $0 [--links-only]" >&2
    exit 2
fi

backup_and_link() {
    local source="$1"
    local target="$2"
    local resolved_source
    resolved_source=$(readlink -f "$source")
    
    if [ -L "$target" ]; then
        current_target=$(readlink -f "$target")
        if [ "$current_target" = "$resolved_source" ]; then
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

need_cmd() {
    command -v "$1" >/dev/null 2>&1
}

copy_dir_if_changed() {
    local source="$1"
    local target="$2"
    local resolved_source
    resolved_source=$(readlink -f "$source")

    if [ -L "$target" ]; then
        current_target=$(readlink -f "$target")
        if [ "$current_target" = "$resolved_source" ]; then
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

setup_agent_skills() {
    local source_dir="$DOTFILES_DIR/agents/skills"
    local target_dir="$HOME/.agents/skills"

    echo ""
    echo "=== Setting up global agent skills ==="

    if need_cmd pi; then
        for package in \
            "git:github.com/obra/superpowers" \
            "https://github.com/cathrynlavery/diagram-design"
        do
            pi install "$package"
        done
    else
        echo "  pi not found; skipping Pi package installs"
    fi

    if [ ! -d "$source_dir" ]; then
        echo "  Warning: $source_dir not found, skipping managed skill symlinks"
        return 0
    fi

    mkdir -p "$target_dir"
    for skill_dir in "$source_dir"/*; do
        [ -d "$skill_dir" ] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        ln -sfn "$skill_dir" "$target_dir/$skill_name"
        echo "  Linked $skill_name"
    done
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
# OpenCode config is symlinked so agents, commands, and local edits stay
# connected to this repo like the rest of the dotfiles.
if [ -d "$DOTFILES_DIR/config/opencode" ]; then
    backup_and_link "$DOTFILES_DIR/config/opencode" "$HOME/.config/opencode"
else
    echo "  Warning: $DOTFILES_DIR/config/opencode not found, skipping"
fi

setup_agent_skills

echo ""
echo "=== Setting up secrets file ==="
if [ ! -f "$HOME/.zshrc.local" ]; then
    cp "$DOTFILES_DIR/.zshrc.local.template" "$HOME/.zshrc.local"
    echo "  Created .zshrc.local from template"
    echo "  IMPORTANT: Open ~/.zshrc.local and fill in your secrets!"
else
    echo "  .zshrc.local already exists"
fi

if [ "$LINKS_ONLY" -eq 1 ]; then
    echo ""
    echo "=== Links-only setup complete ==="
    exit 0
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
if need_cmd apt; then
  sudo apt update
  sudo apt install -y playerctl steam-devices
else
  echo "  apt not found; skipping apt packages"
  echo "  On Fedora/Bazzite, prefer Flatpak/Homebrew. If needed, manually layer host packages with rpm-ostree."
fi

echo "=== Installing gcloud CLI ==="
if need_cmd gcloud; then
  echo "  gcloud already installed"
elif need_cmd apt; then
  if [ ! -f /usr/share/keyrings/google-cloud-sdk.gpg ]; then
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google-cloud-sdk.gpg
  fi
  if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
    echo "deb [signed-by=/usr/share/keyrings/google-cloud-sdk.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
  fi
  sudo apt update && sudo apt install -y google-cloud-cli
elif need_cmd brew; then
  brew install google-cloud-sdk
else
  echo "  Neither apt nor brew found; install gcloud manually and rerun if needed"
fi

echo "=== Running brew bundle ==="
if need_cmd brew; then
  # Homebrew now requires explicit trust for some third-party taps in non-interactive bundle runs.
  for tap in \
    bgreenwell/xleak \
    dagger/tap \
    dart-lang/dart \
    dopplerhq/cli \
    oven-sh/bun \
    steipete/tap
  do
    brew trust "$tap" >/dev/null 2>&1 || true
  done
  brew bundle install --file "$DOTFILES_DIR/Brewfile_linux"
else
  echo "  Homebrew not found; install Homebrew and rerun this script for CLI packages"
fi

echo "=== Installing Flatpak apps ==="
if need_cmd flatpak; then
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
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
else
  echo "  flatpak not found; skipping GUI apps"
fi

echo "=== Setup complete ==="
