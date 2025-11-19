# Dotfiles

My personal development environment configuration files for macOS.

**IMPORTANT:** These are my personal configs - use them as inspiration rather
than blindly copying. Proceed at your own risk!

## What's Included

- **Shell:** Zsh with oh-my-zsh, starship prompt, and various plugins
- **Editor:** Neovim (LazyVim-based config)
- **Terminal:** Ghostty
- **Tools:** fzf, eza, bat, zoxide, lazygit, and more

## Quick Start

```bash
# Clone the repo (wherever you prefer)
git clone https://github.com/accolver/dotfiles.git
cd dotfiles

# Preview what will happen (recommended first)
chmod +x install.sh
./install.sh --dry-run

# Run the install script
./install.sh
```

The install script will:

1. Backup any existing configs to `~/.dotfiles-backup/`
2. Create symlinks from the repo to your home directory
3. Create a `.zshrc.local` template for your secrets
4. Optionally install Homebrew packages

Use `--dry-run` to see what would happen without making any changes.

## Directory Structure

```
dotfiles/
├── .gitignore
├── .zshrc                    # Main shell config
├── .zshrc.local.template     # Template for secrets/API keys
├── Brewfile                  # Homebrew packages
├── install.sh                # Setup script
├── README.md
└── config/                   # ~/.config contents
    ├── bat/                  # Bat syntax highlighter themes
    ├── ghostty/              # Ghostty terminal
    ├── git/                  # Git global ignore
    ├── ncspot/               # Spotify TUI
    ├── nvim/                 # Neovim config (LazyVim)
    ├── opencode/             # OpenCode AI config & agents
    ├── themes/               # Shared themes
    └── yazi/                 # Yazi file manager
```

## Secrets Management

Sensitive data (API keys, tokens) are stored in `~/.zshrc.local` which is
git-ignored.

On a new machine:

1. The install script creates `~/.zshrc.local` from the template
2. Edit the file and replace placeholder values with real secrets
3. Run `./install.sh --inject-secrets` to update config files

The `--inject-secrets` flag reads `CONTEXT7_API_KEY` and `FIRECRAWL_API_KEY`
from your `.zshrc.local` and injects them into
`~/.config/opencode/opencode.jsonc`.

## Homebrew

Packages are managed via Brewfile:

```bash
# Export current packages (on existing machine)
brew bundle dump --force --file=Brewfile

# Install packages (on new machine)
brew bundle install --file=Brewfile
```

## Key Tools

### Terminal & Shell

- [Ghostty](https://ghostty.org/) - GPU-accelerated terminal
- [Starship](https://starship.rs/) - Cross-shell prompt
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

### CLI Tools

- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [eza](https://github.com/eza-community/eza) - Modern ls replacement
- [bat](https://github.com/sharkdp/bat) - Cat with syntax highlighting
- [zoxide](https://github.com/ajeetdsouza/zoxide) - Smarter cd
- [lazygit](https://github.com/jesseduffield/lazygit) - Git TUI
- [yazi](https://github.com/sxyazi/yazi) - Terminal file manager
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast grep

### Editor

- [Neovim](https://neovim.io/) with LazyVim
- Tokyo Night theme

## Shell Aliases

Some useful aliases defined in `.zshrc`:

```bash
# Navigation & Files
ls    # eza with icons
ll    # eza with details
v     # nvim
y     # yazi with cd on exit
z     # zoxide jump
lg    # lazygit
c     # clear

# Terragrunt (with sound notification)
tgp   # terragrunt plan
tga   # terragrunt apply
tgi   # terragrunt init

# OpenCode
oc    # opencode
ocs   # opencode serve
oca   # opencode attach

# Utilities
x <cmd>  # Run command with timing and sound notification
```

## Manual Setup Steps

Some things require manual setup:

1. **Oh My Zsh:** Install if not present

   ```bash
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

2. **Python (pyenv):** Install a Python version

   ```bash
   pyenv install 3.12
   pyenv global 3.12
   ```

3. **Node (nvm):** Install a Node version

   ```bash
   nvm install --lts
   ```

## License

MIT - Use freely, but don't blame me if something breaks!
