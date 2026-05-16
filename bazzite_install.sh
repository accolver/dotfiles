#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

backup_and_link() {
    local source="$1"
    local target="$2"

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            local current_target
            current_target="$(readlink -f "$target")"
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
    ln -sfn "$source" "$target"
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1
}

ensure_flatpak_remote() {
    if ! flatpak remote-list | grep -q '^flathub'; then
        echo "=== Adding Flathub remote ==="
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
}

echo "=== Setting up SSH for GitHub ==="
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$HOME/.ssh/id_github" ]; then
    chmod 600 "$HOME/.ssh/id_github"
fi
if [ -f "$HOME/.ssh/id_github.pub" ]; then
    chmod 644 "$HOME/.ssh/id_github.pub"
fi

cat > "$HOME/.ssh/config" <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_github
  IdentitiesOnly yes
EOF
chmod 600 "$HOME/.ssh/config"

if need_cmd ssh-add && [ -f "$HOME/.ssh/id_github" ]; then
    if ! ssh-add -l >/dev/null 2>&1; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    ssh-add "$HOME/.ssh/id_github" || true
fi

echo ""
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
echo "=== Building bat theme cache ==="
if need_cmd bat; then
    bat cache --build
    echo "  bat theme cache built."
else
    echo "  bat not found yet, skipping cache build"
fi

echo ""
echo "=== Setting up OpenCode config ==="
if [ -d "$HOME/.config/opencode" ] || [ -L "$HOME/.config/opencode" ]; then
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
    echo "  IMPORTANT: Open ~/.zshrc.local and fill in your secrets"
else
    echo "  .zshrc.local already exists"
fi

echo ""
echo "=== Installing nerd fonts ==="
mkdir -p "$HOME/.local/share/fonts"
pushd /tmp >/dev/null
for font in Hack Meslo NerdFontsSymbolsOnly; do
  curl -fLo "nerd-fonts-${font}.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
  unzip -o "nerd-fonts-${font}.zip" -d "$HOME/.local/share/fonts"
  rm -f "nerd-fonts-${font}.zip"
done
rm -rf /home/linuxbrew/.linuxbrew/var/cache/fontconfig 2>/dev/null || true
fc-cache -f -v || true
popd >/dev/null

echo ""
echo "=== Ensuring Homebrew is available ==="
if ! need_cmd brew; then
    echo "Homebrew not found."
    echo "On Bazzite, install Homebrew first, then rerun this script."
    echo "Docs: https://docs.bazzite.gg/Installing_and_Managing_Software/Homebrew/"
    exit 1
fi

echo ""
echo "=== Running brew bundle ==="
brew bundle install --file="$DOTFILES_DIR/Brewfile_linux"

echo ""
echo "=== Installing gcloud CLI via Homebrew ==="
if ! need_cmd gcloud; then
    brew install --quiet google-cloud-sdk
else
    echo "  gcloud already installed"
fi

echo ""
echo "=== Installing/ensuring CLI tools via Homebrew ==="
BREW_PACKAGES=(
  playerctl
)
for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" >/dev/null 2>&1; then
        echo "  $pkg already installed"
    else
        brew install "$pkg"
    fi
done

echo ""
echo "=== Installing Flatpak apps ==="
ensure_flatpak_remote
flatpak install -y flathub \
  com.google.AndroidStudio \
  com.bitwarden.desktop \
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

echo ""
echo "=== Optional host layering for Fedora/Bazzite-only packages ==="
echo "Skipping rpm-ostree layering by default."
echo "If you truly need a host package not available via Flatpak/Homebrew/Distrobox,"
echo "use something like:"
echo "  sudo rpm-ostree install <package>"
echo "Then reboot."
echo ""
echo "Potential example:"
echo "  sudo rpm-ostree install steam-devices"
echo "Only do this if you confirm you actually need it on your setup."

echo ""
echo "=== Rebuilding bat cache after installs ==="
if need_cmd bat; then
    bat cache --build || true
fi

echo ""
echo "=== Setup complete ==="
echo "Recommended next steps:"
echo "  1. source ~/.zshrc"
echo "  2. ssh -T git@github.com"
echo "  3. Open ~/.zshrc.local and fill in secrets"
