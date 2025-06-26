# Branch Management Guide - OpenWebUI Installer

This document outlines the branch management strategy, cleanup procedures, and best practices for maintaining a clean and organized repository.

## Current Repository Status

**As of latest assessment:**
- **Total Branches**: 85
- **Active Branches**: 84 (all unmerged)
- **Merged Branches**: 0
- **Branch Types**: 82 Codex branches, 2 Dependabot branches

**Key Finding**: All branches are currently unmerged feature branches, indicating they contain work that hasn't been integrated into main.

## Branch Categories

### 🤖 Codex Branches
- **Pattern**: `codex/*` and `{user}-codex/*`
- **Purpose**: AI-generated feature branches
- **Examples**: `codex/add-trailing-newline-to-files`, `codex/format-code-with-black-and-isort`
- **Lifecycle**: Created by AI tooling, should be reviewed and merged or closed

### 🔄 Dependabot Branches  
- **Pattern**: `dependabot/*`
- **Purpose**: Automated dependency updates
- **Examples**: `dependabot/github_actions/actions/setup-python-5`
- **Lifecycle**: Auto-created, should be reviewed and merged quickly

### 🚀 Feature Branches
- **Pattern**: `feature/*`, `bugfix/*`, `hotfix/*`
- **Purpose**: Manual feature development
- **Lifecycle**: Created by developers, merged via PR, then deleted

## Best Practices

### ✅ Branch Creation
1. **Use descriptive names**: `feature/user-authentication` not `feature/fix`
2. **Follow naming conventions**: 
   - `feature/` for new features
   - `bugfix/` for bug fixes
   - `hotfix/` for urgent fixes
   - `codex/` for AI-generated branches
3. **Keep branches focused**: One feature/fix per branch
4. **Branch from main**: Always create branches from latest main

### 🔄 Branch Lifecycle
1. **Create** → **Develop** → **Review** → **Merge** → **Delete**
2. **Maximum lifetime**: 30 days for feature branches
3. **Regular updates**: Rebase/merge from main weekly
4. **Clean commits**: Squash related commits before merging

### 🧹 Cleanup Strategy

#### Immediate Actions Required
Since all 84 branches are unmerged, they need triage:

1. **Review Critical Branches** (from `.branch-analysis/critical_branches.txt`):
   - `codex/extend-installer-with-container-management-commands`
   - `codex/implement-macos-autostart-feature`
   - `codex/add-cli-methods-and-update-tests`
   - Priority: Merge these first if functionality is needed

2. **Review Formatting Branches**:
   - `codex/format-code-with-black-and-isort`
   - `codex/run-black-and-isort,-fix-flake8-issues`
   - Decision: Choose one consistent formatting approach

3. **Review Duplicate Branches**:
   - Multiple newline/formatting branches exist
   - Multiple refactoring branches exist
   - Action: Merge best version, close duplicates

#### Automated Cleanup Rules
Configure GitHub to automatically:
- Delete merged branches
- Mark stale branches (>30 days)
- Auto-merge dependabot PRs (after CI passes)

## Cleanup Procedures

### 1. Manual Branch Review Process

Use the GitHub Actions **Branch Cleanup** workflow for a comprehensive
analysis. It can be triggered manually from the **Actions** tab or run
on its weekly schedule.

```bash
# List merged branches locally for a quick review
git branch -r --merged main | grep -v 'main\|master\|HEAD'
```

### 2. Branch Triage Workflow

For each active branch:

```bash
# Check branch content
git log --oneline main..origin/BRANCH_NAME

# Check if changes are needed
git diff main...origin/BRANCH_NAME

# Decision matrix:
# - Useful + No conflicts → Create PR and merge
# - Useful + Conflicts → Create PR and resolve conflicts  
# - Obsolete/Duplicate → Delete branch
# - Uncertain → Leave for team review
```

### 3. Safe Branch Deletion

Only delete branches that are:
- ✅ Fully merged into main
- ✅ Contain obsolete/duplicate work
- ✅ Failed experiments or POCs
- ✅ Superseded by newer implementations

Never delete branches that:
- ❌ Contain unique unreleased features
- ❌ Are referenced in open issues/PRs
- ❌ Represent ongoing work

### 4. Automated Cleanup

Branch cleanup is handled by the workflow
`.github/workflows/branch-cleanup.yml`. It runs weekly and can also be
triggered manually.

If you need to remove a merged branch without using a helper script, run:

```bash
git push origin --delete BRANCH_NAME
```

```bash
# Review history before deleting a branch
git log --graph --oneline main..origin/BRANCH_NAME
```

## GitHub Configuration

### Repository Settings
1. **Settings → General → Pull Requests**
   - ✅ Automatically delete head branches
   - ✅ Allow squash merging
   - ✅ Allow rebase merging

2. **Settings → Branches → Branch Protection Rules**
   - Protect `main` branch
   - Require PR reviews
   - Require status checks
   - Require linear history

### Automated Workflows
- **Weekly cleanup**: `.github/workflows/branch-cleanup.yml`
- **Stale branch detection**: Alerts for branches >30 days old
- **Auto-merge**: Dependabot PRs after CI passes

## Monitoring and Alerts

### Dashboard Metrics
Track these metrics weekly:
- Total branch count
- Branches >30 days old
- Unmerged feature branches
- Failed automated merges

### Alert Triggers
- Branch count >100
- Branches >60 days old
- Multiple branches with same purpose
- Failed automated cleanups

## Emergency Procedures

### Repository Cleanup Crisis
If branch count becomes unmanageable (>200):

1. **Immediate triage**:
   ```bash
   # Identify truly merged branches
   git branch -r --merged main | grep -v main > merged_branches.txt
   
   # Identify stale branches (>90 days)
   git for-each-ref --format='%(refname:short) %(committerdate)' refs/remotes/origin | \
   awk '$2 < "'$(date -d '90 days ago' -I)'"' > stale_branches.txt
   ```

2. **Batch deletion** (with extreme caution):
   ```bash
   # Delete confirmed merged branches only
   while read branch; do
     git push origin --delete "$branch"
   done < confirmed_safe_to_delete.txt
   ```

3. **Team notification**: Inform all developers of the cleanup

### Branch Recovery
If a branch is accidentally deleted:

```bash
# Find the branch in reflog
git reflog --all | grep BRANCH_NAME

# Recreate branch from reflog
git checkout -b BRANCH_NAME COMMIT_HASH

# Push recovered branch
git push origin BRANCH_NAME
```

## Current Action Plan

### Phase 1: Immediate (This Week)
1. **Triage critical branches**: Review and merge/close high-priority branches
2. **Consolidate formatting**: Choose one formatting approach, merge it
3. **Remove obvious duplicates**: Delete clearly redundant branches
4. **Enable auto-delete**: Configure GitHub to auto-delete merged branches

### Phase 2: Short-term (Next 2 Weeks)  
1. **Review all codex branches**: Systematically evaluate each for value
2. **Merge valuable features**: Create PRs for useful functionality
3. **Document decisions**: Record what was kept/discarded and why
4. **Set up monitoring**: Implement branch count tracking

### Phase 3: Long-term (Ongoing)
1. **Weekly cleanup**: Run automated cleanup weekly
2. **Monthly reviews**: Review stale branches monthly
3. **Process improvements**: Refine branch management based on experience
4. **Team training**: Ensure all developers follow branch management practices

## Tools and Scripts

### Available Tools
- `.github/workflows/branch-cleanup.yml` - Automated branch cleanup
- `scripts/auto_merge_safe.sh` - Automatically merges branches prefixed with
  `safe/` into the target branch. Run `./scripts/auto_merge_safe.sh` to merge
  all safe branches into `main` by default.
- `scripts/enhanced_branch_analyzer.sh` - Detailed branch categorization
- `scripts/post_merge_validation.sh` - Post-merge validation and testing

### Usage Examples

```bash
# Trigger the cleanup workflow manually (optional)
# This can also be scheduled via GitHub Actions
gh workflow run branch-cleanup.yml

# Manual merge with validation
git merge origin/BRANCH_NAME
./scripts/post_merge_validation.sh

# Manual conflict resolution
./scripts/manual_merge_branch.sh BRANCH_NAME

# Check branch status
git for-each-ref --format='%(refname:short) %(committerdate:relative)' refs/remotes/origin
```

## Success Metrics

### Target Goals
- **Branch count**: <20 active branches
- **Branch age**: No branches >30 days old
- **Cleanup frequency**: Weekly automated cleanup
- **Merge velocity**: Average branch lifetime <7 days

### Monthly Review
- Total branches created vs deleted
- Average branch lifetime
- Number of stale branches
- Automated cleanup success rate

---

**Remember**: The goal is not just to delete branches, but to maintain a clean, organized repository that supports productive development. Always err on the side of caution when deleting branches with potentially valuable work.

**Next Action**: Review the critical branches list and begin systematic triage of the 84 unmerged branches.