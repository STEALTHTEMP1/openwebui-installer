# Development Team Guide

This repository uses GitHub Actions to enforce branch hygiene and a helper script to create feature branches from the proper base.

## Pull Request Branch Enforcement

Pull requests targeting `main` must originate from either the `develop` branch or a `phase` branch. The workflow `pr-branch-check.yml` automatically fails if a PR originates from any other branch.

## Creating Feature Branches

Use `scripts/create_feature_branch.sh` to create a feature branch from the current phase or `develop` branch:

```bash
./scripts/create_feature_branch.sh my-feature
```

The script detects a local branch beginning with `phase` and uses it as the base. If no phase branch exists, it falls back to `develop`.
