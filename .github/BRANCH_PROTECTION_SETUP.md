# GitHub Branch Protection Rules Setup

This document provides step-by-step instructions for configuring GitHub branch protection rules and repository settings to maintain a clean and secure repository.

## Repository Settings Configuration

### 1. General Settings

Navigate to **Settings → General → Pull Requests** and configure:

- ✅ **Allow merge commits**
- ✅ **Allow squash merging** 
- ✅ **Allow rebase merging**
- ✅ **Always suggest updating pull request branches**
- ✅ **Allow auto-merge**
- ✅ **Automatically delete head branches** ⭐ **CRITICAL**

### 2. Branch Protection Rules

Navigate to **Settings → Branches** and add the following rule for `main`:

#### Main Branch Protection Rule

**Branch name pattern**: `main`

**Protect matching branches:**
- ✅ **Require a pull request before merging**
  - Required number of reviewers: `1`
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ✅ Require review from code owners (if CODEOWNERS file exists)
  
- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Status checks to require:
    - `CI / test (ubuntu-latest, 3.9)`
    - `CI / test (ubuntu-latest, 3.10)`
    - `CI / test (ubuntu-latest, 3.11)`
    - `CI / lint`
    - `CI / security`

- ✅ **Require conversation resolution before merging**
- ✅ **Require signed commits** (optional but recommended)
- ✅ **Require linear history** (optional - prevents merge commits)
- ✅ **Include administrators** (applies rules to admins too)
- ✅ **Restrict pushes that create files** (optional)

#### Additional Branch Protection (Optional)

For development branches like `develop` or `staging`, create similar rules with potentially relaxed requirements.

### 3. Repository Security Settings

Navigate to **Settings → Security & analysis**:

- ✅ **Dependency graph**
- ✅ **Dependabot alerts**
- ✅ **Dependabot security updates**
- ✅ **Secret scanning**
- ✅ **Push protection** (for secret scanning)

### 4. Actions Permissions

Navigate to **Settings → Actions → General**:

- **Actions permissions**: 
  - ✅ Allow enterprise, and select non-enterprise, actions and reusable workflows
  - ✅ Allow actions created by GitHub
  - ✅ Allow specified actions and reusable workflows

- **Workflow permissions**:
  - ✅ Read and write permissions
  - ✅ Allow GitHub Actions to create and approve pull requests

## Branch Naming Conventions

Enforce these naming conventions for consistency:

### Recommended Branch Names

- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Critical fixes
- `codex/description` - AI-generated changes
- `dependabot/dependency-updates` - Dependency updates

### Protected Branch Names

Never use these patterns for feature branches:
- `main`, `master` - Primary branches
- `release/*` - Release branches
- `hotfix/*` - Critical fixes only

## Automated Branch Management

### Current Automation

1. **Weekly Cleanup**: Automated workflow runs every Sunday at 2 AM UTC
2. **Auto-delete**: GitHub automatically deletes merged branches
3. **Security Scanning**: Automated security checks on all PRs
4. **Branch Cleanup Workflow**: See `.github/workflows/branch-cleanup.yml`
   - This is the recommended way to remove merged branches.

### Manual Cleanup Commands

```bash
# View current branch status
git branch -r | wc -l
git branch -r --merged main | grep -v 'main\|master\|HEAD'

# Manual cleanup (if needed)
git branch -r --merged main | grep 'codex/' | sed 's/origin\///' | xargs -I {} git push origin --delete {}
```

## Best Practices

### For Contributors

1. **Always create pull requests** - Never push directly to main
2. **Use descriptive branch names** - Follow naming conventions
3. **Keep branches focused** - One feature/fix per branch
4. **Delete branches after merge** - Keep repository clean
5. **Rebase before PR** - Maintain linear history

### For Maintainers

1. **Review all PRs** - Ensure code quality
2. **Require status checks** - All tests must pass
3. **Use squash merge** - Keep history clean
4. **Delete merged branches** - Automatic deletion enabled
5. **Monitor security alerts** - Address promptly

### For Repository Health

1. **Weekly branch cleanup** - Automated via GitHub Actions
2. **Monthly security review** - Check Dependabot alerts
3. **Quarterly rule review** - Update protection rules as needed
4. **Monitor repository metrics** - Track branch count, PR velocity

## Troubleshooting

### Common Issues

**Problem**: Cannot delete protected branch
**Solution**: Temporarily disable branch protection, delete branch, re-enable protection

**Problem**: Status checks not appearing
**Solution**: Ensure workflow names match exactly in branch protection settings

**Problem**: Auto-delete not working
**Solution**: Verify "Automatically delete head branches" is enabled in repository settings

**Problem**: Too many stale branches
**Solution**: Trigger the **Branch Cleanup** workflow or prune branches manually

### Emergency Procedures

If branch protection prevents critical fixes:

1. **Temporary bypass**: Admin can disable rules temporarily
2. **Hotfix process**: Create `hotfix/critical-fix` branch
3. **Fast-track review**: Assign multiple reviewers
4. **Post-fix audit**: Review what happened and improve process

## Monitoring and Metrics

### Key Metrics to Track

- **Branch count**: Should stay under 100 active branches
- **Stale branches**: Branches older than 30 days
- **Merge velocity**: Time from PR creation to merge
- **Failed merges**: PRs that fail status checks

### Alerts to Set Up

1. **High branch count** (>150 branches)
2. **Failed workflow runs** (cleanup failures)
3. **Security alerts** (vulnerability detection)
4. **Large PRs** (>500 lines changed)

## Configuration Files

This setup works with the following repository files:

- `.github/workflows/branch-cleanup.yml` - Automated cleanup
- `.github/workflows/ci.yml` - Status checks
- `.github/workflows/branch-cleanup.yml` - Automated cleanup
- `CODEOWNERS` - Code review assignments (optional)

## Compliance and Auditing

### Audit Trail

GitHub maintains logs of:
- Branch protection rule changes
- Force pushes (should be none)
- Admin overrides
- Security events

### Compliance Requirements

For regulated environments, consider:
- **Required signed commits**
- **Additional reviewers** (2+ for critical changes)
- **Deployment protection rules**
- **Environment-specific approvals**

---

**Last Updated**: December 2024
**Maintained By**: OpenWebUI Installer Team
**Review Schedule**: Quarterly