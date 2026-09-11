# Dotfiles

My personal development environment configuration files for macOS.

**IMPORTANT:** These are my personal configs - use them as inspiration rather
than blindly copying. Proceed at your own risk!

## What's Included

- **Shell:** Zsh with oh-my-zsh, starship prompt, and various plugins
- **Editor:** Neovim (LazyVim-based config)
- **Terminal:** Ghostty and tmux
- **Tools:** fzf, eza, bat, zoxide, tmuxinator, lazygit, and more
- **Agent skills:** selected global skills for Pi/agent workflows, plus Superpowers as a Pi package

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

# Or skip Homebrew package installation
./install.sh --skip-brew
```

The install script will:

1. Backup any existing configs to `~/.dotfiles-backup/`
2. Create symlinks from the repo to your home directory
3. Symlink tmux, tmuxinator, and Neovim configs
4. Link managed skills from `agents/skills/` into `~/.agents/skills/`
5. Install Obra/Superpowers as a Pi package when `pi` is available
6. Create a `.zshrc.local` template for your secrets
7. Optionally install Homebrew packages (skip with `--skip-brew` or `--no-brew`)

Use `--dry-run` to see what would happen without making any changes.

## Unraid / Tower

Use `unraid_install.sh` on Unraid instead of the general-purpose install
scripts. It preserves Tower's `/boot/config`-managed shell files, restores only
Unraid-safe symlinks, installs global agent skills, updates Pi and installed Pi
packages, bootstraps OpenBSD `nc` for Herdr Unix-socket navigation, and restores
Neovim plugins from the lockfile without leaving `lazy-lock.json` dirty.

```bash
./unraid_install.sh --dry-run
./unraid_install.sh

# Same manual update path, named for operator clarity
./unraid_install.sh --upgrade

# Array-start mode: no git pull, network Pi package installs, Pi updates, or Neovim sync
./unraid_install.sh --startup

# Useful local controls
./unraid_install.sh --no-git-pull --no-pi-update --no-nvim-sync
```

The script is idempotent. Re-running it updates the dotfiles checkout with
`git pull --ff-only`, reasserts the symlinks, ensures required Pi packages are
installed, runs `pi update --all`, checks OpenBSD `nc`, and restores Neovim
plugins from the committed lockfile.

For Minuet AI completion on Tower, set `FIREWORKS_API_KEY` in the private
persistent file `/boot/config/shell/.zshrc.local`; it is restored to
`/root/.zshrc.local` at boot.

## Directory Structure

```
dotfiles/
├── .gitignore
├── .zshrc                    # Main shell config
├── .zshrc.local.template     # Template for secrets/API keys
├── .tmux.conf                # Tmux config
├── .tmuxinator/              # Tmuxinator project configs
├── Brewfile                  # Homebrew packages
├── install.sh                # General setup script
├── linux_install.sh          # Linux workstation setup script
├── bazzite_install.sh        # Bazzite workstation setup script
├── unraid_install.sh         # Tower/Unraid-safe setup script
├── README.md
├── agents/                   # Managed global agent skills
│   └── skills/
└── config/                   # ~/.config contents
    ├── bat/                  # Bat syntax highlighter themes
    ├── ghostty/              # Ghostty terminal
    ├── git/                  # Git global ignore
    ├── herdr/                # Herdr agent workspace manager
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

## Agent Skills

Selected skills are tracked in `agents/skills/` and linked into
`~/.agents/skills/` by every install script.

Currently managed:

- `grill-me`
- `domain-modeling`
- `codebase-design`
- `improve-codebase-architecture`
- `unslop`

The install scripts also install these Pi packages when `pi` is available:

```bash
pi install git:github.com/obra/superpowers
pi install https://github.com/cathrynlavery/diagram-design
```

Superpowers is intentionally installed as a Pi package rather than vendored in
this repository so its Pi extension can provide the startup/compaction
bootstrap behavior. Use Superpowers' `writing-skills`; do not keep an older
global `~/.agents/skills/writing-skills` copy, because that creates a duplicate
skill warning in Pi. Diagram Design is also installed as a Pi package to avoid
creating a duplicate global `diagram-design` skill when the Pi package is
already present.

## Homebrew

Packages are managed via Brewfile:

```bash
# Export current packages (on existing machine)
brew bundle dump --force --no-describe --file Brewfile

# Install packages (on new machine)
brew bundle install --file Brewfile
```

## Key Tools

### Terminal & Shell

- [Ghostty](https://ghostty.org/) - GPU-accelerated terminal
- [tmux](https://github.com/tmux/tmux/wiki) - Terminal multiplexer
- [tmuxinator](https://github.com/tmuxinator/tmuxinator) - Tmux session manager
- [Herdr](https://herdr.dev/) - AI-agent workspace manager
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
- `config/nvim` is symlinked to `~/.config/nvim` by the install scripts

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
