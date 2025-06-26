# Development Team Guide

This project uses automation to enforce a clean Git history and consistent workflows.

## Pull Request Branch Rules

Pull requests targeting `main` must originate from the `develop` branch or a `phase-*` branch. A GitHub Actions workflow validates this automatically and will fail if the requirement is not met.

## Creating Feature Branches

Use the `scripts/create_feature_branch.sh` script to create feature branches from the correct base. The script fetches the latest branches and creates your feature branch from `develop` if it exists, otherwise from the latest `phase-*` branch.

```bash
./scripts/create_feature_branch.sh my-feature
```

Pass `--base <branch>` to override the default base.

## Continuous Integration

GitHub Actions runs tests and linting for every pull request. Ensure all checks pass before requesting reviews.

## Architectural Considerations

The CLI installer shares its core container-management code with the macOS App Store. Any architectural changes that diverge from this common core must be reviewed before implementation. The CLI must continue to support macOS and Linux, with native Windows support planned for a future phase.

