#!/usr/bin/env bash
# ==============================================================================
# /merged - Generic Post-Merge PR & Worktree Cleanup Utility
#
# Automates post-merge housekeeping for any git repository:
# 1. Verifies the pull request was merged successfully on GitHub
# 2. Deletes the remote feature branch from GitHub if it still exists
# 3. Switches out of any active worktree and removes associated worktrees
# 4. Deletes the local feature branch
# 5. Checks out the base branch (default: main) and pulls latest changes
# ==============================================================================

set -eo pipefail

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

info() {
    echo -e "${CYAN}${BOLD}[INFO]${RESET} $*"
}

success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $*"
}

warn() {
    echo -e "${YELLOW}${BOLD}[WARN]${RESET} $*"
}

error() {
    echo -e "${RED}${BOLD}[ERROR]${RESET} $*" >&2
}

fatal() {
    error "$*"
    exit 1
}

show_help() {
    cat << EOF
Usage: merged.sh [OPTIONS] [PR_OR_BRANCH]

Performs post-merge cleanup after a Pull Request lands on GitHub.

Arguments:
  PR_OR_BRANCH    Optional PR number (e.g. 44), URL, or branch name.
                  If omitted, auto-detects from the current git branch or worktree.

Options:
  -f, --force     Force cleanup even if worktree has untracked/modified files.
  -d, --dry-run   Simulate all cleanup actions without deleting anything.
  -h, --help      Display this help message.

Examples:
  ./merged.sh               # Auto-detect current branch/PR and clean up
  ./merged.sh 44            # Clean up PR #44
  ./merged.sh my-feature    # Clean up branch 'my-feature'
  ./merged.sh --dry-run     # Preview what would be cleaned up
EOF
}

# Parse flags
FORCE=false
DRY_RUN=false
TARGET_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            fatal "Unknown option: $1. Run with --help for usage."
            ;;
        *)
            if [[ -z "$TARGET_ARG" ]]; then
                TARGET_ARG="$1"
            else
                fatal "Unexpected argument: $1. Run with --help for usage."
            fi
            shift
            ;;
    esac
done

# Pre-flight check: ensure git is available
if ! command -v git >/dev/null 2>&1; then
    fatal "git is required but not installed."
fi

# Pre-flight check: verify we are inside a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fatal "Current directory is not inside a git repository."
fi

# Pre-flight check: ensure gh CLI is available and authenticated
if ! command -v gh >/dev/null 2>&1; then
    fatal "GitHub CLI ('gh') is required but not installed. Install with: brew install gh"
fi

if ! gh auth status >/dev/null 2>&1; then
    fatal "GitHub CLI ('gh') is not authenticated. Run: gh auth login"
fi

# 1. Determine Repository Roots & Context
ORIGINAL_PWD="$(pwd -P)"
GIT_COMMON_DIR="$(git rev-parse --git-common-dir 2>/dev/null || git rev-parse --git-dir)"
# Resolve main worktree root (first entry in worktree list is always the primary tree)
MAIN_ROOT="$(git worktree list --porcelain | head -n 1 | sed 's/^worktree //')"

if [[ -z "$MAIN_ROOT" || ! -d "$MAIN_ROOT" ]]; then
    MAIN_ROOT="$(git -C "$GIT_COMMON_DIR/.." rev-parse --show-toplevel 2>/dev/null || pwd -P)"
fi

CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || true)"

info "Repository root: ${MAIN_ROOT}"
info "Current location: ${ORIGINAL_PWD}"

# 2. Resolve PR Details via GitHub CLI
info "Resolving pull request details..."

PR_JSON=""
if [[ -n "$TARGET_ARG" ]]; then
    # Target argument explicitly provided (PR number, branch, or URL)
    PR_JSON="$(gh pr view "$TARGET_ARG" --json number,title,state,mergedAt,headRefName,baseRefName,url 2>/dev/null || true)"
elif [[ -n "$CURRENT_BRANCH" && "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
    # Auto-detect from current feature branch
    PR_JSON="$(gh pr view "$CURRENT_BRANCH" --json number,title,state,mergedAt,headRefName,baseRefName,url 2>/dev/null || true)"
else
    # Current branch is main/master or detached; check if an associated PR exists for recent work
    PR_JSON="$(gh pr list --state merged --author "@me" --limit 1 --json number,title,state,mergedAt,headRefName,baseRefName,url 2>/dev/null | jq -r '.[0] // empty' 2>/dev/null || true)"
fi

if [[ -z "$PR_JSON" || "$PR_JSON" == "null" ]]; then
    if [[ -n "$TARGET_ARG" ]]; then
        fatal "Could not find a pull request matching '${TARGET_ARG}'."
    else
        fatal "Could not auto-detect an active or merged pull request for branch '${CURRENT_BRANCH}'. Please provide a PR number: merged.sh <PR_NUMBER>"
    fi
fi

# Extract JSON fields
PR_NUMBER="$(echo "$PR_JSON" | jq -r '.number')"
PR_TITLE="$(echo "$PR_JSON" | jq -r '.title')"
PR_STATE="$(echo "$PR_JSON" | jq -r '.state')"
PR_URL="$(echo "$PR_JSON" | jq -r '.url')"
HEAD_BRANCH="$(echo "$PR_JSON" | jq -r '.headRefName')"
BASE_BRANCH="$(echo "$PR_JSON" | jq -r '.baseRefName')"

if [[ -z "$BASE_BRANCH" || "$BASE_BRANCH" == "null" ]]; then
    BASE_BRANCH="main"
fi

info "Found PR #${PR_NUMBER}: ${BOLD}${PR_TITLE}${RESET}"
info "URL: ${PR_URL}"
info "Head Branch: ${HEAD_BRANCH} -> Base Branch: ${BASE_BRANCH}"
info "State: ${BOLD}${PR_STATE}${RESET}"

# Safety: protect against accidental deletion of root/base branches
if [[ "$HEAD_BRANCH" == "main" || "$HEAD_BRANCH" == "master" || "$HEAD_BRANCH" == "develop" || "$HEAD_BRANCH" == "release" ]]; then
    fatal "Refusing to clean up protected branch: '${HEAD_BRANCH}'."
fi

# 3. Ensure PR Merged Successfully
if [[ "$PR_STATE" != "MERGED" ]]; then
    if [[ "$PR_STATE" == "OPEN" ]]; then
        error "Pull Request #${PR_NUMBER} is still OPEN and has not been merged."
        error "Merge the PR first with: gh pr merge ${PR_NUMBER}"
        exit 1
    elif [[ "$PR_STATE" == "CLOSED" ]]; then
        error "Pull Request #${PR_NUMBER} was CLOSED without merging."
        error "If you want to discard this branch and worktree, delete it manually."
        exit 1
    else
        fatal "Pull Request #${PR_NUMBER} is in unexpected state: '${PR_STATE}'."
    fi
fi

success "Verified: PR #${PR_NUMBER} has been merged into '${BASE_BRANCH}'."

# 4. Delete the Feature Branch from GitHub if it Remains
info "Checking remote branch 'origin/${HEAD_BRANCH}'..."

REMOTE_EXISTS=false
if git ls-remote --heads origin "$HEAD_BRANCH" 2>/dev/null | grep -q "refs/heads/$HEAD_BRANCH"; then
    REMOTE_EXISTS=true
fi

if [[ "$REMOTE_EXISTS" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would delete remote branch 'origin/${HEAD_BRANCH}'"
    else
        info "Deleting remote branch 'origin/${HEAD_BRANCH}'..."
        if git push origin --delete "$HEAD_BRANCH"; then
            success "Deleted remote branch 'origin/${HEAD_BRANCH}'."
        else
            warn "Failed to delete remote branch via git push. Trying GitHub API..."
            gh api -X DELETE "repos/:owner/:repo/git/refs/heads/${HEAD_BRANCH}" || warn "Remote branch could not be removed."
        fi
    fi
else
    success "Remote branch 'origin/${HEAD_BRANCH}' is already deleted."
fi

# 5. Clean up Associated Local Worktrees
info "Scanning for local worktrees associated with '${HEAD_BRANCH}'..."

# Parse git worktree list to find any worktree checking out HEAD_BRANCH
# Format of git worktree list --porcelain:
# worktree /path/to/worktree
# HEAD <sha>
# branch refs/heads/<branch>
#
ASSOCIATED_WORKTREES=()
CUR_WT=""
CUR_BRANCH=""

while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.*)$ ]]; then
        CUR_WT="${BASH_REMATCH[1]}"
        CUR_BRANCH=""
    elif [[ "$line" =~ ^branch\ refs/heads/(.*)$ ]]; then
        CUR_BRANCH="${BASH_REMATCH[1]}"
        if [[ "$CUR_BRANCH" == "$HEAD_BRANCH" && -n "$CUR_WT" ]]; then
            # Do not count main root if it happens to be on that branch
            if [[ "$CUR_WT" != "$MAIN_ROOT" ]]; then
                ASSOCIATED_WORKTREES+=("$CUR_WT")
            fi
        fi
    fi
done < <(git worktree list --porcelain)

# Also check for worktrees located under .worktree/ or .worktrees/ whose path matches head branch
for wt_candidate in "$MAIN_ROOT/.worktree"/* "$MAIN_ROOT/.worktrees"/*; do
    if [[ -d "$wt_candidate" ]]; then
        WT_DIR_NAME="$(basename "$wt_candidate")"
        if [[ "$HEAD_BRANCH" == *"$WT_DIR_NAME"* || "$WT_DIR_NAME" == *"$(basename "$HEAD_BRANCH")"* ]]; then
            # Check if not already in list
            ALREADY_IN=false
            for existing in "${ASSOCIATED_WORKTREES[@]}"; do
                if [[ "$existing" == "$wt_candidate" ]]; then
                    ALREADY_IN=true
                    break
                fi
            done
            if [[ "$ALREADY_IN" == false ]]; then
                ASSOCIATED_WORKTREES+=("$wt_candidate")
            fi
        fi
    fi
done

# If current directory is inside any worktree to be deleted, change to MAIN_ROOT first
if [[ ${#ASSOCIATED_WORKTREES[@]} -gt 0 ]]; then
    for wt_path in "${ASSOCIATED_WORKTREES[@]}"; do
        if [[ "$ORIGINAL_PWD" == "$wt_path"* ]]; then
            info "Current directory is inside worktree being removed (${wt_path})."
            info "Navigating to main repository root: ${MAIN_ROOT}"
            cd "$MAIN_ROOT"
            break
        fi
    done
fi

# Process worktree removals
if [[ ${#ASSOCIATED_WORKTREES[@]} -gt 0 ]]; then
    for wt_path in "${ASSOCIATED_WORKTREES[@]}"; do
        info "Found associated worktree at: ${wt_path}"
        
        # Check for uncommitted changes
        if [[ -d "$wt_path" ]]; then
            DIRTY_STATUS="$(git -C "$wt_path" status --porcelain 2>/dev/null || true)"
            if [[ -n "$DIRTY_STATUS" && "$FORCE" != true && "$DRY_RUN" != true ]]; then
                warn "Worktree '${wt_path}' contains uncommitted or untracked changes:"
                echo "$DIRTY_STATUS"
                fatal "Refusing to delete dirty worktree without --force."
            fi
        fi

        if [[ "$DRY_RUN" == true ]]; then
            info "[DRY-RUN] Would remove worktree '${wt_path}'"
        else
            info "Removing worktree: ${wt_path}..."
            git worktree remove ${FORCE:+"--force"} "$wt_path" 2>/dev/null || rm -rf "$wt_path"
            success "Removed worktree '${wt_path}'."
        fi
    done
else
    info "No separate local worktrees found for '${HEAD_BRANCH}'."
fi

# Prune stale worktree metadata
if [[ "$DRY_RUN" != true ]]; then
    git worktree prune
fi

# 6. Delete Local Branch if it Remains
# Make sure we run from MAIN_ROOT
cd "$MAIN_ROOT"

if git show-ref --verify --quiet "refs/heads/$HEAD_BRANCH"; then
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would delete local branch '${HEAD_BRANCH}'"
    else
        # If currently on the branch in the main root, we switch first
        MAIN_CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || true)"
        if [[ "$MAIN_CURRENT_BRANCH" == "$HEAD_BRANCH" ]]; then
            info "Main tree is currently on '${HEAD_BRANCH}'. Switching to '${BASE_BRANCH}' first..."
            git checkout "$BASE_BRANCH"
        fi

        info "Deleting local branch '${HEAD_BRANCH}'..."
        if git branch -d "$HEAD_BRANCH" 2>/dev/null; then
            success "Deleted local branch '${HEAD_BRANCH}'."
        else
            info "Branch not fully merged locally (squash/rebase on remote). Force deleting (-D)..."
            git branch -D "$HEAD_BRANCH"
            success "Deleted local branch '${HEAD_BRANCH}' (-D)."
        fi
    fi
else
    info "Local branch '${HEAD_BRANCH}' already removed."
fi

# 7. Check out Base Branch and Pull Latest Changes
cd "$MAIN_ROOT"

if [[ "$DRY_RUN" == true ]]; then
    info "[DRY-RUN] Would check out '${BASE_BRANCH}' and run 'git pull origin ${BASE_BRANCH}'"
else
    CURRENT_MAIN_BRANCH="$(git branch --show-current 2>/dev/null || true)"
    if [[ "$CURRENT_MAIN_BRANCH" != "$BASE_BRANCH" ]]; then
        info "Checking out base branch: '${BASE_BRANCH}'..."
        git checkout "$BASE_BRANCH"
    fi

    info "Pulling latest changes from 'origin/${BASE_BRANCH}'..."
    git pull --ff-only origin "$BASE_BRANCH" 2>/dev/null || git pull origin "$BASE_BRANCH"
    success "Successfully updated '${BASE_BRANCH}' to latest commit: $(git rev-parse --short HEAD)"
fi

echo ""
success "=========================================================================="
success "Post-merge cleanup complete for PR #${PR_NUMBER} (${PR_URL})!"
success "• Remote branch 'origin/${HEAD_BRANCH}' deleted"
success "• Local worktrees and branch '${HEAD_BRANCH}' cleaned up"
success "• Checked out '${BASE_BRANCH}' and synced with latest origin"
success "=========================================================================="
