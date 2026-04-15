---
name: git
description: Expert Git guidance for commits, branches, merges, rebases, remotes, conflict resolution, and recovery. Use when performing git operations, writing commit messages, managing branches, syncing with remote, resolving merge conflicts, or undoing changes.
---

# Git

Expert guidance for version control with Git. Use this skill for any git operation, commit workflow, branching, merging, rebasing, remote sync, or recovery.

## Before Any Destructive Action

1. **Check state**: `git status` and `git log -3 --oneline`
2. **Uncommitted work**: Stash (`git stash`) or commit before switching branches, rebasing, or resetting
3. **Shared branches**: Avoid `git push --force` on shared branches; prefer `--force-with-lease` if you must overwrite

## Commit Workflow

### Making a good commit

1. Stage intentionally: `git add <paths>` or `git add -p` for hunks
2. Commit with a clear message (see format below)
3. Prefer small, logical commits over one large commit

### Commit message format

Use conventional style when the project expects it; otherwise keep subject line short and imperative.

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`. **Subject**: imperative, ~50 chars, no period.

**Examples:**
- `feat(auth): add JWT login`
- `fix(api): handle null response in parser`
- `chore: bump deps`

### Amend last commit (local only)

- Change message: `git commit --amend -m "new message"`
- Add more changes: stage files, then `git commit --amend --no-edit`
- **Do not** amend after push if others use the branch; use a new commit instead

## Branch Workflow

### Creating and switching

```bash
git switch -c feature/name    # create and switch
git switch main              # switch existing
git checkout -b feature/name # same as switch -c (older syntax)
```

### Keeping a branch updated

- **Merge** (preserves history, safe for shared branches):  
  `git switch main && git pull && git switch feature && git merge main`
- **Rebase** (linear history, use only on branches you haven’t shared):  
  `git switch feature && git fetch origin && git rebase origin/main`

### When to merge vs rebase

| Use merge when           | Use rebase when                    |
|--------------------------|------------------------------------|
| Integrating a shared branch | Updating your local/feature branch |
| Preserving full history  | You want a linear history          |
| Pull requests / main flow| Branch is only on your machine     |

**Do not rebase** commits that have been pushed and others may have pulled.

## Merge

### Basic merge

```bash
git switch main
git pull
git merge feature/branch
# resolve conflicts if any, then:
git add .
git commit  # or omit if no conflicts
```

### Abort a merge

`git merge --abort` (returns to pre-merge state)

## Rebase

### Update branch onto latest main

```bash
git fetch origin
git rebase origin/main
```

### Interactive rebase (reword, squash, drop commits)

```bash
git rebase -i HEAD~n   # n = number of commits
```

In the editor: `pick` = keep, `reword` = change message, `squash`/`fixup` = fold into previous, `drop` = remove. Save and close; then follow prompts.

### Abort or continue

- `git rebase --abort` — cancel and restore pre-rebase state
- After resolving conflicts: `git add .` then `git rebase --continue`

## Undo and Recovery

### Discard uncommitted changes

- File: `git restore <file>` or `git checkout -- <file>`
- All tracked: `git restore .` (unstaged) and/or `git clean -fd` (untracked; use `-n` first to preview)

### Move branch back (keep working tree)

- `git reset --soft HEAD~1` — undo last commit, keep changes staged
- `git reset --mixed HEAD~1` — undo last commit, keep changes unstaged (default)
- `git reset --hard HEAD~1` — **destructive**: undo last commit and discard changes

### Restore a file from another commit

`git restore --source=<commit> -- <file>` or `git checkout <commit> -- <file>`

### Reflog (recover “lost” commits)

After a bad reset/rebase, find the previous HEAD:

```bash
git reflog
git switch -c recovery <commit-hash>
# or git reset --hard <commit-hash>
```

## Stash

- Save: `git stash` or `git stash push -m "description"`
- List: `git stash list`
- Apply (keep in stash): `git stash apply [stash@{n}]`
- Apply and remove: `git stash pop [stash@{n}]`
- Drop: `git stash drop stash@{n}`

## Remotes

### Fetch, pull, push

- `git fetch origin` — update remote refs only (safe, no local changes)
- `git pull` — fetch + merge (or rebase if configured)
- `git pull --rebase` — fetch + rebase onto remote
- `git push origin <branch>` — push branch
- `git push -u origin <branch>` — push and set upstream

### Force push (use sparingly)

- Prefer: `git push --force-with-lease origin <branch>` (fails if remote has new commits)
- Avoid: `git push --force` on shared branches

### Remote branch deleted by others

`git fetch --prune` (or `git remote prune origin`) to remove stale remote-tracking refs.

## Merge Conflicts

### Resolve steps

1. Identify: `git status` shows “both modified”
2. Open conflicted files; look for `<<<<<<<`, `=======`, `>>>>>>>`
3. Edit to keep the correct code and remove conflict markers
4. Stage: `git add <file>`
5. Finish: `git merge --continue` or `git commit` (merge), or `git rebase --continue` (rebase)

### Abort

- Merge: `git merge --abort`
- Rebase: `git rebase --abort`

### Reduce conflicts

- Sync with main often (merge or rebase)
- Small, focused commits and branches

## Safety Checklist

- [ ] Run `git status` and `git log -3` before destructive commands
- [ ] Stash or commit uncommitted work before switch/reset/rebase
- [ ] Use `--force-with-lease` instead of `--force` when overwriting remote
- [ ] Do not rebase shared/pushed history without team agreement
- [ ] Use `git reflog` to find commits after a mistaken reset/rebase

## Quick Reference

For a compact command reference, see [reference.md](reference.md).

## Related

- **Project workflow**: For this repo’s branching and PR flow, see `@development-workflow`.
