# 🚀 Getting Started - Open WebUI Installer Development

Welcome to the Open WebUI Installer development environment! This guide will help you get up and running quickly.

## 📋 Prerequisites

Before you begin, make sure you have:

- ✅ **Docker Desktop** installed and running
- ✅ **Git** for version control
- ✅ **Terminal/Command Line** access
- ✅ At least **4GB RAM** and **5GB disk space** available

## 🏁 Quick Start (5 minutes)

### 1. Clone the Repository
```bash
git clone https://github.com/STEALTHTEMP1/openwebui-installer.git
cd openwebuiinstaller
```

### 2. Start Development Environment
```bash
./dev.sh start
```

This will:
- 🏗️ Build the development Docker containers
- 🚀 Start all services (database, Redis, development environment)
- ✅ Set up the complete development stack

### 3. Verify Everything Works
```bash
# Check status
./dev.sh status

# Test Python imports
./dev.sh exec "python -c 'import openwebui_installer; print(\"✅ Ready!\")'"

# Run tests
./dev.sh exec "python -m pytest tests/ -v"
```

## 🛠️ Development Workflow

### Common Commands

```bash
# Environment Management
./dev.sh start          # Start all services
./dev.sh stop           # Stop all services  
./dev.sh restart        # Restart everything
./dev.sh status         # Check what's running

# Development Tools
./dev.sh shell          # Access container (shows status if no TTY)
./dev.sh exec "cmd"     # Run command in container
./dev.sh test           # Run full test suite
./dev.sh lint           # Run code quality checks
./dev.sh format         # Format code with Black/isort

# Container Management
./dev.sh build          # Rebuild containers
./dev.sh clean          # Clean up containers/images
./dev.sh logs           # View service logs
```

### Running Commands in Container

Since the development environment is containerized, you'll run most commands using `./dev.sh exec`:

```bash
# Python development
./dev.sh exec "python --version"
./dev.sh exec "pip list"
./dev.sh exec "python -m pytest tests/"

# Code quality
./dev.sh exec "black --check ."
./dev.sh exec "isort --check-only ."
./dev.sh exec "flake8 ."
./dev.sh exec "mypy ."

# Interactive Python
./dev.sh exec "python -i"
```

## 📁 Project Structure

```
openwebuiinstaller/
├── 🐳 Docker Development Environment
│   ├── Dockerfile.dev              # Main development container
│   ├── Dockerfile.quality          # Code quality tools
│   ├── Dockerfile.ai               # AI development tools
│   ├── docker-compose.dev.yml      # Service orchestration
│   └── requirements-container.txt  # Container-safe dependencies
│
├── 🛠️ Development Tools
│   ├── dev.sh                      # Development environment manager
│   ├── setup-codex.sh             # Environment setup script
│   └── .env.dev                   # Development configuration
│
├── 📦 Core Application
│   ├── openwebui_installer/        # Main Python package
│   ├── install.py                  # Installation script
│   ├── requirements.txt            # Production dependencies
│   └── setup.py                   # Package setup
│
├── 🧪 Testing & Quality
│   ├── tests/                      # Test suite
│   ├── requirements-dev.txt        # Development dependencies
│   └── pyproject.toml             # Tool configuration
│
├── 📚 Documentation
│   ├── README.md                   # Project overview
│   ├── GETTING_STARTED.md         # This file
│   ├── DEV_ENVIRONMENT.md         # Detailed dev setup
│   └── QA_REVIEW_SUMMARY.md       # Quality assessment
│
└── ⚙️ Configuration
    ├── .vscode/                    # VS Code settings
    ├── .codex/                     # Development metadata
    ├── .github/workflows/          # CI/CD pipelines
    └── .dockerignore              # Docker build optimization
```

## 🌐 Service URLs

When the development environment is running, these services are available:

| Service | URL | Purpose |
|---------|-----|---------|
| **Development Server** | http://localhost:8000 | Main application |
| **Jupyter Lab** | http://localhost:8888 | Interactive development |
| **Database** | localhost:5432 | PostgreSQL (testuser/testpass) |
| **Redis** | localhost:6379 | Caching and sessions |
| **Documentation** | http://localhost:8080 | Generated docs (when enabled) |
| **Monitoring** | http://localhost:3000 | Development dashboard (when enabled) |

## 💡 Pro Tips

### 1. **Use Aliases for Faster Development**
Add to your shell profile (`~/.bashrc`, `~/.zshrc`):
```bash
alias dev="./dev.sh"
alias devx="./dev.sh exec"
alias devtest="./dev.sh exec 'python -m pytest tests/ -v'"
alias devlint="./dev.sh exec 'black . && isort . && flake8 .'"
```

Then use:
```bash
dev start
devx "python --version"
devtest
devlint
```

### 2. **VS Code Integration**
The repository includes VS Code settings for:
- ✅ Python development with proper linting
- ✅ Docker container integration
- ✅ Recommended extensions
- ✅ Debugging configuration

Open the project in VS Code:
```bash
code .
```

### 3. **Watch Mode for Tests**
```bash
./dev.sh exec "python -m pytest tests/ --looponfail"
```

### 4. **Code Quality Automation**
```bash
# Format and check code in one command
./dev.sh exec "black . && isort . && flake8 . && mypy ."
```

## 🔧 Troubleshooting

### Common Issues

#### 🐳 **Docker Issues**
```bash
# Docker not running
# Solution: Start Docker Desktop

# Port conflicts
./dev.sh clean --force
./dev.sh start

# Permission issues
sudo chown -R $USER:$USER .
```

#### 🐍 **Python Import Errors**
```bash
# Check if container is running
./dev.sh status

# Rebuild if necessary
./dev.sh clean
./dev.sh build
./dev.sh start

# Test imports
./dev.sh exec "python -c 'import openwebui_installer'"
```

#### 🚫 **Shell Access Issues**
The `./dev.sh shell` command works differently in different environments:
- **With TTY**: Opens interactive bash shell
- **Without TTY**: Shows container status and usage instructions

Use `./dev.sh exec "bash"` for commands or direct Docker access:
```bash
docker exec -it openwebui-installer-dev bash
```

#### ⚠️ **API Key Warnings**
Add your API keys to `.env.dev`:
```bash
# Edit .env.dev
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
```

### Getting Help

1. **Check logs**: `./dev.sh logs`
2. **Check status**: `./dev.sh status`
3. **Clean restart**: `./dev.sh clean && ./dev.sh start`
4. **View documentation**: `cat README.md`, `cat DEV_ENVIRONMENT.md`

## 🎯 Next Steps

1. **Explore the codebase**:
   ```bash
   ./dev.sh exec "find . -name '*.py' | head -10"
   ./dev.sh exec "ls -la openwebui_installer/"
   ```

2. **Run the full test suite**:
   ```bash
   ./dev.sh test
   ```

3. **Make your first change**:
   - Edit a file
   - Run tests: `./dev.sh exec "python -m pytest tests/"`
   - Format code: `./dev.sh format`
   - Check quality: `./dev.sh lint`

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: your change description"
   ```

## 📚 Additional Resources

- **[README.md](README.md)** - Project overview and installation methods
- **[DEV_ENVIRONMENT.md](DEV_ENVIRONMENT.md)** - Detailed development setup
- **[QA_REVIEW_SUMMARY.md](QA_REVIEW_SUMMARY.md)** - Quality assessment and architecture
- **[GitHub Issues](https://github.com/STEALTHTEMP1/openwebui-installer/issues)** - Bug reports and feature requests

## 🆘 Need Help?

- **Documentation**: Check the docs in this repository
- **Issues**: Create a GitHub issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions

---

**Happy coding! 🚀** 

The development environment is designed to be robust and easy to use. If you encounter any issues, the troubleshooting section above should help, or feel free to create an issue in the repository.