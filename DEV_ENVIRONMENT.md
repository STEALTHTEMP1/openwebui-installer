# Development Environment Guide

This guide helps you set up and use the complete development environment for the Open WebUI Installer project.

## Quick Start

```bash
# 1. Initial setup (run once)
./setup-codex.sh --full

# 2. Start development environment
./dev.sh start

# 3. Open development shell
./dev.sh shell

# 4. Run tests
./dev.sh test
```

## Environment Components

### 🧠 Codex Development Setup
- **Python virtual environment** with all dependencies
- **Code quality tools** (Black, isort, flake8, mypy, pylint)
- **Testing framework** (pytest with coverage)
- **Pre-commit hooks** for code quality
- **VS Code configuration** with AI assistance
- **Documentation tools** (Sphinx)

### 🐳 Docker Development Stack
- **Development container** with full Python environment
- **Database** (PostgreSQL for testing)
- **Cache** (Redis for session management)
- **Code quality container** with analysis tools
- **AI development container** with Jupyter Lab
- **Documentation server** (Sphinx + HTTP server)
- **Monitoring stack** (Prometheus + Grafana)

## Setup Scripts

### setup-codex.sh
Complete development environment setup for AI-assisted coding.

```bash
# Full setup with all features
./setup-codex.sh --full

# Minimal setup for basic development
./setup-codex.sh --minimal

# Clean install (removes existing environment)
./setup-codex.sh --clean --full

# Skip specific components
./setup-codex.sh --skip-docker --skip-git-hooks
```

**What it sets up:**
- Python virtual environment (`venv/`)
- Development dependencies (pytest, black, mypy, etc.)
- VS Code configuration (`.vscode/`)
- Git hooks for code quality
- AI/Codex integration helpers (`.codex/`)
- Testing framework with sample tests
- Documentation structure

### dev.sh
Development environment management and Docker orchestration.

```bash
# Environment management
./dev.sh setup          # Initial setup
./dev.sh start           # Start all services
./dev.sh stop            # Stop all services
./dev.sh restart         # Restart all services
./dev.sh status          # Show service status

# Development workflow
./dev.sh shell           # Open development shell
./dev.sh test            # Run tests with coverage
./dev.sh lint            # Run code quality checks
./dev.sh format          # Format code (black, isort)

# Specialized environments
./dev.sh ai              # Start AI development (Jupyter)
./dev.sh docs            # Start documentation server
./dev.sh monitor         # Start monitoring dashboard

# Maintenance
./dev.sh build           # Build Docker images
./dev.sh clean           # Clean containers and images
./dev.sh reset           # Complete reset
./dev.sh backup          # Backup development data
./dev.sh restore <dir>   # Restore from backup
```

## Development Workflows

### 1. Standard Python Development

```bash
# Setup
./setup-codex.sh

# Activate virtual environment
source venv/bin/activate

# Start coding
code .

# Run tests
pytest

# Format code
black .
isort .

# Type checking
mypy .
```

### 2. Docker-based Development

```bash
# Start environment
./dev.sh start

# Open development shell
./dev.sh shell

# Inside container:
python install.py --help
pytest tests/
black --check .
```

### 3. AI-Assisted Development

```bash
# Start AI environment
./dev.sh ai

# Open Jupyter Lab (http://localhost:8889)
./dev.sh jupyter

# Use notebooks in /workspace/notebooks/
# Use prompts in .codex/prompts/
```

### 4. Documentation Development

```bash
# Start documentation server
./dev.sh docs

# Access at http://localhost:8080
# Edit files in docs/
# Rebuild automatically
```

## Service URLs

When the development environment is running:

- **Development Server**: http://localhost:8000
- **Jupyter Lab**: http://localhost:8888
- **AI Jupyter**: http://localhost:8889 (with `--profile ai`)
- **Documentation**: http://localhost:8080 (with `--profile docs`)
- **Monitoring**: http://localhost:3000 (with `--profile monitoring`)
- **Database**: localhost:5432
- **Redis**: localhost:6379

## Directory Structure

```
openwebuiinstaller/
├── .codex/                 # AI development helpers
│   ├── prompts/           # Reusable AI prompts
│   ├── templates/         # Code templates
│   └── docs/              # AI-generated insights
├── .vscode/               # VS Code configuration
├── docs/                  # Documentation
├── tests/                 # Test suite
├── venv/                  # Python virtual environment
├── setup-codex.sh        # Environment setup script
├── dev.sh                # Development manager
├── docker-compose.dev.yml # Docker development stack
├── Dockerfile.dev        # Main development container
├── Dockerfile.quality    # Code quality container
├── Dockerfile.ai         # AI development container
└── DEV_ENVIRONMENT.md    # This guide
```

## Code Quality

### Automated Checks
- **Pre-commit hooks** run on every commit
- **GitHub Actions** run on push/PR
- **Docker quality container** for isolated checks

### Manual Checks
```bash
# Format code
./dev.sh format

# Run all quality checks
./dev.sh lint

# Run specific checks
docker-compose -f docker-compose.dev.yml run code-quality format
docker-compose -f docker-compose.dev.yml run code-quality security
docker-compose -f docker-compose.dev.yml run code-quality complexity
```

### Quality Tools
- **Black**: Code formatting
- **isort**: Import sorting
- **flake8**: Linting
- **mypy**: Type checking
- **pylint**: Advanced linting
- **bandit**: Security analysis
- **pytest**: Testing with coverage

## AI Development

### Jupyter Notebooks
- Located in `notebooks/`
- Pre-configured with AI libraries
- Access via http://localhost:8889

### AI Libraries Available
- **OpenAI**: GPT models and embeddings
- **Anthropic**: Claude models
- **LangChain**: LLM application framework
- **Transformers**: Hugging Face models
- **Sentence Transformers**: Text embeddings

### Prompts and Templates
- Stored in `.codex/prompts/`
- Use for consistent AI interactions
- Templates for common development tasks

### Environment Variables
Set in `.env.dev` file:
```bash
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
HUGGINGFACE_TOKEN=your_token_here
```

## Testing

### Running Tests
```bash
# All tests with coverage
./dev.sh test

# Specific test file
pytest tests/test_specific.py

# With verbose output
pytest -v

# With coverage report
pytest --cov=openwebui_installer --cov-report=html
```

### Test Structure
```
tests/
├── unit/              # Unit tests
├── integration/       # Integration tests
├── e2e/              # End-to-end tests
└── conftest.py       # Test configuration
```

## Debugging

### Development Shell
```bash
# Open development container shell
./dev.sh shell

# Debug with ipdb
import ipdb; ipdb.set_trace()
```

### Logs
```bash
# All service logs
./dev.sh logs

# Specific service logs
./dev.sh logs dev-environment
./dev.sh logs test-db
```

### VS Code Debugging
- Launch configurations in `.vscode/launch.json`
- Set breakpoints in VS Code
- Use "Python: Current File" configuration

## Environment Variables

### Development (.env.dev)
```bash
COMPOSE_PROJECT_NAME=openwebui-installer-dev
PYTHONPATH=/workspace
DEVELOPMENT=true
DEV_PORT=8000
JUPYTER_PORT=8888
```

### Production
- Use separate `.env.prod` file
- Never commit API keys or secrets
- Use Docker secrets for production

## Troubleshooting

### Common Issues

1. **Docker not running**
   ```bash
   # Check Docker status
   docker info
   # Start Docker Desktop or daemon
   ```

2. **Port conflicts**
   ```bash
   # Check what's using port
   lsof -i :8000
   # Kill process or change port in .env.dev
   ```

3. **Permission errors**
   ```bash
   # Fix Docker permissions (Linux)
   sudo usermod -aG docker $USER
   # Re-login or restart shell
   ```

4. **Virtual environment issues**
   ```bash
   # Recreate virtual environment
   rm -rf venv/
   ./setup-codex.sh --clean
   ```

5. **Pre-commit hook failures**
   ```bash
   # Install hooks
   pre-commit install
   # Run manually
   pre-commit run --all-files
   ```

### Getting Help

1. **Check logs**: `./dev.sh logs`
2. **Check status**: `./dev.sh status`
3. **Reset environment**: `./dev.sh reset`
4. **GitHub Issues**: Report bugs and feature requests
5. **Documentation**: Check `docs/` directory

## Best Practices

### Code Development
1. **Use type hints** for all functions
2. **Write docstrings** for public APIs
3. **Add tests** for new features
4. **Run quality checks** before committing
5. **Use meaningful commit messages**

### AI-Assisted Development
1. **Use provided prompts** for consistency
2. **Review AI suggestions** carefully
3. **Test AI-generated code** thoroughly
4. **Document AI-assisted changes**
5. **Keep prompts updated**

### Docker Development
1. **Use containers** for consistency
2. **Mount volumes** for persistence
3. **Separate concerns** with profiles
4. **Clean up** unused containers/images
5. **Backup important data**

## Performance Tips

### Faster Development
- Use `--profile` flags to start only needed services
- Use `.dockerignore` to exclude unnecessary files
- Cache dependencies in Docker layers
- Use volume mounts for hot reloading

### Resource Management
- Monitor Docker resource usage
- Clean up regularly with `./dev.sh clean`
- Use `docker system prune` for deep cleaning
- Consider resource limits in docker-compose

## Contributing

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/name`
3. **Setup environment**: `./setup-codex.sh --full`
4. **Make changes** and add tests
5. **Run quality checks**: `./dev.sh test && ./dev.sh lint`
6. **Commit changes**: Use conventional commits
7. **Push and create PR**

## Additional Resources

- [Python Style Guide](https://pep8.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [VS Code Python](https://code.visualstudio.com/docs/python/python-tutorial)
- [Jupyter Lab](https://jupyterlab.readthedocs.io/)
- [GitHub Copilot](https://docs.github.com/en/copilot)

---

**Need help?** Run `./dev.sh --help` or `./setup-codex.sh --help` for detailed usage information.