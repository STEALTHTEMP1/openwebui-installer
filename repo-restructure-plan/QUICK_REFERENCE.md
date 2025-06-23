# Repository Restructuring Quick Reference

## 🚀 Quick Start

### 1. Run the Restructuring Script
```bash
cd openwebuiinstaller
chmod +x repo-restructure-plan/restructure-repo.sh
./repo-restructure-plan/restructure-repo.sh
```

### 2. Validate the Changes
```bash
chmod +x repo-restructure-plan/validate-restructure.sh
./repo-restructure-plan/validate-restructure.sh
```

### 3. Commit and Push
```bash
# Public repo
git add .
git commit -m "feat: minimize public surface area - move internal tools to private repo"
git push

# Private repo (if created)
cd ../openwebui-installer-internal
git add .
git commit -m "initial: internal tools from public repo"
git remote add origin git@github.com:YOUR_ORG/openwebui-installer-internal.git
git push -u origin main
```

## 📁 What Stays Public

### Core Installer (REQUIRED)
- `openwebui_installer/` - Python package
- `install.py` - Main installer script
- `setup.py`, `setup.sh` - Setup scripts
- `pyproject.toml` - Python project config
- `requirements*.txt` - Dependencies

### Essential Config (REQUIRED)
- `.dockerignore`, `.gitignore`
- `.env.example` - Example environment
- `Dockerfile.*` - Container definitions
- `.codexrc` - Codex configuration

### CI/CD (REQUIRED)
- `.github/workflows/ci.yml` - CI pipeline
- `.github/workflows/release.yml` - Release automation
- `.github/dependabot.yml` - Dependency updates

### Documentation (REQUIRED)
- `README.md` - Main documentation
- `LICENSE` - License file
- `CHANGELOG.md` - Version history
- `GETTING_STARTED.md` - User guide

### Distribution (OPTIONAL)
- `helm-chart/` - Kubernetes Helm chart
- `homebrew-tap/` - Homebrew formula
- `kubernetes/` - K8s manifests
- `terraform/` - Infrastructure as code

## 🔒 What Goes Private

### Branch Management (~40 files)
- `.branch-analysis/` - All analysis data
- `scripts/*branch*.sh` - Branch scripts
- `scripts/*merge*.sh` - Merge scripts
- `*BRANCH*.md` - Branch documentation

### Internal Tools
- Development scripts
- Test utilities
- Internal documentation
- Development environments
- Analysis tools

### Sensitive Files
- `.env.dev` - Dev environment
- `*.bak` - Backup files
- Internal workflows
- Private configurations

## ⚡ Quick Commands

### Check What Would Be Moved
```bash
# List files that would go private
find . -name "*branch*" -o -name "*merge*" -o -name "*.bak" | grep -v .git
```

### Create Private Repo via GitHub CLI
```bash
gh repo create openwebui-installer-internal --private --description "Internal tools for OpenWebUI Installer"
```

### Add Private Submodule (Alternative)
```bash
git submodule add git@github.com:YOUR_ORG/openwebui-installer-internal.git .internal
echo ".internal/" >> .gitignore
```

### Clean Git History (if needed)
```bash
# Remove sensitive files from history
git filter-branch --tree-filter 'rm -rf .branch-analysis' HEAD
# OR use BFG Repo-Cleaner (faster)
bfg --delete-folders .branch-analysis
```

## 📊 Impact Summary

### Before
- **212** total files/directories
- **~50** internal tool files exposed
- **~40** branch management files
- Cluttered repository structure

### After
- **~80** files (62% reduction)
- **0** internal tools exposed
- **0** branch management files
- Clean, user-focused structure

## ✅ Validation Checklist

- [ ] Core installer files present
- [ ] No internal tools in public repo
- [ ] CI/CD workflows functional
- [ ] Documentation complete
- [ ] Installation process works
- [ ] Distribution methods intact
- [ ] No sensitive data exposed
- [ ] Git history clean (optional)

## 🚨 Common Issues

### Missing Required Files
If validation fails for required files:
1. Check if file was accidentally moved
2. Restore from backup directory
3. Re-run validation

### Import Errors
If Python imports fail:
1. Ensure `__init__.py` exists
2. Check PYTHONPATH
3. Verify package structure

### CI/CD Failures
If workflows break:
1. Update paths in workflow files
2. Check for missing dependencies
3. Verify secrets/variables

## 📝 Notes

- Always backup before restructuring
- Test installation after changes
- Update team documentation
- Consider using Git tags before major changes
- Keep private repo access restricted