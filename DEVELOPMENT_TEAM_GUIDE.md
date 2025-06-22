# Development Team Guide

This guide summarizes key references and processes for contributing to the **Open WebUI Installer** project.

## Key Documents
- **ONE_CLICK_REQUIREMENTS.md** – overall product vision and requirements
- **NATIVE_WRAPPER_ANALYSIS.md** – evaluation of native macOS wrapper approach
- **CODEBASE_EVALUATION.md** – existing code assessment and reusable components
- **DOCKER_ABSTRACTION_STRATEGY.md** – approach for hiding container complexity
- **WORKING_SETUP.md** – verified setup steps for running the installer

Review these documents before making changes to ensure alignment with the project goals.

## GitHub Branching Strategy

We use a phase‑based feature flow:
```
main
└── develop
    ├── phase/1-mvp
    │   └── feature/<name>
    ├── phase/2-enhanced
    │   └── feature/<name>
    └── phase/3-advanced
        └── feature/<name>
```
- **main** – production-ready releases only
- **develop** – integration branch for active development
- **phase/*-*** – branches for each project phase
- **feature/** – short-lived branches for individual features. Branch from the appropriate phase branch and merge back via pull request.

## Development Workflow
1. Create your feature branch: `git checkout -b feature/<name> phase/<phase-name>`
2. Implement changes with tests and documentation.
3. Run `pre-commit` and relevant tests.
4. Open a PR to merge into the phase branch. Ensure GitHub Actions pass and at least one reviewer approves.
5. After phase completion, merge the phase branch into **develop**. Releases are tagged from **main**.

## Cross-Platform Scripts
All scripts in `scripts/` should be compatible with both macOS and Linux. Use POSIX shell syntax and avoid platform-specific commands whenever possible.

## Security & Maintainability
- Follow best practices for handling secrets. Use GitHub Actions secrets for CI credentials.
- Keep third-party dependencies up to date.
- Add comments to complex logic and maintain code readability.
- Reuse existing modules and scripts in `scripts/` and `openwebui_installer/` instead of duplicating functionality.

## Getting Started
1. Clone the repository.
2. Install development dependencies as described in `README.md`.
3. Start with the `feature/swift-app-foundation` branch under `phase/1-mvp` to implement the SwiftUI wrapper.

For any questions, create an issue with the label `dev-help`.
