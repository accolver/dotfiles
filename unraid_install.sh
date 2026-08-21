#!/bin/bash
set -Eeuo pipefail

# Tower/Unraid-specific dotfiles bootstrap.
#
# This intentionally avoids the macOS/Linux install scripts' broad home-directory
# replacement behavior. On Unraid, /root and /usr/local are RAM-backed, while
# durable configuration belongs under /boot/config or /mnt/user/appdata.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=false
STARTUP_MODE=false
MODE="interactive"
SYNC_DOTFILES=true
SYNC_NVIM=true
INSTALL_PI_PACKAGES=true
UPDATE_PI_PACKAGES=true

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--upgrade] [--startup] [--no-git-pull] [--no-pi-update] [--no-nvim-sync]

  --dry-run       Show actions without changing files.
  --upgrade       Explicit manual upgrade mode. Same network-capable behavior as
                  the default interactive run, but named for operator clarity.
  --startup       Fast array-start mode: relink local config/skills, skip network
                  package installs, Pi updates, git pulls, and Neovim sync.
  --no-git-pull   Do not pull this dotfiles repository.
  --no-pi-update  Do not run pi update. Pi package installs still ensure required
                  packages are present.
  --no-nvim-sync  Skip Neovim Lazy sync.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --upgrade) MODE="upgrade" ;;
    --startup) STARTUP_MODE=true; MODE="startup"; SYNC_DOTFILES=false; SYNC_NVIM=false; INSTALL_PI_PACKAGES=false; UPDATE_PI_PACKAGES=false ;;
    --no-git-pull) SYNC_DOTFILES=false ;;
    --no-pi-update) UPDATE_PI_PACKAGES=false ;;
    --no-nvim-sync) SYNC_NVIM=false ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

run() {
  if [ "$DRY_RUN" = true ]; then
    printf '  [DRY RUN] %q' "$1"
    shift
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

is_unraid() {
  [ -f /etc/os-release ] && grep -q '^ID="\?unraid-os"\?$' /etc/os-release
}

sync_dotfiles_repo() {
  echo "=== Updating dotfiles repository ==="

  if [ "$SYNC_DOTFILES" != true ]; then
    if [ "$STARTUP_MODE" = true ]; then
      echo "  Startup mode: skipping dotfiles git pull"
    else
      echo "  Skipping dotfiles git pull"
    fi
    return 0
  fi

  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "  $DOTFILES_DIR is not a Git checkout; skipping pull"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "  git not found; skipping pull"
    return 0
  fi

  run git -C "$DOTFILES_DIR" pull --ff-only
}

backup_and_link() {
  local source="$1"
  local target="$2"
  local backup_dir="${BACKUP_DIR:-/root/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)}"
  local resolved_source current_target

  resolved_source="$(readlink -f "$source")"
  if [ -L "$target" ]; then
    current_target="$(readlink -f "$target" 2>/dev/null || true)"
    if [ "$current_target" = "$resolved_source" ]; then
      echo "  Already linked: $target -> $source"
      return 0
    fi
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "  Backing up existing $target to $backup_dir/"
    run mkdir -p "$backup_dir"
    run mv "$target" "$backup_dir/"
  fi

  echo "  Linking $target -> $source"
  run ln -sfnT "$source" "$target"
}

setup_unraid_links() {
  echo "=== Linking Unraid-safe dotfiles ==="
  run mkdir -p /root/.config/herdr /root/.config

  backup_and_link "$DOTFILES_DIR/config/nvim" /root/.config/nvim
  backup_and_link "$DOTFILES_DIR/config/herdr/config.toml" /root/.config/herdr/config.toml
  backup_and_link "$DOTFILES_DIR/config/herdr/smart-pane-nav.sh" /root/.config/herdr/smart-pane-nav.sh
  backup_and_link "$DOTFILES_DIR/.tmuxinator" /root/.tmuxinator

  echo "  Leaving /root/.zshrc and /root/.tmux.conf under /boot/config/shell management."
}

setup_agent_skills() {
  local source_dir="$DOTFILES_DIR/agents/skills"
  local target_dir="/root/.agents/skills"

  echo "=== Setting up global agent skills ==="

  if command -v pi >/dev/null 2>&1; then
    if [ "$INSTALL_PI_PACKAGES" = true ]; then
      for package in \
        "git:github.com/obra/superpowers" \
        "https://github.com/cathrynlavery/diagram-design"
      do
        echo "  Installing Pi package: $package"
        run pi install "$package"
      done
    else
      echo "  Startup mode: skipping network Pi package installs and updates"
    fi

    if [ "$UPDATE_PI_PACKAGES" = true ]; then
      echo "  Updating installed Pi packages"
      run pi update --all
    fi
  else
    echo "  pi not found; skipping Pi package installs and updates"
  fi

  if [ ! -d "$source_dir" ]; then
    echo "  Warning: $source_dir not found; skipping skill symlinks"
    return 0
  fi

  run mkdir -p "$target_dir"
  for skill_dir in "$source_dir"/*; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name="$(basename "$skill_dir")"
    echo "  Linking skill: $skill_name"
    run ln -sfnT "$skill_dir" "$target_dir/$skill_name"
  done
}

install_netcat_bootstrap() {
  echo "=== Ensuring OpenBSD nc bootstrap ==="

  if [ ! -d /boot/config ]; then
    echo "  /boot/config not found; skipping Unraid netcat bootstrap"
    return 0
  fi

  run mkdir -p /boot/config/custom
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would install /boot/config/custom/install-netcat-openbsd.sh"
  else
    cat >/boot/config/custom/install-netcat-openbsd.sh <<'NETCAT_SCRIPT'
#!/bin/bash
set -Eeuo pipefail

PKG_DIR="${PKG_DIR:-/boot/extra}"
mkdir -p "$PKG_DIR"

have_nc_unix_socket() {
  command -v nc >/dev/null 2>&1 && nc -h 2>&1 | grep -Eq -- '(^|[[:space:]])-U([,[:space:]]|$)|UNIX'
}

download_pkg() {
  local url="$1"
  local file="$2"
  local md5="$3"
  local dest="$PKG_DIR/$file"

  if [ -f "$dest" ] && echo "$md5  $dest" | md5sum -c - >/dev/null 2>&1; then
    return 0
  fi

  local tmp="$dest.tmp.$$"
  rm -f "$tmp"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$tmp"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$tmp" "$url"
  else
    echo "Neither curl nor wget is available to fetch $url" >&2
    return 1
  fi

  echo "$md5  $tmp" | md5sum -c - >/dev/null
  mv -f "$tmp" "$dest"
}

install_pkg_if_needed() {
  local file="$1"
  local package_name="$2"

  if ls "/var/log/packages/${package_name}"-* >/dev/null 2>&1; then
    return 0
  fi

  installpkg "$PKG_DIR/$file" >/dev/null
}

download_pkg \
  "https://download.salixos.org/x86_64/15.0/salix/l/libbsd-0.10.0-x86_64-1gv.txz" \
  "libbsd-0.10.0-x86_64-1gv.txz" \
  "48db666c87cda04dc2ca47f7e5cd9ac6"

download_pkg \
  "https://download.salixos.org/x86_64/extra-15.0/salix/network/netcat-openbsd-1.217_1-x86_64-1salix15.0.txz" \
  "netcat-openbsd-1.217_1-x86_64-1salix15.0.txz" \
  "4e540b5ba9d9b4bab974d677a530141a"

if ! have_nc_unix_socket; then
  install_pkg_if_needed "libbsd-0.10.0-x86_64-1gv.txz" "libbsd"
  install_pkg_if_needed "netcat-openbsd-1.217_1-x86_64-1salix15.0.txz" "netcat-openbsd"
fi

if ! have_nc_unix_socket; then
  echo "OpenBSD nc installed but Unix-socket support was not detected" >&2
  exit 1
fi

echo "OpenBSD nc is available at $(command -v nc)"
NETCAT_SCRIPT
  fi

  if [ -f /boot/tools/install-cli-tools.sh ] && \
    ! grep -qF '/boot/config/custom/install-netcat-openbsd.sh' /boot/tools/install-cli-tools.sh; then
    echo "  Adding netcat bootstrap call to /boot/tools/install-cli-tools.sh"
    if [ "$DRY_RUN" = true ]; then
      echo "  [DRY RUN] Would patch /boot/tools/install-cli-tools.sh"
    else
      local tmp
      tmp="$(mktemp)"
      awk '
        { print }
        /^}$/ && in_install_bin && ! inserted {
          print ""
          print "# OpenBSD netcat for Unix-domain socket support used by Herdr helpers."
          print "if [ -f /boot/config/custom/install-netcat-openbsd.sh ]; then"
          print "  bash /boot/config/custom/install-netcat-openbsd.sh"
          print "fi"
          inserted=1
          in_install_bin=0
          next
        }
        /^install_bin\(\) \{/ { in_install_bin=1 }
        END { if (!inserted) exit 42 }
      ' /boot/tools/install-cli-tools.sh >"$tmp" || {
        rm -f "$tmp"
        echo "could not patch /boot/tools/install-cli-tools.sh" >&2
        return 1
      }
      cat "$tmp" >/boot/tools/install-cli-tools.sh
      rm -f "$tmp"
    fi
  fi

  if [ "$DRY_RUN" = false ]; then
    bash -n /boot/config/custom/install-netcat-openbsd.sh
    bash /boot/config/custom/install-netcat-openbsd.sh
  fi
}

sync_neovim_plugins() {
  echo "=== Installing Neovim plugins ==="

  if [ "$SYNC_NVIM" != true ]; then
    echo "  Skipping Neovim sync"
    return 0
  fi

  if ! command -v nvim >/dev/null 2>&1; then
    echo "  nvim not found; skipping plugin sync"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would run: nvim --headless '+Lazy! restore' '+qa'"
    return 0
  fi

  local log="/tmp/unraid-dotfiles-nvim-lazy-sync.log"
  local lockfile="$DOTFILES_DIR/config/nvim/lazy-lock.json"
  local lockfile_backup=""

  # Lazy can prune optional/platform-specific entries from lazy-lock.json during
  # a headless restore. This installer should install plugins, not dirty the
  # dotfiles checkout, so restore the lockfile bytes after Neovim exits.
  if [ -f "$lockfile" ]; then
    lockfile_backup="$(mktemp)"
    cp -p "$lockfile" "$lockfile_backup"
  fi

  if nvim --headless '+Lazy! restore' '+qa' >"$log" 2>&1; then
    if [ -n "$lockfile_backup" ] && ! cmp -s "$lockfile_backup" "$lockfile"; then
      cp -p "$lockfile_backup" "$lockfile"
      echo "  Restored lazy-lock.json after plugin restore"
    fi
    [ -n "$lockfile_backup" ] && rm -f "$lockfile_backup"
    echo "  Neovim Lazy restore completed; log: $log"
  else
    local exit_code=$?
    if [ -n "$lockfile_backup" ]; then
      cp -p "$lockfile_backup" "$lockfile"
      rm -f "$lockfile_backup"
    fi
    echo "  Neovim Lazy restore failed; log: $log" >&2
    tail -80 "$log" >&2 || true
    return "$exit_code"
  fi
}

if ! is_unraid; then
  echo "Warning: this script is optimized for Unraid; continuing anyway." >&2
fi

echo "Dotfiles directory: $DOTFILES_DIR"
echo "Mode: $MODE"

sync_dotfiles_repo
setup_unraid_links
setup_agent_skills
install_netcat_bootstrap
sync_neovim_plugins

cat <<'EOF'

FIREWORKS_API_KEY:
  Put this in /root/.zshrc.local (never in the dotfiles repo):

    export FIREWORKS_API_KEY="..."

  For persistence on this Unraid host, put the real value in:

    /boot/config/shell/.zshrc.local

  /boot/config/shell/restore-shell-config.sh restores that private file to
  /root/.zshrc.local on boot. Keep it mode 600 and out of Git/backups.
EOF
