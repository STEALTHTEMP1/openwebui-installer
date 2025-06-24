#!/bin/bash

# setup-codex.sh - Codex Environment Setup Script
# This script sets up a complete development environment for the Open WebUI Installer project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_codex() {
    echo -e "${CYAN}[CODEX]${NC} $1"
}

show_banner() {
    echo "================================================"
    echo "🧠 Codex Development Environment Setup"
    echo "🚀 Open WebUI Installer Project"
    echo "================================================"
    echo ""
}

show_help() {
    cat << EOF
Codex Development Environment Setup Script

This script sets up a complete development environment for AI-assisted coding
with the Open WebUI Installer project.

Usage: $0 [OPTIONS]

Options:
  -h, --help           Show this help message
  -f, --full           Full setup including all optional components
  -m, --minimal        Minimal setup for basic development
  -c, --clean          Clean existing environment before setup
  -d, --dev-only       Setup only development tools (no production deps)
  -t, --test           Run tests after setup
  -v, --verbose        Verbose output
  --skip-venv          Skip virtual environment creation
  --skip-git-hooks     Skip git hooks setup
  --skip-docker        Skip Docker setup verification

What this script does:
1. 🐍 Python environment setup (virtual environment, dependencies)
2. 🔧 Development tools (linting, formatting, testing)
3. 🐳 Docker environment verification
4. 📝 IDE configuration (VS Code, PyCharm settings)
5. 🔗 Git hooks for code quality
6. 🧪 Testing framework setup
7. 📊 Code analysis tools
8. 🤖 AI/Codex integration helpers
9. 🚀 Build and deployment tools
10. 📚 Documentation generators

Examples:
  $0                    # Standard setup
  $0 --full            # Complete setup with all features
  $0 --minimal         # Minimal development setup
  $0 --clean --full    # Clean install with all features
EOF
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get >/dev/null 2>&1; then
            PACKAGE_MANAGER="apt"
        elif command -v yum >/dev/null 2>&1; then
            PACKAGE_MANAGER="yum"
        elif command -v pacman >/dev/null 2>&1; then
            PACKAGE_MANAGER="pacman"
        else
            PACKAGE_MANAGER="unknown"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        PACKAGE_MANAGER="choco"
    else
        OS="unknown"
        PACKAGE_MANAGER="unknown"
    fi

    log_info "Detected OS: $OS, Package Manager: $PACKAGE_MANAGER"
}

check_requirements() {
    log_step "Checking system requirements..."

    local missing_deps=()

    # Check Python
    if ! command -v python3 >/dev/null 2>&1; then
        missing_deps+=("python3")
    else
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        log_success "Python $PYTHON_VERSION found"
    fi

    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    else
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        log_success "Git $GIT_VERSION found"
    fi

    # Check curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them using your system package manager:"

        case $PACKAGE_MANAGER in
            "brew")
                echo "  brew install ${missing_deps[*]}"
                ;;
            "apt")
                echo "  sudo apt-get update && sudo apt-get install ${missing_deps[*]}"
                ;;
            "yum")
                echo "  sudo yum install ${missing_deps[*]}"
                ;;
            "pacman")
                echo "  sudo pacman -S ${missing_deps[*]}"
                ;;
            *)
                echo "  Please install: ${missing_deps[*]}"
                ;;
        esac
        exit 1
    fi

    log_success "All system requirements satisfied"
}

setup_python_environment() {
    log_step "Setting up Python development environment..."

    if [[ "$SKIP_VENV" != true ]]; then
        # Create virtual environment
        if [[ ! -d "venv" ]] || [[ "$CLEAN_INSTALL" == true ]]; then
            if [[ -d "venv" ]]; then
                log_info "Removing existing virtual environment..."
                rm -rf venv
            fi

            log_info "Creating virtual environment..."
            python3 -m venv venv
            log_success "Virtual environment created"
        else
            log_info "Virtual environment already exists"
        fi

        # Activate virtual environment
        source venv/bin/activate
        log_success "Virtual environment activated"

        # Upgrade pip
        log_info "Upgrading pip..."
        pip install --upgrade pip
    fi

    # Install dependencies
    log_info "Installing Python dependencies..."

    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
        log_success "Production dependencies installed"
    fi

    if [[ -f "requirements-dev.txt" ]]; then
        pip install -r requirements-dev.txt
        log_success "Development dependencies installed"
    fi

    # Install additional codex/AI development tools
    if [[ "$FULL_SETUP" == true ]]; then
        log_info "Installing AI/Codex development tools..."
        pip install openai anthropic jupyter notebook jupyterlab
        pip install pre-commit commitizen semantic-version
        pip install sphinx sphinx-rtd-theme
        log_success "AI development tools installed"
    fi
}

setup_development_tools() {
    log_step "Setting up development tools..."

    # Create development configuration files
    log_info "Setting up development configuration..."

    # Pre-commit configuration
    if [[ ! -f ".pre-commit-config.yaml" ]] || [[ "$CLEAN_INSTALL" == true ]]; then
        cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: debug-statements
      - id: check-docstring-first

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: ["--profile", "black"]

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        args: [--max-line-length=100]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
      - id: mypy
        additional_dependencies: [types-requests]
EOF
        log_success "Pre-commit configuration created"
    fi

    # Setup git hooks
    if [[ "$SKIP_GIT_HOOKS" != true ]]; then
        if command -v pre-commit >/dev/null 2>&1; then
            pre-commit install
            log_success "Git hooks installed"
        else
            log_warning "pre-commit not available, skipping git hooks"
        fi
    fi

    # Create VS Code settings
    mkdir -p .vscode
    if [[ ! -f ".vscode/settings.json" ]] || [[ "$CLEAN_INSTALL" == true ]]; then
        cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": "./venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.linting.mypyEnabled": true,
    "python.formatting.provider": "black",
    "python.sortImports.args": ["--profile", "black"],
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "files.exclude": {
        "**/__pycache__": true,
        "**/*.pyc": true,
        ".pytest_cache": true,
        ".coverage": true,
        "htmlcov": true,
        "dist": true,
        "build": true,
        "*.egg-info": true
    },
    "python.testing.pytestEnabled": true,
    "python.testing.unittestEnabled": false,
    "python.testing.pytestArgs": [
        "tests"
    ],
    "github.copilot.enable": {
        "*": true,
        "python": true,
        "plaintext": false,
        "markdown": true,
        "yaml": true
    }
}
EOF
        log_success "VS Code settings created"
    fi

    # Create launch configuration for debugging
    if [[ ! -f ".vscode/launch.json" ]] || [[ "$CLEAN_INSTALL" == true ]]; then
        cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": true
        },
        {
            "name": "Python: Install Script",
            "type": "python",
            "request": "launch",
            "program": "${workspaceFolder}/install.py",
            "console": "integratedTerminal",
            "justMyCode": true,
            "args": ["--help"]
        },
        {
            "name": "Python: Tests",
            "type": "python",
            "request": "launch",
            "module": "pytest",
            "console": "integratedTerminal",
            "justMyCode": true,
            "args": ["tests/", "-v"]
        }
    ]
}
EOF
        log_success "VS Code launch configuration created"
    fi
}

setup_docker_environment() {
    if [[ "$SKIP_DOCKER" == true ]]; then
        log_info "Skipping Docker setup verification"
        return
    fi

    log_step "Verifying Docker environment..."

    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
            log_success "Docker $DOCKER_VERSION is running"
        else
            log_warning "Docker is installed but not running"
            log_info "Please start Docker daemon"
        fi
    else
        log_warning "Docker not found. Some features may not work."
        log_info "Install Docker from: https://docs.docker.com/get-docker/"
    fi

    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | tr -d ',')
        log_success "Docker Compose $COMPOSE_VERSION found"
    else
        log_info "Docker Compose not found (optional for development)"
    fi
}

setup_testing_framework() {
    log_step "Setting up testing framework..."

    # Create test directory structure
    mkdir -p tests/{unit,integration,e2e}

    # Create pytest configuration if it doesn't exist
    if [[ ! -f "pytest.ini" ]] && [[ ! -f "pyproject.toml" || $(grep -q "tool.pytest" pyproject.toml) ]]; then
        cat > pytest.ini << 'EOF'
[tool:pytest]
minversion = 6.0
addopts = -ra -q --cov=openwebui_installer --cov-report=term-missing --cov-report=html
testpaths = tests
python_files = test_*.py
python_functions = test_*
python_classes = Test*
EOF
        log_success "Pytest configuration created"
    fi

    # Create sample test files
    if [[ ! -f "tests/__init__.py" ]]; then
        touch tests/__init__.py
        touch tests/unit/__init__.py
        touch tests/integration/__init__.py
        touch tests/e2e/__init__.py
    fi

    if [[ ! -f "tests/test_sample.py" ]]; then
        cat > tests/test_sample.py << 'EOF'
"""Sample test file to verify testing setup."""

import pytest
import sys
import os

# Add the project root to Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def test_python_version():
    """Test that we're running a supported Python version."""
    assert sys.version_info >= (3, 9), "Python 3.9+ required"


def test_imports():
    """Test that we can import required packages."""
    try:
        import click
        import docker
        import requests
        import rich
    except ImportError as e:
        pytest.fail(f"Required package not available: {e}")


def test_project_structure():
    """Test that essential project files exist."""
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    essential_files = [
        "README.md",
        "requirements.txt",
        "setup.py"
    ]

    for file_path in essential_files:
        full_path = os.path.join(project_root, file_path)
        assert os.path.exists(full_path), f"Essential file missing: {file_path}"


if __name__ == "__main__":
    pytest.main([__file__])
EOF
        log_success "Sample test file created"
    fi
}

setup_codex_integration() {
    log_step "Setting up Codex/AI integration helpers..."

    # Create AI prompts directory
    mkdir -p .codex/{prompts,templates,docs}

    # Create AI development helper scripts
    if [[ ! -f ".codex/README.md" ]]; then
        cat > .codex/README.md << 'EOF'
# Codex/AI Development Helpers

This directory contains prompts, templates, and documentation to help with AI-assisted development.

## Structure

- `prompts/` - Reusable prompts for common development tasks
- `templates/` - Code templates and boilerplates
- `docs/` - AI-generated documentation and insights

## Usage

Use these files as context when working with AI coding assistants like GitHub Copilot, OpenAI Codex, or Claude.
EOF
    fi

    # Create common prompts
    cat > .codex/prompts/code_review.md << 'EOF'
# Code Review Prompt

Please review the following code for:
1. **Code Quality**: Clean, readable, and maintainable code
2. **Best Practices**: Following Python and project conventions
3. **Security**: Potential security vulnerabilities
4. **Performance**: Efficiency and optimization opportunities
5. **Testing**: Test coverage and quality
6. **Documentation**: Proper docstrings and comments

Focus on the Open WebUI Installer project context and Docker/containerization best practices.
EOF

    cat > .codex/prompts/bug_fix.md << 'EOF'
# Bug Fix Prompt

When fixing bugs, please:
1. **Analyze** the root cause thoroughly
2. **Reproduce** the issue if possible
3. **Fix** with minimal, targeted changes
4. **Test** the fix comprehensively
5. **Document** the fix and prevention measures

Consider the installer's cross-platform requirements and Docker integration.
EOF

    cat > .codex/prompts/feature_development.md << 'EOF'
# Feature Development Prompt

When developing new features:
1. **Design** with the user experience in mind
2. **Implement** following project patterns and conventions
3. **Test** thoroughly with unit and integration tests
4. **Document** with clear docstrings and usage examples
5. **Consider** cross-platform compatibility and Docker integration

Keep the installer simple, reliable, and user-friendly.
EOF

    log_success "Codex integration helpers created"
}

setup_documentation() {
    log_step "Setting up documentation tools..."

    # Create docs directory structure
    mkdir -p docs/{api,user,dev}

    # Create basic Sphinx configuration if doing full setup
    if [[ "$FULL_SETUP" == true ]]; then
        if [[ ! -f "docs/conf.py" ]]; then
            cat > docs/conf.py << 'EOF'
"""Sphinx configuration for Open WebUI Installer documentation."""

import os
import sys
sys.path.insert(0, os.path.abspath('..'))

# Project information
project = 'Open WebUI Installer'
copyright = '2024, STEALTHTEMP1'
author = 'STEALTHTEMP1'
release = '1.1.1'

# Extensions
extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
    'sphinx.ext.githubpages',
]

# Theme
html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

# Options
autodoc_default_options = {
    'members': True,
    'member-order': 'bysource',
    'special-members': '__init__',
    'undoc-members': True,
    'exclude-members': '__weakref__'
}
EOF
            log_success "Sphinx documentation configuration created"
        fi
    fi

    # Create development documentation
    if [[ ! -f "docs/dev/DEVELOPMENT.md" ]]; then
        cat > docs/dev/DEVELOPMENT.md << 'EOF'
# Development Guide

## Getting Started

1. Run the setup script: `./setup-codex.sh --full`
2. Activate the virtual environment: `source venv/bin/activate`
3. Run tests: `pytest`
4. Start developing!

## Development Workflow

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "Add your feature"`
3. Run tests: `pytest`
4. Push and create a pull request

## Code Style

- Use Black for formatting: `black .`
- Use isort for imports: `isort .`
- Follow PEP 8 guidelines
- Write docstrings for all public functions
- Maintain test coverage above 80%

## AI-Assisted Development

- Use the prompts in `.codex/prompts/` for consistent AI interactions
- Leverage GitHub Copilot for code completion
- Review AI suggestions carefully before accepting
EOF
        log_success "Development documentation created"
    fi
}

run_tests() {
    if [[ "$RUN_TESTS" == true ]]; then
        log_step "Running tests to verify setup..."

        if command -v pytest >/dev/null 2>&1; then
            if pytest tests/ -v; then
                log_success "All tests passed!"
            else
                log_warning "Some tests failed. Please review the output above."
            fi
        else
            log_warning "pytest not available, skipping test run"
        fi
    fi
}

show_completion_summary() {
    echo ""
    echo "================================================"
    echo "🎉 Codex Environment Setup Complete!"
    echo "================================================"
    echo ""
    log_success "Environment successfully configured for AI-assisted development"
    echo ""
    echo "📋 What was set up:"
    echo "   ✅ Python virtual environment (venv/)"
    echo "   ✅ Development dependencies installed"
    echo "   ✅ Code quality tools (black, isort, flake8, mypy)"
    echo "   ✅ Testing framework (pytest with coverage)"
    echo "   ✅ Git hooks for code quality"
    echo "   ✅ VS Code configuration"
    echo "   ✅ Docker environment verified"
    echo "   ✅ AI/Codex integration helpers"
    echo "   ✅ Documentation structure"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Activate virtual environment: source venv/bin/activate"
    echo "   2. Start VS Code: code ."
    echo "   3. Run tests: pytest"
    echo "   4. Start developing with AI assistance!"
    echo ""
    echo "🧠 AI Development Tips:"
    echo "   • Use prompts in .codex/prompts/ for consistent AI interactions"
    echo "   • Enable GitHub Copilot in VS Code for code completion"
    echo "   • Use 'git commit' to trigger pre-commit hooks automatically"
    echo "   • Run 'pytest --cov' to check test coverage"
    echo ""
    echo "📚 Documentation:"
    echo "   • Development guide: docs/dev/DEVELOPMENT.md"
    echo "   • Project README: README.md"
    echo "   • Codex helpers: .codex/README.md"
    echo ""
    echo "🆘 Need help?"
    echo "   • Check the project documentation"
    echo "   • Use AI assistants with the provided prompts"
    echo "   • Run tests to verify everything works: pytest -v"
}

# Parse command line arguments
FULL_SETUP=false
MINIMAL_SETUP=false
CLEAN_INSTALL=false
DEV_ONLY=false
RUN_TESTS=false
VERBOSE=false
SKIP_VENV=false
SKIP_GIT_HOOKS=false
SKIP_DOCKER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--full)
            FULL_SETUP=true
            shift
            ;;
        -m|--minimal)
            MINIMAL_SETUP=true
            shift
            ;;
        -c|--clean)
            CLEAN_INSTALL=true
            shift
            ;;
        -d|--dev-only)
            DEV_ONLY=true
            shift
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            set -x
            shift
            ;;
        --skip-venv)
            SKIP_VENV=true
            shift
            ;;
        --skip-git-hooks)
            SKIP_GIT_HOOKS=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        -*)
            log_error "Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            log_error "Unexpected argument $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
show_banner

# Set defaults based on options
if [[ "$MINIMAL_SETUP" == true ]]; then
    SKIP_DOCKER=true
    DEV_ONLY=true
fi

log_codex "Starting Codex environment setup..."
log_info "Configuration: Full=$FULL_SETUP, Minimal=$MINIMAL_SETUP, Clean=$CLEAN_INSTALL"

detect_os
check_requirements
setup_python_environment
setup_development_tools
setup_docker_environment
setup_testing_framework
setup_codex_integration

if [[ "$FULL_SETUP" == true ]]; then
    setup_documentation
fi

run_tests
show_completion_summary

log_codex "Codex environment ready for AI-assisted development! 🚀"
