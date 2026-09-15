---
name: merged
description: Clean up after a Pull Request is merged. Verifies the PR is merged on GitHub, deletes the remote branch if remaining, removes associated local worktrees, deletes the local branch, and checks out main with latest changes.
disable-model-invocation: true
---

# Post-merge pull request and worktree cleanup

Use this skill when a pull request has been merged on GitHub (or when the user runs the `/merged` slash command) to complete post-merge housekeeping.

## Workflow overview

When this command runs, it executes the following steps in sequence:
1. **Verify merge status**: Confirms the target pull request has been merged on GitHub. If the PR is still open or was closed unmerged, it stops immediately.
2. **Delete remote branch**: Deletes the remote feature branch from GitHub if it has not already been deleted.
3. **Clean up local worktrees**: Identifies any local worktree attached to the feature branch (such as `.worktree/<name>` or `.worktrees/<name>`), switches out of the worktree directory if currently inside it, and removes the worktree.
4. **Clean up local branch**: Deletes the local feature branch.
5. **Update base branch**: Switches the primary repository tree to `main` (or the repository default base branch) and pulls the latest upstream commits.

---

## Quick execution via helper script

The skill includes a pre-packaged helper script that handles all five steps automatically:

```bash
# Auto-detect PR from current branch, worktree, or recent user activity
~/.agents/skills/merged/scripts/merged.sh

# Or specify a PR number, URL, or branch explicitly
~/.agents/skills/merged/scripts/merged.sh 44
~/.agents/skills/merged/scripts/merged.sh docs/audit-and-license

# Dry-run mode to inspect actions before executing
~/.agents/skills/merged/scripts/merged.sh --dry-run
```

---

## Step-by-step procedure

If executing manually or embedding into an agent tool turn:

### Step 1: Detect and verify the pull request

1. Resolve the pull request number and status:
   ```bash
   gh pr view [PR_NUMBER_OR_BRANCH] --json number,title,state,mergedAt,headRefName,baseRefName,url
   ```
2. Check the `state` field:
   - **`MERGED`**: Proceed to Step 2.
   - **`OPEN`**: Stop. Report to the user:
     ```
     PR #<num> (<url>) is still OPEN and has not been merged.
     Run 'gh pr merge <num>' or merge through the GitHub UI before running /merged.
     ```
   - **`CLOSED`**: Stop. Report to the user that the PR was closed without merging, and ask for explicit confirmation before deleting branches or worktrees.

### Step 2: Delete the remote branch

Check if the remote branch still exists and delete it if present:
```bash
if git ls-remote --heads origin "<head-branch>" | grep -q "<head-branch>"; then
    git push origin --delete "<head-branch>"
fi
```
If already deleted (for example, by GitHub's automatic branch deletion), proceed.

### Step 3: Remove associated local worktrees

1. Capture the main repository root before switching directories:
   ```bash
   MAIN_ROOT="$(git worktree list --porcelain | head -n 1 | sed 's/^worktree //')"
   ```
2. If the current working directory is inside a worktree being removed, navigate to `$MAIN_ROOT` first:
   ```bash
   cd "$MAIN_ROOT"
   ```
3. Locate any worktree checked out on the feature branch using `git worktree list --porcelain`:
   ```bash
   git worktree list
   ```
4. Verify the worktree has no uncommitted or untracked changes:
   ```bash
   git -C "<worktree-path>" status --porcelain
   ```
   If dirty, warn the user before removing.
5. Remove the worktree and prune metadata:
   ```bash
   git worktree remove "<worktree-path>"
   git worktree prune
   ```

### Step 4: Delete the local branch

From the main repository root:
```bash
cd "$MAIN_ROOT"
git branch -d "<head-branch>" 2>/dev/null || git branch -D "<head-branch>"
```

### Step 5: Check out main and pull latest changes

```bash
cd "$MAIN_ROOT"
git checkout main
git pull --ff-only origin main || git pull origin main
git status
```

---

## Safety rules and invariants

1. **Never delete protected branches**: Refuse deletion if the head branch is `main`, `master`, `develop`, or `release`.
2. **Never delete unmerged work without confirmation**: If the PR is open or closed unmerged, never delete worktrees or branches.
3. **Navigate out of worktrees before removal**: Running `git worktree remove` from inside the target worktree directory will fail with lock errors. Always `cd` to the main repository root first.
4. **Check for dirty state**: Check `git status --porcelain` on the worktree before deleting.
