#!/bin/bash

set -e

# Determine dotfiles directory (where this script lives)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --inject-secrets)
            # Handled below
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
        ln -sf "$source" "$target"
    fi
}

# 1. Create Symlinks for .zshrc
echo "Setting up .zshrc..."
backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# 2. Setup .config directory symlinks
echo ""
echo "Setting up .config directories..."
mkdir -p "$HOME/.config"

# Directories to symlink directly
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

# OpenCode needs special handling (copy + substitute secrets)
echo ""
echo "Setting up OpenCode config..."
if [ -d "$HOME/.config/opencode" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would backup $HOME/.config/opencode to $BACKUP_DIR/"
    else
        echo "  Backing up existing opencode config"
        mkdir -p "$BACKUP_DIR"
        mv "$HOME/.config/opencode" "$BACKUP_DIR/"
    fi
fi
if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would copy $DOTFILES_DIR/config/opencode to $HOME/.config/opencode"
else
    cp -R "$DOTFILES_DIR/config/opencode" "$HOME/.config/opencode"
fi

# 3. Setup Secrets File
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

# 4. Inject secrets into config files
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
if [ "$1" = "--inject-secrets" ]; then
    inject_secrets
    exit 0
fi

# Skip Brewfile in dry-run mode
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "[DRY RUN] Would prompt to install Brewfile dependencies"
else
    # 5. Install Homebrew Packages
    echo ""
    echo "Checking Homebrew..."
    if command -v brew &> /dev/null; then
        read -p "Install Brewfile dependencies? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installing Brewfile dependencies..."
            brew bundle install --file="$DOTFILES_DIR/Brewfile"
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
