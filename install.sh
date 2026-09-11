#!/bin/bash

set -e

# Determine dotfiles directory (where this script lives)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
SKIP_BREW="${SKIP_BREW:-false}"
if [ "$SKIP_BREW" = "1" ]; then
    SKIP_BREW=true
fi
INJECT_SECRETS=false

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --dry-run              Show what would happen without making changes
  --skip-brew, --no-brew Skip Homebrew package installation
  --inject-secrets       Inject secrets into configuration files and exit
  -h, --help             Show this help message
EOF
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-brew|--no-brew)
            SKIP_BREW=true
            shift
            ;;
        --inject-secrets)
            INJECT_SECRETS=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE ==="
    echo "No changes will be made. Showing what would happen..."
    echo ""
fi

echo "Starting Dotfiles Setup..."
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Function to backup and symlink
backup_and_link() {
    local source="$1"
    local target="$2"
    
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$source" ]; then
        echo "  $target already linked"
        return 0
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  [DRY RUN] Would backup $target to $BACKUP_DIR/"
        else
            echo "  Backing up existing $target"
            mkdir -p "$BACKUP_DIR"
            mv "$target" "$BACKUP_DIR/"
        fi
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would link $source -> $target"
    else
        echo "  Linking $source -> $target"
        ln -sfn "$source" "$target"
    fi
}

setup_opencode_config() {
    local source="$DOTFILES_DIR/config/opencode"
    local target="$HOME/.config/opencode"

    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$source" ]; then
        echo "  $target already linked"
        return 0
    fi

    if [ -d "$target" ] && diff -qr "$source" "$target" >/dev/null 2>&1; then
        echo "  $target already up to date"
        return 0
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "  $target already exists; leaving it unchanged to avoid overwriting local secrets"
        echo "  Remove it manually if you want a fresh copy from $source"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would copy $source to $target"
    else
        echo "  Copying $source -> $target"
        cp -R "$source" "$target"
    fi
}

setup_agent_skills() {
    local source_dir="$DOTFILES_DIR/agents/skills"
    local target_dir="$HOME/.agents/skills"

    echo ""
    echo "Setting up global agent skills..."

    if command -v pi >/dev/null 2>&1; then
        for package in \
            "git:github.com/obra/superpowers" \
            "https://github.com/cathrynlavery/diagram-design"
        do
            if [ "$DRY_RUN" = true ]; then
                echo "  [DRY RUN] Would run: pi install $package"
            else
                pi install "$package"
            fi
        done
    else
        echo "  pi not found; skipping Pi package installs"
    fi

    if [ ! -d "$source_dir" ]; then
        echo "  Warning: $source_dir not found, skipping managed skill symlinks"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would create $target_dir"
    else
        mkdir -p "$target_dir"
    fi

    for skill_dir in "$source_dir"/*; do
        [ -d "$skill_dir" ] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        if [ -L "$target_dir/$skill_name" ] && [ "$(readlink -f "$target_dir/$skill_name")" = "$skill_dir" ]; then
            echo "  $skill_name already linked"
            continue
        fi
        if [ "$DRY_RUN" = true ]; then
            echo "  [DRY RUN] Would link $skill_dir -> $target_dir/$skill_name"
        else
            ln -sfn "$skill_dir" "$target_dir/$skill_name"
            echo "  Linked $skill_name"
        fi
    done
}

# 1. Create Symlinks for home-directory dotfiles
echo "Setting up home-directory dotfiles..."
backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# 2. Setup tmuxinator project configs
echo ""
echo "Setting up tmuxinator configs..."
if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would create $HOME/.tmuxinator"
else
    mkdir -p "$HOME/.tmuxinator"
fi

for file in "$DOTFILES_DIR"/.tmuxinator/*.yml; do
    if [ -f "$file" ]; then
        backup_and_link "$file" "$HOME/.tmuxinator/$(basename "$file")"
    fi
done

# 3. Setup .config directory symlinks
echo ""
echo "Setting up .config directories..."
if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would create $HOME/.config"
else
    mkdir -p "$HOME/.config"
fi

# Directories to symlink directly
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

# Neovim is managed as a full-directory symlink so local config edits stay
# connected to this repo. Plugin data/cache remain in Neovim's stdpath dirs.
echo ""
echo "Setting up Neovim config..."
if [ -d "$DOTFILES_DIR/config/nvim" ]; then
    backup_and_link "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
else
    echo "  Warning: $DOTFILES_DIR/config/nvim not found, skipping"
fi

# Herdr stores runtime sockets/sessions in ~/.config/herdr, so symlink only
# the static config and helper script instead of the whole directory.
echo ""
echo "Setting up Herdr config..."
if [ -f "$DOTFILES_DIR/config/herdr/config.toml" ] && [ -f "$DOTFILES_DIR/config/herdr/smart-pane-nav.sh" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would create $HOME/.config/herdr"
    else
        mkdir -p "$HOME/.config/herdr"
    fi
    backup_and_link "$DOTFILES_DIR/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    backup_and_link "$DOTFILES_DIR/config/herdr/smart-pane-nav.sh" "$HOME/.config/herdr/smart-pane-nav.sh"
else
    echo "  Warning: Herdr static config files not found, skipping"
fi

# Build bat theme cache so custom themes are available
echo ""
echo "Building bat theme cache..."
if command -v bat &> /dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would run: bat cache --build"
    else
        bat cache --build
        echo "  bat theme cache built."
    fi
else
    echo "  bat not found, skipping cache build (install bat first, then run: bat cache --build)"
fi

# OpenCode needs special handling (copy + substitute secrets)
echo ""
echo "Setting up OpenCode config..."
setup_opencode_config

setup_agent_skills

# 4. Setup Secrets File
echo ""
echo "Setting up secrets file..."
if [ ! -f "$HOME/.zshrc.local" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would create ~/.zshrc.local from template"
    else
        echo "  Creating .zshrc.local from template..."
        cp "$DOTFILES_DIR/.zshrc.local.template" "$HOME/.zshrc.local"
        echo ""
        echo "  ⚠️  IMPORTANT: Open ~/.zshrc.local and fill in your secrets!"
        echo "  Then run: ./install.sh --inject-secrets"
    fi
else
    echo "  .zshrc.local already exists."
fi

# 5. Inject secrets into config files
inject_secrets() {
    echo ""
    echo "Injecting secrets into config files..."
    
    # Source the secrets
    if [ -f "$HOME/.zshrc.local" ]; then
        source "$HOME/.zshrc.local"
    else
        echo "  Error: ~/.zshrc.local not found. Create it first."
        return 1
    fi
    
    # Check if secrets are set
    if [ "$CONTEXT7_API_KEY" = "REPLACE_WITH_REAL_KEY" ] || [ -z "$CONTEXT7_API_KEY" ]; then
        echo "  Warning: CONTEXT7_API_KEY not set in ~/.zshrc.local"
    fi
    if [ "$FIRECRAWL_API_KEY" = "REPLACE_WITH_REAL_KEY" ] || [ -z "$FIRECRAWL_API_KEY" ]; then
        echo "  Warning: FIRECRAWL_API_KEY not set in ~/.zshrc.local"
    fi
    
    # Substitute in opencode config
    local opencode_config="$HOME/.config/opencode/opencode.jsonc"
    if [ -f "$opencode_config" ]; then
        sed -i '' "s/REPLACE_WITH_YOUR_CONTEXT7_API_KEY/$CONTEXT7_API_KEY/g" "$opencode_config"
        sed -i '' "s/REPLACE_WITH_YOUR_FIRECRAWL_API_KEY/$FIRECRAWL_API_KEY/g" "$opencode_config"
        echo "  Updated $opencode_config"
    fi
    
    echo "  Secrets injected!"
}

# Handle --inject-secrets flag
if [ "$INJECT_SECRETS" = true ]; then
    inject_secrets
    exit 0
fi

# 6. Install Homebrew Packages
echo ""
if [ "$SKIP_BREW" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Skipping Brewfile installation (--skip-brew)"
    else
        echo "Skipping Brewfile installation (--skip-brew)"
    fi
elif [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would prompt to install Brewfile dependencies"
else
    echo "Checking Homebrew..."
    if command -v brew &> /dev/null; then
        if [ -t 0 ]; then
            read -p "Install Brewfile dependencies? (y/n) " -n 1 -r || REPLY="n"
            echo
        else
            echo "Non-interactive session detected; skipping Brewfile dependencies."
            REPLY="n"
        fi
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installing Brewfile dependencies..."
            brew bundle install --file "$DOTFILES_DIR/Brewfile"
        else
            echo "Skipping Brewfile installation."
        fi
    else
        echo "  Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
fi

echo ""
echo "============================================"
if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN complete! No changes were made."
    echo ""
    echo "Run without --dry-run to apply changes."
else
    echo "Setup complete!"
    echo ""
    if [ -d "$BACKUP_DIR" ]; then
        echo "Backups saved to: $BACKUP_DIR"
    fi
    echo ""
    echo "Next steps:"
    echo "  1. Fill in secrets: vim ~/.zshrc.local"
    echo "  2. Inject secrets: ./install.sh --inject-secrets"
    echo "  3. Restart your terminal or run: source ~/.zshrc"
fi
echo "============================================"
