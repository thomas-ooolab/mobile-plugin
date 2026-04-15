---
title: Git Command Reference
description: Quick reference for common Git commands — commits, branches, merges, remotes, recovery
---

# Git Command Reference

Quick reference for common Git commands. See [SKILL.md](SKILL.md) for workflows and when to use each.

## State and history

| Command | Purpose |
|--------|--------|
| `git status` | Working tree and branch state |
| `git log -n --oneline` | Last n commits, one line each |
| `git log --oneline --graph` | Branch graph |
| `git diff` | Unstaged changes |
| `git diff --staged` | Staged changes |
| `git reflog` | History of HEAD (recovery) |

## Staging and committing

| Command | Purpose |
|--------|--------|
| `git add <path>` | Stage file(s) |
| `git add -p` | Stage hunks interactively |
| `git restore --staged <file>` | Unstage file |
| `git commit -m "msg"` | Commit with message |
| `git commit --amend [-m "msg"]` | Fix last commit (local only if pushed) |

## Branches

| Command | Purpose |
|--------|--------|
| `git branch` | List local branches |
| `git branch -a` | List all (local + remote) |
| `git switch -c <branch>` | Create and switch |
| `git switch <branch>` | Switch branch |
| `git branch -d <branch>` | Delete merged branch |
| `git branch -D <branch>` | Force delete branch |

## Merge and rebase

| Command | Purpose |
|--------|--------|
| `git merge <branch>` | Merge branch into current |
| `git merge --abort` | Cancel in-progress merge |
| `git rebase <upstream>` | Rebase onto upstream |
| `git rebase -i HEAD~n` | Interactive rebase |
| `git rebase --abort` | Cancel in-progress rebase |
| `git rebase --continue` | After resolving conflicts |

## Reset

| Command | Purpose |
|--------|--------|
| `git reset --soft HEAD~1` | Undo commit, keep staged |
| `git reset --mixed HEAD~1` | Undo commit, keep unstaged |
| `git reset --hard HEAD~1` | Undo commit and discard changes |
| `git restore <file>` | Discard unstaged file changes |
| `git clean -fd` | Remove untracked files (use `-n` to preview) |

## Remote

| Command | Purpose |
|--------|--------|
| `git fetch [remote]` | Update remote refs only |
| `git pull [remote] [branch]` | Fetch and merge |
| `git pull --rebase` | Fetch and rebase |
| `git push [remote] [branch]` | Push branch |
| `git push -u origin <branch>` | Push and set upstream |
| `git push --force-with-lease` | Safe force push |
| `git remote -v` | List remotes |
| `git fetch --prune` | Remove stale remote-tracking refs |

## Stash

| Command | Purpose |
|--------|--------|
| `git stash` | Stash changes |
| `git stash push -m "msg"` | Stash with message |
| `git stash list` | List stashes |
| `git stash apply [ref]` | Apply, keep in stash |
| `git stash pop [ref]` | Apply and remove |
| `git stash drop [ref]` | Remove stash entry |

## Restore from commit

| Command | Purpose |
|--------|--------|
| `git restore --source=<commit> -- <file>` | Restore file from commit |
| `git show <commit>:<file>` | Print file content at commit |

## Conflict markers

In conflicted files:

- `<<<<<<< HEAD` — your side
- `=======` — separator
- `>>>>>>> <branch>` — their side

Edit to final content and remove all three markers, then `git add` and continue merge/rebase.
