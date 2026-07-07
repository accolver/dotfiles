# Set up Homebrew environment early so all brew-installed tools are available
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Detect platform
case "$(uname -s)" in
    Linux*)     PLATFORM=linux ;;
    Darwin*)    PLATFORM=macos ;;
    *)          PLATFORM=unknown ;;
esac

# Add deno completions to search path
if [[ "$PLATFORM" == "Darwin" ]]; then
    if [[ ":$FPATH:" != *":/Users/alancolver/completions:"* ]]; then export FPATH="/Users/alancolver/completions:$FPATH"; fi
fi
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export EDITOR=nvim

# Load local machine configurations and secrets
if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi

# Ghostty over SSH can advertise TERM=xterm-ghostty, but this host may not
# have that terminfo entry. Fall back to a widely-supported terminal so
# backspace and redraw behave correctly.
if [[ -n "$SSH_TTY" && "$TERM" == "xterm-ghostty" ]]; then
  export TERM=xterm-256color
fi

alias ssh='TERM=xterm-256color ssh'

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.local/share/nvim/site/"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

BAT_THEME="tokyonight_storm"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(bun deno direnv docker gcloud git tmux tmuxinator)
source $ZSH/oh-my-zsh.sh


# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# autoload -U +X bashcompinit && bashcompinit
# if [[ "$PLATFORM" == "Darwin" ]]; then
#     complete -o nospace -C /opt/homebrew/bin/terragrunt terragrunt
# elif command -v terragrunt &>/dev/null; then
#     complete -o nospace -C $(which terragrunt) terragrunt
# fi

export GPG_TTY=$(tty)

source <(fzf --zsh)
export FZF_CTRL_T_OPTS="--preview 'bat -n --theme='tokyonight_storm' --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
ff() {
  aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}
# alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions --all"
alias ll="eza --color=always --long --git --no-filesize --icons=always --no-time --all"
alias python="python3"
alias c="clear"
alias mux="tmuxinator"
alias lg="lazygit"
alias claude-yolo="claude --dangerously-skip-permissions"
alias oc="opencode"

alias ts-up='tailscale set \
  --exit-node="us-slc-wg-302.mullvad.ts.net" \
  --exit-node-allow-lan-access=true \
  --accept-dns=true \
  --accept-routes=false'

alias ts-down='tailscale set --exit-node='

  # --exit-node="us-den-wg-101.mullvad.ts.net" \

ocs() { opencode serve --port ${1:-59121}; }
oca() { opencode attach http://127.0.0.1:${1:-59121}; }

# gs() {
#   gamescope -f -W 3440 -H 1440 -r 174 -- "$@"
# }

gs() {
  __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  gamescope -f -W 3440 -H 1440 -r 174 -S fit -- "$@"
}

if [[ "$PLATFORM" == "Darwin" ]]; then
    alias tga="time terragrunt apply; afplay /System/Library/Sounds/Glass.aiff; date"
    alias tgaa="time terragrunt apply -auto-approve; afplay /System/Library/Sounds/Glass.aiff; date"
    alias tgp="time terragrunt plan; afplay /System/Library/Sounds/Glass.aiff; date"
    alias tgr="time terragrunt plan -refresh=true; afplay /System/Library/Sounds/Glass.aiff; date"
    alias tgi="time terragrunt init; afplay /System/Library/Sounds/Glass.aiff; date"
    alias tgiu="time terragrunt init -upgrade; afplay /System/Library/Sounds/Glass.aiff; date"
else
    alias tga="time terragrunt apply; date"
    alias tgaa="time terragrunt apply -auto-approve; date"
    alias tgp="time terragrunt plan; date"
    alias tgr="time terragrunt plan -refresh=true; date"
    alias tgi="time terragrunt init; date"
    alias tgiu="time terragrunt init -upgrade; date"
fi

alias ttyd-local="ttyd -i 0.0.0.0 -W zsh"
alias v="nvim"

# Map caps key to esc
# hidutil property --set \
#'{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'


autoload -Uz compinit
compinit

# pnpm
if [[ "$PLATFORM" == "Darwin" ]]; then
    export PNPM_HOME="$HOME/Library/pnpm"
else
    export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun
export PATH="$PATH:$HOME/.bun/bin"
# bun end

# Java
if [[ "$PLATFORM" == "Darwin" ]]; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 21)
else
    if [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
        export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
    fi
fi

# Java Version Switcher
jdk() {
  version=$1
  if [[ "$PLATFORM" == "Darwin" ]]; then
      export JAVA_HOME=$(/usr/libexec/java_home -v "$version")
  else
      if [ -d "/usr/lib/jvm/java-${version}-openjdk-amd64" ]; then
          export JAVA_HOME="/usr/lib/jvm/java-${version}-openjdk-amd64"
      fi
  fi
  java -version
}

# source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify
# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
if [[ "$PLATFORM" == "Darwin" ]]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
    if [ -f "$HOME/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
        source "$HOME/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi
    if [ -f "$HOME/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
        source "$HOME/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi
fi

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

export GPG_TTY=$(tty)

# Zoxide
# shellcheck shell=bash

# =============================================================================
#
# Utility functions for zoxide.
#

# pwd based on the value of _ZO_RESOLVE_SYMLINKS.
function __zoxide_pwd() {
    \builtin pwd -L
}

# cd + custom logic based on the value of _ZO_ECHO.
function __zoxide_cd() {
    # shellcheck disable=SC2164
    \builtin cd -- "$@"
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
function __zoxide_hook() {
    # shellcheck disable=SC2312
    \command zoxide add -- "$(__zoxide_pwd)"
}

# Initialize hook.
# shellcheck disable=SC2154
if [[ ${precmd_functions[(Ie)__zoxide_hook]:-} -eq 0 ]] && [[ ${chpwd_functions[(Ie)__zoxide_hook]:-} -eq 0 ]]; then
    chpwd_functions+=(__zoxide_hook)
fi

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
function __zoxide_z() {
    # shellcheck disable=SC2199
    if [[ "$#" -eq 0 ]]; then
        __zoxide_cd ~
    elif [[ "$#" -eq 1 ]] && { [[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]$ ]]; }; then
        __zoxide_cd "$1"
    elif [[ "$#" -eq 2 ]] && [[ "$1" = "--" ]]; then
        __zoxide_cd "$2"
    else
        \builtin local result
        # shellcheck disable=SC2312
        result="$(\command zoxide query --exclude "$(__zoxide_pwd)" -- "$@")" && __zoxide_cd "${result}"
    fi
}

# Jump to a directory using interactive search.
function __zoxide_zi() {
    \builtin local result
    result="$(\command zoxide query --interactive -- "$@")" && __zoxide_cd "${result}"
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

function z() {
    __zoxide_z "$@"
}

function zi() {
    __zoxide_zi "$@"
}

# Completions.
if [[ -o zle ]]; then
    __zoxide_result=''

    function __zoxide_z_complete() {
        # Only show completions when the cursor is at the end of the line.
        # shellcheck disable=SC2154
        [[ "${#words[@]}" -eq "${CURRENT}" ]] || return 0

        if [[ "${#words[@]}" -eq 2 ]]; then
            # Show completions for local directories.
            _cd -/

        elif [[ "${words[-1]}" == '' ]]; then
            # Show completions for Space-Tab.
            # shellcheck disable=SC2086
            __zoxide_result="$(\command zoxide query --exclude "$(__zoxide_pwd || \builtin true)" --interactive -- ${words[2,-1]})" || __zoxide_result=''

            # Set a result to ensure completion doesn't re-run
            compadd -Q ""

            # Bind '\e[0n' to helper function.
            \builtin bindkey '\e[0n' '__zoxide_z_complete_helper'
            # Sends query device status code, which results in a '\e[0n' being sent to console input.
            \builtin printf '\e[5n'

            # Report that the completion was successful, so that we don't fall back
            # to another completion function.
            return 0
        fi
    }

    function __zoxide_z_complete_helper() {
        if [[ -n "${__zoxide_result}" ]]; then
            # shellcheck disable=SC2034,SC2296
            BUFFER="z ${(q-)__zoxide_result}"
            __zoxide_result=''
            \builtin zle reset-prompt
            \builtin zle accept-line
        else
            \builtin zle reset-prompt
        fi
    }
    \builtin zle -N __zoxide_z_complete_helper

    [[ "${+functions[compdef]}" -ne 0 ]] && \compdef __zoxide_z_complete z
fi

if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

eval "$(starship init zsh)"

# =============================================================================
#
# To initialize zoxide, add this to your configuration (usually ~/.zshrc):
#
# eval "$(zoxide init zsh)"

alias goosec="goose session --with-builtin computercontroller"
export PATH="$HOME/.local/bin:$PATH"

export PATH="$PATH":"$HOME/.pub-cache/bin"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f $HOME/.dart-cli-completion/zsh-config.zsh ]] && . $HOME/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

if [[ "$PLATFORM" == "Darwin" ]]; then
    export JAVA_HOME=$(/usr/libexec/java_home -v "17")
else
    if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
        export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
    fi
fi
export PATH="$JAVA_HOME/bin:$PATH"

if [[ "$PLATFORM" == "Darwin" ]]; then
    export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
else
    export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
fi
#export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"


# Call a command with "x command" to get timing and sound
x() {
  if [[ "$PLATFORM" == "Darwin" ]]; then
    local sound="/System/Library/Sounds/Glass.aiff"
  else
    local sound=""
  fi

  if (( $# == 0 )); then
    print -P "%F{red}Usage:%f x <command ...>"
    return 1
  fi

  # Record start time
  local start=$EPOCHSECONDS
  local start_human
  start_human=$(date '+%Y-%m-%d %H:%M:%S')

  # Colored "starting" line
  print -P "%F{cyan}[START %F{yellow}$start_human%F{cyan}]%f %F{white}$*%f"
  echo

  # Rebuild the command string so aliases (like `l`) work
  local cmd_str
  cmd_str=$(printf '%q ' "$@")
  cmd_str=${cmd_str% }  # trim trailing space

  # Run in a new interactive zsh so aliases expand
  zsh -ic "$cmd_str"
  local exit_code=$?

  # Record end time
  local end=$EPOCHSECONDS
  local end_human
  end_human=$(date '+%Y-%m-%d %H:%M:%S')
  local elapsed=$(( end - start ))

  # Color for exit status
  local status_color="red"
  (( exit_code == 0 )) && status_color="green"

  # Play completion sound (foreground, but silent)
  if [[ "$PLATFORM" == "Darwin" ]] && [ -n "$sound" ]; then
    afplay "$sound" >/dev/null 2>&1
  fi

  echo
  print -P "%F{cyan}[END   %F{yellow}$end_human%F{cyan}]%f"
  print -P "  %F{magenta}Elapsed:%f ${elapsed}s"
  print -P "  %F{magenta}Exit:%f %F{$status_color}$exit_code%f"
  echo

  return $exit_code
}


function zj () {
    local name="$1"
    command zellij attach "${name}" 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "🚀 Creating new session '${name}'..."
        if [ -f "$HOME/.config/zellij/layouts/${name}.kdl" ]; then
            command zellij -s "${name}" -n "${name}"
        else
            command zellij -s "${name}"
        fi
    fi
}

eval "$(mise activate zsh)"


# Sleep aliases - keep Mac awake or restore idle sleep
if [[ "$PLATFORM" == "Darwin" ]]; then
    alias awake='sudo pmset -a disablesleep 1 sleep 0 && echo "☕ Sleep fully disabled; idle sleep set to never"'
    alias rest='sudo pmset -a disablesleep 0 sleep 15 && echo "😴 Sleep re-enabled; idle sleep set to 15 min"'


    # OpenClaw Completion
    source "/Users/alancolver/.openclaw/completions/openclaw.zsh"

    # OpenClaw TUI aliases
    alias claw='openclaw tui'
    alias claw-realestate='openclaw tui --session agent:realestate:main'
    alias claw-bounty='openclaw tui --session agent:bounty-ninja:main'
    alias claw-redshift='openclaw tui --session agent:redshift:main'
    alias claw-bento='openclaw tui --session agent:bento:main'
else
    # Linux alternatives for sleep (may require sudo)
    alias awake='echo "Use: sudo systemctl suspend" to sleep; sudo -v; echo "☕ Sleep disabled"'
    alias rest='echo "😴 Sleep re-enabled"'
fi

if [[ "$PLATFORM" == "Darwin" ]] && command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# Herdr shortcuts — tmux-like muscle memory for the AI-agent workspace manager.
# Sessions are long-lived Herdr servers; workspaces are project/group rows; tabs are tmux-window-like.
alias h='herdr'                         # launch/attach default Herdr session
alias hd='herdr'                        # mnemonic: Herdr default
alias hst='herdr status'                # local client/server status
alias hu='herdr update --handoff'       # update with live handoff when possible
alias hrl='herdr server reload-config'  # reload ~/.config/herdr/config.toml
alias hstop='herdr server stop'         # stop the running default server

# Herdr session/workspace aliases. Deliberately avoid tl/ts/ta/tk so tmux/tmuxinator aliases stay free.
alias hl='herdr session list'
# `hs name` = Herdr space: create a new workspace in the current/main session.
hs() {
  emulate -L zsh

  command -v herdr >/dev/null 2>&1 || { echo "hs: herdr is not in PATH" >&2; return 127; }

  local name="${*:-${PWD:t}}"
  [[ -n "$name" ]] || name="workspace"

  local attach_after=0 session="${HERDR_SESSION:-main}"
  if [[ -z "${HERDR_SOCKET_PATH:-}" ]]; then
    local HERDR_SESSION="$session"
    export HERDR_SESSION
    attach_after=1

    if ! herdr workspace list >/dev/null 2>&1; then
      echo "hs: starting Herdr session '$session'..."
      herdr --session "$session" server >/tmp/hs-herdr-server.log 2>&1 &!

      local attempt
      for attempt in {1..50}; do
        herdr workspace list >/dev/null 2>&1 && break
        sleep 0.1
      done

      if ! herdr workspace list >/dev/null 2>&1; then
        echo "hs: failed to start Herdr session '$session'; see /tmp/hs-herdr-server.log" >&2
        return 1
      fi
    fi
  fi

  local created workspace_id
  created=$(herdr workspace create --cwd "$PWD" --label "$name" --focus) || return
  if command -v jq >/dev/null 2>&1; then
    workspace_id=$(jq -r '.result.workspace.workspace_id // empty' <<< "$created" 2>/dev/null)
  fi
  echo "Created Herdr workspace '$name'${workspace_id:+ ($workspace_id)}"

  if (( attach_after )); then
    herdr session attach "$session"
  fi
}
ha() { herdr session attach "${1:-main}"; }
# `hk name` = Herdr kill: stop and delete the named session snapshot.
hk() {
  emulate -L zsh

  local herdr_bin
  herdr_bin=$(command -v herdr) || { echo "hk: herdr is not in PATH" >&2; return 127; }

  local session="${1:-${HERDR_SESSION:-main}}"
  [[ -n "$session" ]] || { echo "hk: session name required" >&2; return 2; }
  if [[ "$session" == "default" ]]; then
    echo "hk: Herdr cannot delete the default session; use a named session." >&2
    return 2
  fi

  local safe_session="${session//[^A-Za-z0-9_.-]/-}"
  local log="/tmp/hk-herdr-${safe_session}.log"

  # If we are killing the session that owns this pane, run the stop/delete from
  # a detached process so the cleanup survives this pane being terminated.
  if [[ -n "${HERDR_SOCKET_PATH:-}" && "${session}" == "${HERDR_SESSION:-main}" ]]; then
    nohup /bin/sh -c '
      session="$1"
      herdr_bin="$2"
      "$herdr_bin" session stop "$session" --json >/dev/null 2>&1 || true
      for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        "$herdr_bin" session delete "$session" --json >/dev/null 2>&1 && exit 0
        sleep 0.25
      done
      exit 1
    ' hk-herdr-kill "$session" "$herdr_bin" >"$log" 2>&1 &!
    echo "Killing Herdr session '$session' (cleanup log: $log)"
    return 0
  fi

  herdr session stop "$session" --json >/dev/null 2>&1 || true
  local attempt
  for attempt in {1..20}; do
    if herdr session delete "$session" --json >/dev/null 2>"$log"; then
      echo "Killed Herdr session '$session'"
      return 0
    fi
    sleep 0.25
  done
  echo "hk: failed to delete Herdr session '$session'; see $log" >&2
  return 1
}
hdlt() { hk "$1"; }

# Remote attach: use SSH config names, e.g. `hr workbox`.
hr() { herdr --remote "$@"; }
hrs() { herdr --remote "$1" --remote-keybindings server; }

# Workspace / tab / pane helpers.
alias hwl='herdr workspace list'
hw() { herdr workspace create --cwd "${1:-$PWD}" --label "${2:-${PWD:t}}" --focus; }
alias htl='herdr tab list'
ht() { herdr tab create --cwd "${1:-$PWD}" --label "${2:-${PWD:t}}" --focus; }
alias hpl='herdr pane list'
alias hpc='herdr pane current'

# Git worktrees.
alias hwtl='herdr worktree list --cwd .'
hwt() { herdr worktree create --cwd . --branch "$1" --focus; }
hwto() { herdr worktree open --cwd . --branch "$1" --focus; }

# Agent helpers. Start agents inside Herdr panes so integrations/session restore work.
alias hal='herdr agent list'
hpi() { herdr agent start pi --cwd "${1:-$PWD}" -- pi; }
hoc() { herdr agent start opencode --cwd "${1:-$PWD}" -- opencode; }
haf() { herdr agent focus "$1"; }
har() { herdr agent read "$1" --lines "${2:-80}"; }

# hux = Herdr tmuxinator-ish layouts. `hux dev` mirrors ~/.tmuxinator/dev.yml.
__hux_dev() {
  emulate -L zsh

  command -v herdr >/dev/null 2>&1 || { echo "hux dev: herdr is not in PATH" >&2; return 127; }
  command -v jq >/dev/null 2>&1 || { echo "hux dev: jq is required to parse herdr CLI JSON" >&2; return 127; }
  command -v pi >/dev/null 2>&1 || { echo "hux dev: pi is not in PATH" >&2; return 127; }
  command -v nvim >/dev/null 2>&1 || { echo "hux dev: nvim is not in PATH" >&2; return 127; }

  local no_attach=0
  if [[ "${1:-}" == "--no-attach" ]]; then
    no_attach=1
    shift
  fi

  # Herdr CLI commands need a target socket/session. Inside Herdr, HERDR_SOCKET_PATH
  # already points at the active session. Outside Herdr, default to your main session
  # so `hux dev` works like `mux dev` from a normal terminal.
  local hux_attach_after=0 hux_session="${HERDR_SESSION:-main}"
  if [[ -z "${HERDR_SOCKET_PATH:-}" ]]; then
    local HERDR_SESSION="$hux_session"
    export HERDR_SESSION
    hux_attach_after=1

    if ! herdr workspace list >/dev/null 2>&1; then
      echo "hux dev: starting Herdr session '$hux_session'..."
      herdr --session "$hux_session" server >/tmp/hux-herdr-server.log 2>&1 &!

      local attempt
      for attempt in {1..50}; do
        herdr workspace list >/dev/null 2>&1 && break
        sleep 0.1
      done

      if ! herdr workspace list >/dev/null 2>&1; then
        echo "hux dev: failed to start Herdr session '$hux_session'; see /tmp/hux-herdr-server.log" >&2
        return 1
      fi
    fi
  fi

  local root="${1:-$PWD}"
  [[ -d "$root" ]] || { echo "hux dev: not a directory: $root" >&2; return 1; }
  root="${root:A}"

  local name="${root:t}"
  [[ -n "$name" ]] || name="root"
  name="${name//[^A-Za-z0-9_.-]/-}"

  local created workspace_id dev_tab_id shell_pane_id
  created=$(herdr workspace create --cwd "$root" --label "$name" --focus) || return
  workspace_id=$(jq -r '.result.workspace.workspace_id' <<< "$created") || return
  dev_tab_id=$(jq -r '.result.tab.tab_id' <<< "$created") || return
  shell_pane_id=$(jq -r '.result.root_pane.pane_id' <<< "$created") || return
  herdr tab rename "$dev_tab_id" "$name" >/dev/null || return

  # First tab: left shell plus two Pi panes stacked on the right.
  local split top_pi_pane bottom_pi_pane
  split=$(herdr pane split "$shell_pane_id" --direction right --ratio 0.40 --cwd "$root" --no-focus) || return
  top_pi_pane=$(jq -r '.result.pane.pane_id' <<< "$split") || return
  split=$(herdr pane split "$top_pi_pane" --direction down --ratio 0.52 --cwd "$root" --no-focus) || return
  bottom_pi_pane=$(jq -r '.result.pane.pane_id' <<< "$split") || return
  herdr pane run "$top_pi_pane" "pi" || return
  herdr pane run "$bottom_pi_pane" "pi" || return

  # Editor tab.
  local editor_created editor_pane_id
  editor_created=$(herdr tab create --workspace "$workspace_id" --cwd "$root" --label editor --no-focus) || return
  editor_pane_id=$(jq -r '.result.root_pane.pane_id' <<< "$editor_created") || return
  herdr pane run "$editor_pane_id" "nvim ." || return

  # Other tab: 2x2 shell grid, matching tmuxinator's four clear panes.
  local other_created other_root_pane right_pane left_bottom_pane right_bottom_pane
  other_created=$(herdr tab create --workspace "$workspace_id" --cwd "$root" --label other --no-focus) || return
  other_root_pane=$(jq -r '.result.root_pane.pane_id' <<< "$other_created") || return
  split=$(herdr pane split "$other_root_pane" --direction right --ratio 0.50 --cwd "$root" --no-focus) || return
  right_pane=$(jq -r '.result.pane.pane_id' <<< "$split") || return
  split=$(herdr pane split "$other_root_pane" --direction down --ratio 0.50 --cwd "$root" --no-focus) || return
  left_bottom_pane=$(jq -r '.result.pane.pane_id' <<< "$split") || return
  split=$(herdr pane split "$right_pane" --direction down --ratio 0.50 --cwd "$root" --no-focus) || return
  right_bottom_pane=$(jq -r '.result.pane.pane_id' <<< "$split") || return
  herdr pane run "$other_root_pane" clear || return
  herdr pane run "$right_pane" clear || return
  herdr pane run "$left_bottom_pane" clear || return
  herdr pane run "$right_bottom_pane" clear || return

  herdr tab focus "$dev_tab_id" >/dev/null || return
  herdr workspace focus "$workspace_id" >/dev/null || return
  echo "Created Herdr dev workspace '$name' ($workspace_id) at $root"

  if (( hux_attach_after && ! no_attach )); then
    echo "hux dev: attaching to Herdr session '$hux_session'..."
    herdr session attach "$hux_session"
  fi
}

hux() {
  emulate -L zsh

  case "${1:-}" in
    dev)
      shift
      __hux_dev "$@"
      ;;
    ""|-h|--help|help)
      echo "Usage: hux dev [--no-attach] [directory]"
      echo "Creates a Herdr workspace like ~/.tmuxinator/dev.yml: dev tab, editor tab, other tab."
      echo "Outside Herdr, targets/starts HERDR_SESSION or main and attaches unless --no-attach is set."
      ;;
    *)
      echo "hux: unknown command: $1" >&2
      echo "Usage: hux dev [--no-attach] [directory]" >&2
      return 2
      ;;
  esac
}


