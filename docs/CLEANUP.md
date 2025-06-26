# Repository Cleanup: Branches & Xcode Projects

This document describes how to keep your repository clean of stale/merged branches and abandoned Xcode project directories, via both manual and automated methods.

---

## 1. Automated Branch Cleanup (via CI)

**Workflow:**  
- The repository includes a scheduled GitHub Actions workflow:  
  `.github/workflows/branch-cleanup.yml`
- **What it does:**  
  - Runs weekly, or can be triggered ad-hoc via GitHub Actions "workflow dispatch".
  - Finds remote branches that:
    - Are already merged into the main branch (`main` or `master`)
    - Match safe-to-delete patterns (e.g., `codex/`, `feature/`, `bugfix/`, `dependabot/`)
  - Either prints what would be deleted (dry run) or actually deletes them (production run).
  - Writes a full log and summary to the GitHub Actions workflow log.

**How to manually trigger a dry run:**
1. Go to **Actions** in the GitHub UI, choose **Branch Cleanup**
2. Click **Run workflow**, select "dry_run" as `true`
3. Review the report to see what would be deleted on the next scheduled or production run

---

## 2. Manual Branch Analysis and Cleanup

Use the **Branch Cleanup** workflow to safely remove merged branches. It can be
triggered from the GitHub Actions tab with a dry-run option.

```bash
# Manually list merged branches for review
git branch -r --merged main | grep -v 'main\|master\|HEAD'

# Delete a merged branch manually (if scripts are unavailable)
git push origin --delete BRANCH_NAME
```

---

## 3. Xcode Project Folder Cleanup

With time, abandoned Xcode `.xcodeproj` or `.xcworkspace` directories can accumulate.  
The script `scripts/find_and_cleanup_xcode_projects.sh` helps find and prune these:

- **Dry run (only lists candidates):**  
  `./scripts/find_and_cleanup_xcode_projects.sh`
- **Actually delete:**  
  `DRY_RUN=0 ./scripts/find_and_cleanup_xcode_projects.sh`

The script will prompt for confirmation before deleting any folders, and by default will only remove those not modified in the last **90 days**.

---

## 4. Best Practices

**Before deleting anything:**
- Always read the generated report for recommended deletions.
- Double-check no one is actively working on listed branches or directories.
- Rerun with `DRY_RUN=1` if unsure; inspect results safely.

**Automated cleanup:**
- Use the CI workflow for regular maintenance.
- Prefer dry runs before enabling actual branch deletion on schedule.
- Enable branch protection rules and GitHub's own auto-delete for merged PR branches if available.

**Manual cleanup:**
- Use the provided scripts for detailed reports, especially before big refactors or releases.
- Commit/remove obsolete directories after confirming they're not required.

**After cleanup:**
- Push changes to the repo and notify team members if any significant directories or branches were removed.
- Archive critical backups if desired.

---

## 5. Troubleshooting

- If a script fails due to permissions, check you have write access to the repo or file system.
- If there are merge conflicts with scripts or backup folders, resolve them and retry.
- If you run into platform issues (macOS vs Linux vs CI), scripts are written to be as cross-compatible as possible, but test on your platform before bulk-deleting.

---

**Contributions and improvements to these workflows and scripts are welcome.**  
Always be cautious with destructive operations and favor backup/review!
