#!/bin/bash

# dev.sh - Development Environment Management Script
# This script manages the complete development environment for the Open WebUI Installer project

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

log_dev() {
    echo -e "${CYAN}[DEV]${NC} $1"
}

show_banner() {
    echo "================================================"
    echo "🛠️  Open WebUI Installer - Development Manager"
    echo "================================================"
    echo ""
}

show_help() {
    cat << EOF
Development Environment Manager

This script helps you manage the development environment for the Open WebUI Installer project.

Usage: $0 <command> [options]

Commands:
  setup                 Run initial setup (runs setup-codex.sh)
  start                 Start the development environment
  stop                  Stop the development environment
  restart               Restart the development environment
  status                Show status of all services
  logs                  Show logs from development services
  shell                 Open a shell in the development container
  jupyter               Open Jupyter Lab in browser
  test                  Run tests with coverage
  lint                  Run code quality checks
  format                Format code with black and isort
  build                 Build all Docker images
  clean                 Clean up containers and images
  reset                 Reset entire development environment
  ai                    Start AI development environment
  docs                  Generate and serve documentation
  monitor               Start monitoring dashboard
  backup                Backup development data
  restore               Restore development data
  exec                  Execute command in development container

Options:
  -h, --help           Show this help message
  -v, --verbose        Verbose output
  -f, --force          Force operation without confirmation
  -d, --detach         Run services in detached mode
  --profile <name>     Use specific Docker Compose profile

Examples:
  $0 setup             # Initial setup
  $0 start             # Start development environment
  $0 start --profile ai # Start with AI development tools
  $0 test              # Run all tests
  $0 shell             # Open development shell
  $0 jupyter           # Open Jupyter Lab
  $0 clean --force     # Force clean all containers
  $0 exec "python -m pytest"  # Run tests in container
  $0 exec "python -c 'import openwebui_installer'"  # Test imports
EOF
}

check_dependencies() {
    local missing=()

    if ! command -v docker >/dev/null 2>&1; then
        missing+=("docker")
    fi

    if ! command -v docker-compose >/dev/null 2>&1; then
        missing+=("docker-compose")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Please install the missing dependencies and try again"
        exit 1
    fi

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi

    log_success "All dependencies satisfied"
}

setup_environment() {
    log_dev "Setting up development environment..."

    if [[ -f "setup-codex.sh" ]]; then
        log_info "Running Codex setup script..."
        ./setup-codex.sh --full
    else
        log_warning "setup-codex.sh not found, skipping initial setup"
    fi

    # Create necessary directories
    mkdir -p {logs,data,backups,tmp}

    # Create environment file if it doesn't exist
    if [[ ! -f ".env.dev" ]]; then
        cat > .env.dev << 'EOF'
# Development Environment Configuration
COMPOSE_PROJECT_NAME=openwebui-installer-dev
PYTHONPATH=/workspace
PYTHONDONTWRITEBYTECODE=1
PYTHONUNBUFFERED=1
DEVELOPMENT=true

# Ports
DEV_PORT=8000
JUPYTER_PORT=8888
DOCS_PORT=8080
MONITOR_PORT=3000

# Database
POSTGRES_DB=openwebui_test
POSTGRES_USER=testuser
POSTGRES_PASSWORD=testpass

# API Keys (set these with your actual keys)
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
HUGGINGFACE_TOKEN=

# Docker
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
EOF
        log_success "Created .env.dev file"
        log_warning "Please update API keys in .env.dev if you plan to use AI features"
    fi

    log_success "Development environment setup complete"
}

start_services() {
    log_dev "Starting development environment..."

    local compose_files="-f docker-compose.dev.yml"
    local profiles=""

    if [[ -n "$PROFILE" ]]; then
        profiles="--profile $PROFILE"
        log_info "Using profile: $PROFILE"
    fi

    if [[ "$DETACH" == true ]]; then
        docker-compose $compose_files up -d $profiles
    else
        log_info "Starting in foreground mode. Press Ctrl+C to stop."
        docker-compose $compose_files up $profiles
    fi

    if [[ "$DETACH" == true ]]; then
        log_success "Development environment started"
        show_service_urls
    fi
}

stop_services() {
    log_dev "Stopping development environment..."

    docker-compose -f docker-compose.dev.yml down

    log_success "Development environment stopped"
}

restart_services() {
    log_dev "Restarting development environment..."

    stop_services
    start_services
}

show_status() {
    log_dev "Development environment status:"
    echo ""

    docker-compose -f docker-compose.dev.yml ps

    echo ""
    log_info "Service URLs:"
    show_service_urls
}

show_logs() {
    log_dev "Showing development environment logs..."

    if [[ -n "$1" ]]; then
        docker-compose -f docker-compose.dev.yml logs -f "$1"
    else
        docker-compose -f docker-compose.dev.yml logs -f
    fi
}

open_shell() {
    log_dev "Opening development shell..."

    # Check if container is running
    if ! docker ps --format "table {{.Names}}" | grep -q "openwebui-installer-dev"; then
        log_error "Development environment is not running. Start it first with: $0 start"
        exit 1
    fi

    # Check if we have a TTY
    if [ -t 0 ] && [ -t 1 ]; then
        log_success "Opening interactive shell..."
        docker-compose -f docker-compose.dev.yml exec dev-environment bash
    else
        log_warning "No TTY available - running in non-interactive mode"
        log_info "Container is running. To access interactively, use:"
        log_info "  docker exec -it openwebui-installer-dev bash"
        log_info ""
        log_info "Running quick test instead:"
        docker exec openwebui-installer-dev bash -c "
            echo '🚀 Development Container Status:'
            echo '================================'
            echo 'Python version:' \$(python --version)
            echo 'Current directory:' \$(pwd)
            echo 'Available commands: pytest, black, isort, mypy, flake8'
            echo ''
            echo 'To run commands:'
            echo '  docker exec openwebui-installer-dev python -c \"import openwebui_installer; print(\"✅ Ready!\")\"'
        "
    fi
}

open_jupyter() {
    log_dev "Opening Jupyter Lab..."

    local jupyter_url="http://localhost:8888"

    if command -v open >/dev/null 2>&1; then
        open "$jupyter_url"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$jupyter_url"
    else
        log_info "Please open $jupyter_url in your browser"
    fi
}

run_tests() {
    log_dev "Running tests with coverage..."

    if docker-compose -f docker-compose.dev.yml ps dev-environment | grep -q "Up"; then
        docker-compose -f docker-compose.dev.yml exec dev-environment pytest \
            --cov=openwebui_installer \
            --cov-report=term-missing \
            --cov-report=html:htmlcov \
            --cov-report=xml:coverage.xml \
            -v tests/
    else
        log_error "Development environment is not running. Start it first with: $0 start"
        exit 1
    fi
}

run_quality_checks() {
    log_dev "Running code quality checks..."

    if docker-compose -f docker-compose.dev.yml ps code-quality | grep -q "Up"; then
        docker-compose -f docker-compose.dev.yml exec code-quality check-all
    else
        log_info "Starting code quality container..."
        docker-compose -f docker-compose.dev.yml run --rm code-quality check-all
    fi
}

format_code() {
    log_dev "Formatting code..."

    if docker-compose -f docker-compose.dev.yml ps dev-environment | grep -q "Up"; then
        docker-compose -f docker-compose.dev.yml exec dev-environment bash -c "
            black --config pyproject.toml . &&
            isort --settings-path pyproject.toml . &&
            echo 'Code formatting complete!'
        "
    else
        log_info "Starting development container to format code..."
        docker-compose -f docker-compose.dev.yml run --rm dev-environment bash -c "
            black --config pyproject.toml . &&
            isort --settings-path pyproject.toml . &&
            echo 'Code formatting complete!'
        "
    fi
}

build_images() {
    log_dev "Building Docker images..."

    docker-compose -f docker-compose.dev.yml build

    log_success "All images built successfully"
}

clean_environment() {
    log_dev "Cleaning development environment..."

    if [[ "$FORCE" != true ]]; then
        echo -n "This will remove all containers, volumes, and images. Continue? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled"
            return
        fi
    fi

    # Stop and remove containers
    docker-compose -f docker-compose.dev.yml down -v --remove-orphans

    # Remove images
    docker-compose -f docker-compose.dev.yml down --rmi all

    # Clean up dangling images and volumes
    docker system prune -f

    log_success "Development environment cleaned"
}

reset_environment() {
    log_dev "Resetting development environment..."

    if [[ "$FORCE" != true ]]; then
        echo -n "This will completely reset the development environment. Continue? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled"
            return
        fi
    fi

    clean_environment

    # Remove development files
    rm -rf venv/ .pytest_cache/ .coverage htmlcov/ .mypy_cache/
    rm -rf logs/ data/ tmp/

    # Re-setup
    setup_environment

    log_success "Development environment reset complete"
}

start_ai_environment() {
    log_dev "Starting AI development environment..."

    docker-compose -f docker-compose.dev.yml up -d --profile ai

    log_success "AI development environment started"
    log_info "Jupyter Lab available at: http://localhost:8889"
    log_info "Use notebooks in /workspace/notebooks/ for AI experiments"
}

generate_docs() {
    log_dev "Generating documentation..."

    docker-compose -f docker-compose.dev.yml up -d --profile docs

    log_success "Documentation server started"
    log_info "Docs available at: http://localhost:8080"
}

start_monitoring() {
    log_dev "Starting monitoring dashboard..."

    docker-compose -f docker-compose.dev.yml up -d --profile monitoring

    log_success "Monitoring dashboard started"
    log_info "Grafana available at: http://localhost:3000 (admin/admin)"
    log_info "Prometheus available at: http://localhost:9090"
}

backup_data() {
    log_dev "Backing up development data..."

    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup database
    if docker-compose -f docker-compose.dev.yml ps test-db | grep -q "Up"; then
        docker-compose -f docker-compose.dev.yml exec -T test-db \
            pg_dump -U testuser openwebui_test > "$backup_dir/database.sql"
        log_success "Database backed up"
    fi

    # Backup volumes
    docker run --rm \
        -v openwebui-installer-dev_dev-cache:/data \
        -v "$(pwd)/$backup_dir:/backup" \
        alpine tar czf /backup/dev-cache.tar.gz -C /data .

    log_success "Development data backed up to $backup_dir"
}

restore_data() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        log_error "Please specify a valid backup directory"
        log_info "Available backups:"
        ls -la backups/ 2>/dev/null || log_info "No backups found"
        return 1
    fi

    log_dev "Restoring development data from $backup_dir..."

    # Restore database
    if [[ -f "$backup_dir/database.sql" ]]; then
        docker-compose -f docker-compose.dev.yml exec -T test-db \
            psql -U testuser -d openwebui_test < "$backup_dir/database.sql"
        log_success "Database restored"
    fi

    # Restore volumes
    if [[ -f "$backup_dir/dev-cache.tar.gz" ]]; then
        docker run --rm \
            -v openwebui-installer-dev_dev-cache:/data \
            -v "$(pwd)/$backup_dir:/backup" \
            alpine tar xzf /backup/dev-cache.tar.gz -C /data
        log_success "Cache restored"
    fi

    log_success "Development data restored"
}

exec_command() {
    local command="$1"

    if [[ -z "$command" ]]; then
        log_error "Please specify a command to execute"
        log_info "Example: $0 exec \"python --version\""
        log_info "Example: $0 exec \"python -m pytest tests/\""
        return 1
    fi

    log_dev "Executing command in development container: $command"

    # Check if container is running
    if ! docker ps --format "table {{.Names}}" | grep -q "openwebui-installer-dev"; then
        log_error "Development environment is not running. Start it first with: $0 start"
        exit 1
    fi

    # Execute the command
    docker exec openwebui-installer-dev bash -c "cd /workspace && $command"
}

show_service_urls() {
    cat << EOF
🌐 Service URLs:
   Development Server: http://localhost:8000
   Jupyter Lab:       http://localhost:8888
   AI Jupyter:        http://localhost:8889
   Documentation:     http://localhost:8080
   Monitoring:        http://localhost:3000
   Database:          localhost:5432
   Redis:             localhost:6379
EOF
}

# Parse command line arguments
VERBOSE=false
FORCE=false
DETACH=true
PROFILE=""

# Parse options first
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            set -x
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--detach)
            DETACH=true
            shift
            ;;
        --no-detach)
            DETACH=false
            shift
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        -*)
            log_error "Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

COMMAND="$1"
shift || true

# Main execution
show_banner

case $COMMAND in
    setup)
        check_dependencies
        setup_environment
        ;;
    start)
        check_dependencies
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        check_dependencies
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$1"
        ;;
    shell)
        open_shell
        ;;
    jupyter)
        open_jupyter
        ;;
    test)
        run_tests
        ;;
    lint)
        run_quality_checks
        ;;
    format)
        format_code
        ;;
    build)
        check_dependencies
        build_images
        ;;
    clean)
        clean_environment
        ;;
    reset)
        reset_environment
        ;;
    ai)
        check_dependencies
        start_ai_environment
        ;;
    docs)
        check_dependencies
        generate_docs
        ;;
    monitor)
        check_dependencies
        start_monitoring
        ;;
    backup)
        backup_data
        ;;
    restore)
        restore_data "$1"
        ;;
    exec)
        exec_command "$1"
        ;;
    "")
        log_error "No command specified"
        show_help
        exit 1
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac

log_dev "Operation completed successfully! 🚀"
