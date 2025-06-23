"""
Core installer functionality for Open WebUI
"""

import json
import logging
import os
import platform
import shutil
import subprocess
import sys
<<<<<<< HEAD
import shutil
=======
from logging.handlers import RotatingFileHandler
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
from typing import Dict, Optional

import docker
import requests
from rich.console import Console
import logging

logger = logging.getLogger(__name__)
console = Console()
logger = logging.getLogger("openwebui_installer")

# Secrets that can be provided via environment variables or Docker secrets
SECRET_ENV_VARS = [
    "OPENAI_API_KEY",
    "ANTHROPIC_API_KEY",
    "HUGGINGFACE_TOKEN",
    "WEBUI_SECRET_KEY",
]


class InstallerError(Exception):
    """Base exception for installer errors."""

    pass


class SystemRequirementsError(InstallerError):
    """Exception for system requirement validation failures."""

    pass


class Installer:
    """Main installer class for Open WebUI."""

<<<<<<< HEAD
    def __init__(self, runtime: str = "docker"):
        """Initialize the installer.

        Parameters
        ----------
        runtime: str
            Container runtime to use. Either ``docker`` or ``podman``. If
            ``docker`` is selected but unavailable, the installer will attempt
            to fall back to Podman if it is detected.
        """

        self.runtime = runtime
        try:
            self.docker_client = docker.from_env()
        except Exception:
            if runtime == "docker" and self._podman_available():
                self.runtime = "podman"
                self.docker_client = self._get_podman_client()
            else:
                raise

        if runtime == "podman" and self.runtime != "podman":
            # Caller explicitly requested podman but we didn't switch
            self.runtime = "podman"
            self.docker_client = self._get_podman_client()

=======
    def __init__(self, verbose: bool = False):
        """Initialize the installer."""
        self.verbose = verbose
        self.docker_client = docker.from_env()
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
        self.webui_image = "ghcr.io/open-webui/open-webui:main"  # Default image
        self.config_dir = os.path.expanduser("~/.openwebui")
        self._setup_logger()

    def _setup_logger(self) -> None:
        """Configure logging with rotation under the config directory."""
        self.log_dir = os.path.join(self.config_dir, "logs")
        os.makedirs(self.log_dir, exist_ok=True)
        self.log_file = os.path.join(self.log_dir, "openwebui_installer.log")

        if not any(
            isinstance(h, RotatingFileHandler) and h.baseFilename == self.log_file
            for h in logger.handlers
        ):
            handler = RotatingFileHandler(self.log_file, maxBytes=5 * 1024 * 1024, backupCount=3)
            handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
            logger.setLevel(logging.INFO)
            logger.addHandler(handler)

<<<<<<< HEAD
    def _podman_available(self) -> bool:
        """Check if Podman is installed."""
        return shutil.which("podman") is not None

    def _get_podman_client(self) -> docker.DockerClient:
        """Return a DockerClient instance configured for Podman."""
        base_url = os.environ.get("DOCKER_HOST")
        if not base_url:
            uid = os.getuid()
            base_url = f"unix:///run/user/{uid}/podman/podman.sock"
        return docker.DockerClient(base_url=base_url)

    def _load_secret(self, name: str) -> Optional[str]:
        """Retrieve a secret from environment variables or Docker secrets."""
        value = os.getenv(name)
        if value:
            return value
        secret_path = os.path.join("/run/secrets", name)
        if os.path.exists(secret_path):
            try:
                with open(secret_path) as f:
                    return f.read().strip()
            except Exception:
                return None
        return None
=======
    def close(self):
        """Close any resources held by the installer."""
        if hasattr(self.docker_client, "close"):
            try:
                self.docker_client.close()
            except Exception:
                pass

    # ------------------------------------------------------------------
    # Context manager support
    # ------------------------------------------------------------------

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        # Propagate exceptions
        return False

>>>>>>> origin/codex/add-context-manager-and-close-method
    def _check_system_requirements(self):
        """Validate system requirements."""
<<<<<<< HEAD
<<<<<<< HEAD
        # Check supported operating systems (macOS and Linux)
        system = platform.system()
        if system not in ("Darwin", "Linux"):
            raise SystemRequirementsError(
                "This installer only supports macOS and Linux"
            )
=======
        logger.debug("Validating system requirements")
=======
        logger.info("Validating system requirements")
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
        # Check macOS
        if platform.system() != "Darwin":
            raise SystemRequirementsError("This installer only supports macOS")
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli

        # Check Python version (aligned with setup.py)
        if sys.version_info < (3, 9):
            raise SystemRequirementsError("Python 3.9 or higher is required")

<<<<<<< HEAD
        # Check container runtime
        try:
            self.docker_client.ping()
        except Exception:
            if self.runtime == "podman":
                raise SystemRequirementsError("Podman is not running or not installed")
            if self._podman_available():
                raise SystemRequirementsError(
                    "Docker is not running or not installed. Podman detected; use --runtime podman"
                )
            raise SystemRequirementsError("Docker is not running or not installed")
=======
        # Check Docker CLI
        logger.debug("Checking Docker CLI availability")
        if not shutil.which("docker"):
            raise SystemRequirementsError(
                "Docker is not installed. Install Docker with our script or from https://docs.docker.com/get-docker/"
            )

        # Check Docker service
        logger.debug("Checking Docker service status")
        try:
            self.docker_client.ping()
        except docker.errors.DockerException as e:
            raise SystemRequirementsError(
                "Docker service is not running. Start Docker Desktop and ensure the daemon is running."
            ) from e
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli

        # Check Ollama with timeout
        logger.debug("Checking Ollama availability")
        try:
            response = requests.get("http://localhost:11434/api/tags", timeout=10)
            if response.status_code != 200:
                raise SystemRequirementsError("Ollama is not running")
        except requests.exceptions.Timeout:
            raise SystemRequirementsError("Timeout connecting to Ollama - check if it's running")
        except Exception:
            raise SystemRequirementsError("Ollama is not installed or not running")

    def _ensure_config_dir(self):
        """Ensure configuration directory exists."""
        os.makedirs(self.config_dir, exist_ok=True)

<<<<<<< HEAD
<<<<<<< HEAD
=======
    def _pull_webui_image(self, image: str) -> None:
        """Pull the Open WebUI Docker image."""
        console.print(f"Pulling Open WebUI image: {image}...")
        try:
            self.docker_client.images.pull(image)
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to pull Open WebUI Docker image: {str(e)}")

    def _pull_ollama_model(self, model: str) -> None:
        """Pull the specified Ollama model."""
        console.print(f"Pulling Ollama model: {model}...")
        try:
            subprocess.run(["ollama", "pull", model], check=True, timeout=300)
        except subprocess.TimeoutExpired:
            raise InstallerError(f"Timeout while pulling Ollama model {model}")
        except subprocess.CalledProcessError as e:
            raise InstallerError(f"Failed to pull Ollama model {model}: {str(e)}")

    def _create_launch_script(self, port: int, image: str) -> None:
        """Create a script to launch Open WebUI."""
        launch_script = os.path.join(self.config_dir, "launch-openwebui.sh")
        with open(launch_script, "w") as f:
            f.write(
                f"""#!/bin/bash
docker run -d \
    --name open-webui \
    -p {port}:8080 \
    -v open-webui:/app/backend/data \
    -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434/api \
    --add-host host.docker.internal:host-gateway \
    {image}
"""
            )
        os.chmod(launch_script, 0o755)

    def _write_config(self, model: str, port: int, image: str) -> None:
        """Write installer configuration."""
        config = {
            "version": "0.1.0",
            "model": model,
            "port": port,
            "image": image,
        }
        with open(os.path.join(self.config_dir, "config.json"), "w") as f:
            json.dump(config, f, indent=2)

    def _stop_existing_container(self) -> None:
        """Stop and remove any existing Open WebUI container."""
        try:
            existing_container = self.docker_client.containers.get("open-webui")
            existing_container.stop()
            existing_container.remove()
        except docker.errors.NotFound:
            pass
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to stop existing container: {str(e)}")

    def _start_container(self, port: int, image: str) -> None:
        """Start the Open WebUI container."""
        try:
            container = self.docker_client.containers.run(
                image,
                name="open-webui",
                ports={"8080/tcp": port},
                volumes={"open-webui": {"bind": "/app/backend/data", "mode": "rw"}},
                environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
                extra_hosts={"host.docker.internal": "host-gateway"},
                detach=True,
                restart_policy={"Name": "unless-stopped"},
            )
            console.print(f"✓ Container started with ID: {container.short_id}")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")

>>>>>>> origin/codex/add-private-helper-functions-in-installer.py
=======
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
    def install(
        self,
        model: str = "llama2",
        port: int = 3000,
        force: bool = False,
        image: Optional[str] = None,
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    ) -> None:
=======
    ):
>>>>>>> origin/codex/extend-installer-with-container-management-commands
=======
    ):
>>>>>>> origin/codex/extend-installer-with-container-management-methods
=======
    ):
>>>>>>> origin/codex/add-cli-methods-and-update-tests
=======
    ):
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
=======
    ):
>>>>>>> origin/codex/implement-macos-autostart-feature
=======
    ):
>>>>>>> origin/codex/add-private-helper-functions-in-installer.py
        """Install Open WebUI."""
        try:
            logger.debug("Starting installation")
=======
    ):
        """Install Open WebUI."""
        try:
            logger.info("Starting installation")
            self._setup_logger()
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
            # Check if already installed
            if not force and self.get_status()["installed"]:
                logger.warning("Installation aborted: already installed")
                raise InstallerError("Open WebUI is already installed. Use --force to reinstall.")

            # Validate system
            self._check_system_requirements()

            # Create config directory
            self._ensure_config_dir()

            # Use custom image if provided, otherwise use default
            current_webui_image = image if image else self.webui_image

<<<<<<< HEAD
            # Pull Docker image
            console.print(f"Pulling Open WebUI image: {current_webui_image}...")
            logger.info("Pulling Docker image %s", current_webui_image)
            try:
                self.docker_client.images.pull(current_webui_image)
            except docker.errors.APIError as e:
                raise InstallerError(f"Failed to pull Open WebUI Docker image: {str(e)}")

            # Pull Ollama model
            console.print(f"Pulling Ollama model: {model}...")
            logger.info("Pulling Ollama model %s", model)
            try:
                subprocess.run(["ollama", "pull", model], check=True, timeout=300)
            except subprocess.TimeoutExpired:
                raise InstallerError(f"Timeout while pulling Ollama model {model}")
            except subprocess.CalledProcessError as e:
                raise InstallerError(f"Failed to pull Ollama model {model}: {str(e)}")

            # Create launch script
            launch_script = os.path.join(self.config_dir, "launch-openwebui.sh")
            with open(launch_script, "w") as f:
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
                f.write(f"""#!/bin/bash
{self.runtime} run -d \\
=======
=======
>>>>>>> origin/codex/extend-installer-with-container-management-methods
=======
>>>>>>> origin/codex/add-cli-methods-and-update-tests
=======
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
=======
>>>>>>> origin/codex/implement-macos-autostart-feature
=======
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
                f.write(
                    f"""#!/bin/bash
docker run -d \\
>>>>>>> origin/codex/extend-installer-with-container-management-commands
    --name open-webui \\
    -p {port}:8080 \\
    -v open-webui:/app/backend/data \\
    -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434/api \\
    --add-host host.docker.internal:host-gateway \\
    {current_webui_image}
"""
                )
            os.chmod(launch_script, 0o755)
=======
            # Pull resources and configure installation
            self._pull_webui_image(current_webui_image)
            self._pull_ollama_model(model)
            self._create_launch_script(port, current_webui_image)
>>>>>>> origin/codex/add-private-helper-functions-in-installer.py

            # Create configuration file
            self._write_config(model, port, current_webui_image)

            # Start the container after installation
            console.print("Starting Open WebUI container...")
<<<<<<< HEAD
<<<<<<< HEAD
=======
            logger.info("Starting Open WebUI container")
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
            try:
                # Stop and remove existing container if it exists
                try:
                    existing_container = self.docker_client.containers.get("open-webui")
                    existing_container.stop()
                    existing_container.remove()
                except docker.errors.NotFound:
                    pass

                # Start new container
                env_vars = {
                    "OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"
                }
                for secret in SECRET_ENV_VARS:
                    value = self._load_secret(secret)
                    if value:
                        env_vars[secret] = value

                container = self.docker_client.containers.run(
                    current_webui_image,
                    name="open-webui",
                    ports={"8080/tcp": port},
                    volumes={"open-webui": {"bind": "/app/backend/data", "mode": "rw"}},
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
                    environment=env_vars,
=======
                    environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
>>>>>>> origin/codex/extend-installer-with-container-management-commands
=======
                    environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
>>>>>>> origin/codex/extend-installer-with-container-management-methods
=======
                    environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
>>>>>>> origin/codex/add-cli-methods-and-update-tests
=======
                    environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
=======
                    environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
>>>>>>> origin/codex/implement-macos-autostart-feature
=======
                    environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
                    extra_hosts={"host.docker.internal": "host-gateway"},
                    detach=True,
                    restart_policy={"Name": "unless-stopped"},
                )
                console.print(f"✓ Container started with ID: {container.short_id}")
                logger.info("Container started with ID %s", container.short_id)

            except docker.errors.APIError as e:
                raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")
=======
            self._stop_existing_container()
            self._start_container(port, current_webui_image)
>>>>>>> origin/codex/add-private-helper-functions-in-installer.py

        except Exception as e:
            logger.error("Installation failed: %s", str(e))
            raise InstallerError(f"Installation failed: {str(e)}")
        else:
            logger.info("Installation complete")

    def uninstall(self):
        """Uninstall Open WebUI."""
        try:
<<<<<<< HEAD
            logger.debug("Starting uninstallation")
=======
            logger.info("Starting uninstallation")
            self._setup_logger()
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
            # Stop and remove container if running
            try:
                container = self.docker_client.containers.get("open-webui")
                container.stop()
                container.remove()
            except docker.errors.NotFound:
                pass

            # Remove configuration
<<<<<<< HEAD
=======
            import shutil

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> origin/codex/extend-installer-with-container-management-commands
=======
>>>>>>> origin/codex/extend-installer-with-container-management-methods
=======
>>>>>>> origin/codex/add-cli-methods-and-update-tests
=======
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
=======
>>>>>>> origin/codex/implement-macos-autostart-feature
=======
>>>>>>> origin/codex/add-private-helper-functions-in-installer.py
=======
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
            if os.path.exists(self.config_dir):
                shutil.rmtree(self.config_dir)

            # Remove Docker volume
            try:
                volume = self.docker_client.volumes.get("open-webui")
                volume.remove()
            except docker.errors.NotFound:
                pass

        except Exception as e:
            logger.error("Uninstallation failed: %s", str(e))
            raise InstallerError(f"Uninstallation failed: {str(e)}")
        else:
            logger.info("Uninstallation complete")

    def get_status(self) -> Dict:
        """Get installation status."""
        self._setup_logger()
        logger.info("Checking installation status")
        status = {
            "installed": False,
            "version": None,
            "port": None,
            "model": None,
            "image": None,
            "running": False,
        }

        # Check config directory
        config_file = os.path.join(self.config_dir, "config.json")
        if not os.path.exists(config_file):
            return status

        # Read configuration
        try:
            with open(config_file) as f:
                config = json.load(f)
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
                status.update(
                    {
                        "installed": True,
                        "version": config.get("version"),
                        "port": config.get("port"),
                        "model": config.get("model"),
                    }
                )
<<<<<<< HEAD
=======
                status.update({
                    "installed": True,
                    "version": config.get("version"),
                    "port": config.get("port"),
                    "model": config.get("model"),
                    "image": config.get("image"),
                })
>>>>>>> origin/codex/replace-placeholder-commands-in-install.py
=======
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
        except Exception:
            return status

        # Check if running
        try:
            container = self.docker_client.containers.get("open-webui")
            status["running"] = container.status == "running"
        except docker.errors.NotFound:
            pass

        logger.info("Status retrieved: %s", status)
        return status

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    def start(self):
<<<<<<< HEAD
        """Start the Open WebUI container."""
        try:
            self._check_system_requirements()

            config_path = os.path.join(self.config_dir, "config.json")
            if not os.path.exists(config_path):
                raise InstallerError("Open WebUI is not installed")

            with open(config_path) as f:
                config = json.load(f)

            image = config.get("image", self.webui_image)
            port = config.get("port", 3000)

            try:
                container = self.docker_client.containers.get("open-webui")
                container.start()
            except docker.errors.NotFound:
=======
        """Start the Open WebUI container using stored configuration."""
        status = self.get_status()
        if not status["installed"]:
            raise InstallerError("Open WebUI is not installed. Run 'install' first.")

        port = status["port"]
        image = status.get("image", self.webui_image)
=======
    def _load_config(self) -> Dict:
        """Load configuration from disk."""
        config_file = os.path.join(self.config_dir, "config.json")
        with open(config_file) as f:
            return json.load(f)

    def start(self):
        """Start the Open WebUI Docker container."""
        if not self.get_status()["installed"]:
            raise InstallerError("Open WebUI is not installed")

        config = self._load_config()
        image = config.get("image", self.webui_image)
        port = config.get("port", 3000)
>>>>>>> origin/codex/extend-installer-with-container-management-methods

        try:
            container = self.docker_client.containers.get("open-webui")
            if container.status != "running":
                container.start()
<<<<<<< HEAD
                console.print(f"✓ Container started with ID: {container.short_id}")
        except docker.errors.NotFound:
            try:
>>>>>>> origin/codex/extend-installer-with-container-management-commands
                container = self.docker_client.containers.run(
=======
    def start(self):
        """Start Open WebUI container."""
        try:
            container = self.docker_client.containers.get("open-webui")
            container.start()
        except docker.errors.NotFound:
            config_file = os.path.join(self.config_dir, "config.json")
            if not os.path.exists(config_file):
                raise InstallerError("Open WebUI is not installed")
            with open(config_file) as f:
                config = json.load(f)
            image = config.get("image", self.webui_image)
            port = config.get("port", 3000)
            try:
                self.docker_client.containers.run(
>>>>>>> origin/codex/add-cli-methods-and-update-tests
                    image,
                    name="open-webui",
                    ports={"8080/tcp": port},
=======
    def start_container(self, port: Optional[int] = None):
        """Start the Open WebUI container if it's not already running."""
        try:
            status = self.get_status()

            if not status["installed"]:
                raise InstallerError("Open WebUI is not installed")

            port_to_use = port if port is not None else status.get("port", 3000)
            image = status.get("image", self.webui_image)

            try:
                container = self.docker_client.containers.get("open-webui")
                if container.status == "running":
                    return  # Already running
                container.start()
            except docker.errors.NotFound:
                self.docker_client.containers.run(
                    image,
                    name="open-webui",
                    ports={"8080/tcp": port_to_use},
>>>>>>> origin/codex/implement-start,-stop,-and-update-commands
                    volumes={"open-webui": {"bind": "/app/backend/data", "mode": "rw"}},
                    environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
                    extra_hosts={"host.docker.internal": "host-gateway"},
                    detach=True,
                    restart_policy={"Name": "unless-stopped"},
                )
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
            return container
        except Exception as e:
            raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")

    def stop(self):
        """Stop the Open WebUI container if it is running."""
        try:
            try:
                container = self.docker_client.containers.get("open-webui")
                container.stop()
            except docker.errors.NotFound:
                return
        except Exception as e:
=======
                console.print(f"✓ Container started with ID: {container.short_id}")
            except docker.errors.APIError as e:
                raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")
=======
        except docker.errors.NotFound:
            self.docker_client.containers.run(
                image,
                name="open-webui",
                ports={"8080/tcp": port},
=======
            except docker.errors.APIError as e:
                raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")

    def stop(self):
        """Stop Open WebUI container."""
=======
    def start(self):
        """Start the Open WebUI container."""
        try:
            container = self.docker_client.containers.get("open-webui")
            container.start()
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI is not installed")
        except Exception as e:
            raise InstallerError(f"Failed to start Open WebUI: {str(e)}")

    def stop(self):
        """Stop the Open WebUI container."""
>>>>>>> origin/codex/replace-placeholder-commands-in-install.py
=======
    def start(self):
        """Start the Open WebUI container."""
        status = self.get_status()
        if not status["installed"]:
            raise InstallerError("Open WebUI is not installed")

        try:
            container = self.docker_client.containers.get("open-webui")
            container.start()
            return
        except docker.errors.NotFound:
            pass

        # Container does not exist, recreate it using stored config
        config_file = os.path.join(self.config_dir, "config.json")
        with open(config_file) as f:
            config = json.load(f)

        image = config.get("image", self.webui_image)
        port = config.get("port", 3000)

        self.docker_client.containers.run(
            image,
            name="open-webui",
            ports={"8080/tcp": port},
            volumes={"open-webui": {"bind": "/app/backend/data", "mode": "rw"}},
            environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
            extra_hosts={"host.docker.internal": "host-gateway"},
            detach=True,
            restart_policy={"Name": "unless-stopped"},
        )

    def stop(self):
        """Stop the Open WebUI container."""
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer
        try:
            container = self.docker_client.containers.get("open-webui")
            container.stop()
        except docker.errors.NotFound:
<<<<<<< HEAD
<<<<<<< HEAD
            raise InstallerError("Open WebUI container is not running")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to stop Open WebUI container: {str(e)}")

    def restart(self):
        """Restart Open WebUI container."""
        try:
            container = self.docker_client.containers.get("open-webui")
            container.restart()
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container is not running")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to restart Open WebUI container: {str(e)}")

    def update(self, image: Optional[str] = None):
        """Update Open WebUI Docker image and restart the container."""
=======
            raise InstallerError("Open WebUI is not installed or not running")
        except Exception as e:
            raise InstallerError(f"Failed to stop Open WebUI: {str(e)}")

    def update(self, image: Optional[str] = None):
        """Update Open WebUI by reinstalling with the latest image."""
>>>>>>> origin/codex/replace-placeholder-commands-in-install.py
        try:
            status = self.get_status()
            if not status["installed"]:
                raise InstallerError("Open WebUI is not installed")

<<<<<<< HEAD
            new_image = image if image else self.webui_image
            self.docker_client.images.pull(new_image)

            config_file = os.path.join(self.config_dir, "config.json")
            with open(config_file) as f:
                config = json.load(f)
            config["image"] = new_image
            with open(config_file, "w") as f:
                json.dump(config, f, indent=2)

            try:
                container = self.docker_client.containers.get("open-webui")
                container.stop()
                container.remove()
            except docker.errors.NotFound:
                pass

            self.docker_client.containers.run(
                new_image,
                name="open-webui",
                ports={"8080/tcp": config.get("port", 3000)},
>>>>>>> origin/codex/add-cli-methods-and-update-tests
                volumes={"open-webui": {"bind": "/app/backend/data", "mode": "rw"}},
                environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
                extra_hosts={"host.docker.internal": "host-gateway"},
                detach=True,
                restart_policy={"Name": "unless-stopped"},
            )
<<<<<<< HEAD
>>>>>>> origin/codex/extend-installer-with-container-management-methods
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")

    def stop(self):
<<<<<<< HEAD
        """Stop the Open WebUI container."""
=======
        """Stop the Open WebUI Docker container."""
>>>>>>> origin/codex/extend-installer-with-container-management-methods
        try:
            container = self.docker_client.containers.get("open-webui")
            container.stop()
        except docker.errors.NotFound:
<<<<<<< HEAD
            raise InstallerError("Open WebUI container not found.")
        except docker.errors.APIError as e:
>>>>>>> origin/codex/extend-installer-with-container-management-commands
            raise InstallerError(f"Failed to stop Open WebUI container: {str(e)}")
=======
            raise InstallerError("Open WebUI is not running")
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer

    def restart(self):
        """Restart the Open WebUI container."""
        try:
<<<<<<< HEAD
<<<<<<< HEAD
            self.stop()
            self.start()
        except Exception as e:
            raise InstallerError(f"Failed to restart Open WebUI container: {str(e)}")
=======
            container = self.docker_client.containers.get("open-webui")
            container.restart()
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container not found.")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to restart Open WebUI container: {str(e)}")

    def update(self, image: Optional[str] = None):
        """Pull the latest Docker image and restart the container."""
        status = self.get_status()
        if not status["installed"]:
            raise InstallerError("Open WebUI is not installed.")

        image_to_use = image if image else status.get("image", self.webui_image)

        try:
            console.print(f"Pulling Open WebUI image: {image_to_use}...")
            self.docker_client.images.pull(image_to_use)

            if image and image != status.get("image"):
                config_file = os.path.join(self.config_dir, "config.json")
                with open(config_file) as f:
                    config = json.load(f)
                config["image"] = image
                with open(config_file, "w") as f:
                    json.dump(config, f, indent=2)

            self.restart()
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to update Open WebUI Docker image: {str(e)}")

    def logs(self, tail: int = 100) -> str:
        """Return logs from the Open WebUI container."""
=======
            raise InstallerError("Open WebUI container is not running")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to stop Open WebUI container: {str(e)}")

    def restart(self):
        """Restart the Open WebUI Docker container."""
        try:
            container = self.docker_client.containers.get("open-webui")
            container.restart()
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container is not running")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to restart Open WebUI container: {str(e)}")

    def update(self):
        """Update the Open WebUI Docker image and restart the container."""
        if not self.get_status()["installed"]:
            raise InstallerError("Open WebUI is not installed")

        config = self._load_config()
        image = config.get("image", self.webui_image)

        try:
            self.docker_client.images.pull(image)
            self.restart()
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to update Open WebUI container: {str(e)}")

    def logs(self, tail: int = 100) -> str:
        """Retrieve logs from the Open WebUI Docker container."""
>>>>>>> origin/codex/extend-installer-with-container-management-methods
        try:
            container = self.docker_client.containers.get("open-webui")
            return container.logs(tail=tail).decode()
        except docker.errors.NotFound:
<<<<<<< HEAD
            raise InstallerError("Open WebUI container not found.")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to get logs: {str(e)}")
>>>>>>> origin/codex/extend-installer-with-container-management-commands
=======
            raise InstallerError("Open WebUI container not found")

    def enable_autostart(self) -> str:
        """Enable autostart on macOS using launchd."""
        if platform.system() != "Darwin":
            raise InstallerError("Autostart is only supported on macOS")

        plist_dir = os.path.expanduser("~/Library/LaunchAgents")
        os.makedirs(plist_dir, exist_ok=True)
        plist_path = os.path.join(plist_dir, "com.openwebui.autostart.plist")
        launch_script = os.path.join(self.config_dir, "launch-openwebui.sh")
        plist_content = f"""<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>com.openwebui</string>
=======
    def enable_autostart(self):
        """Configure macOS to launch Open WebUI at login."""
        if platform.system() != "Darwin":
            raise InstallerError("Autostart is only supported on macOS")

        launch_script = os.path.join(self.config_dir, "launch-openwebui.sh")
        if not os.path.exists(launch_script):
            raise InstallerError(
                "Launch script not found. Please run 'openwebui-installer install' first."
            )

        plist_dir = os.path.expanduser("~/Library/LaunchAgents")
        os.makedirs(plist_dir, exist_ok=True)
        plist_path = os.path.join(plist_dir, "com.openwebui.openwebui.plist")

        plist_contents = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openwebui.openwebui</string>
>>>>>>> origin/codex/implement-macos-autostart-feature
    <key>ProgramArguments</key>
    <array>
        <string>{launch_script}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
<<<<<<< HEAD
</dict>
</plist>
"""
        with open(plist_path, "w") as f:
            f.write(plist_content)
        try:
            subprocess.run(["launchctl", "load", "-w", plist_path], check=True)
        except subprocess.CalledProcessError as e:
            raise InstallerError(f"Failed to enable autostart: {str(e)}")
        return plist_path
>>>>>>> origin/codex/extend-installer-with-container-management-methods
=======
        except Exception as e:
            raise InstallerError(f"Update failed: {str(e)}")

    def logs(self, tail: int = 100) -> str:
        """Return logs from the Open WebUI container."""
        try:
            container = self.docker_client.containers.get("open-webui")
            output = container.logs(tail=tail)
            return output.decode("utf-8") if isinstance(output, bytes) else str(output)
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container not found")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to fetch logs: {str(e)}")
>>>>>>> origin/codex/add-cli-methods-and-update-tests
=======
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>{os.path.join(self.config_dir, 'openwebui.log')}</string>
    <key>StandardErrorPath</key>
    <string>{os.path.join(self.config_dir, 'openwebui.err')}</string>
</dict>
</plist>
"""

        with open(plist_path, "w") as plist_file:
            plist_file.write(plist_contents)

        subprocess.run(["launchctl", "load", "-w", plist_path], check=True)
>>>>>>> origin/codex/implement-macos-autostart-feature
=======
            current_image = image if image else status.get("image", self.webui_image)
            self.install(
                model=status.get("model", "llama2"),
                port=status.get("port", 3000),
                force=True,
                image=current_image,
            )
        except Exception as e:
            raise InstallerError(f"Update failed: {str(e)}")
>>>>>>> origin/codex/replace-placeholder-commands-in-install.py
=======
        except Exception as e:
            raise InstallerError(f"Failed to start container: {str(e)}")

    def stop_container(self, remove: bool = False):
        """Stop the Open WebUI container and optionally remove it."""
        try:
            try:
                container = self.docker_client.containers.get("open-webui")
                if container.status == "running":
                    container.stop()
                if remove:
                    container.remove()
            except docker.errors.NotFound:
                if remove:
                    # Ensure removed container is not lingering
                    try:
                        container = self.docker_client.containers.get("open-webui")
                        container.remove()
                    except docker.errors.NotFound:
                        pass
        except Exception as e:
            raise InstallerError(f"Failed to stop container: {str(e)}")

    def update(self, image: Optional[str] = None):
        """Pull the latest image and restart the container."""
        try:
            new_image = image if image else self.webui_image
            self.docker_client.images.pull(new_image)
            self.stop_container()
            self.start_container()
        except Exception as e:
            raise InstallerError(f"Update failed: {str(e)}")
>>>>>>> origin/codex/implement-start,-stop,-and-update-commands
=======
            container = self.docker_client.containers.get("open-webui")
            container.restart()
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI is not running")
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer
