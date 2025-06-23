"""
Core installer functionality for Open WebUI
"""

import json
import os
import platform
import shutil
import subprocess
import sys
import shutil
from typing import Dict, Optional

import docker
import requests
from rich.console import Console

console = Console()

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

        self.webui_image = "ghcr.io/open-webui/open-webui:main"  # Default image
        self.config_dir = os.path.expanduser("~/.openwebui")

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
    def _check_system_requirements(self):
        """Validate system requirements."""
        # Check supported operating systems (macOS and Linux)
        system = platform.system()
        if system not in ("Darwin", "Linux"):
            raise SystemRequirementsError(
                "This installer only supports macOS and Linux"
            )

        # Check Python version (aligned with setup.py)
        if sys.version_info < (3, 9):
            raise SystemRequirementsError("Python 3.9 or higher is required")

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

        # Check Ollama with timeout
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

    def install(
        self,
        model: str = "llama2",
        port: int = 3000,
        force: bool = False,
        image: Optional[str] = None,
<<<<<<< HEAD
    ) -> None:
=======
    ):
>>>>>>> origin/codex/extend-installer-with-container-management-commands
        """Install Open WebUI."""
        try:
            # Check if already installed
            if not force and self.get_status()["installed"]:
                raise InstallerError("Open WebUI is already installed. Use --force to reinstall.")

            # Validate system
            self._check_system_requirements()

            # Create config directory
            self._ensure_config_dir()

            # Use custom image if provided, otherwise use default
            current_webui_image = image if image else self.webui_image

            # Pull Docker image
            console.print(f"Pulling Open WebUI image: {current_webui_image}...")
            try:
                self.docker_client.images.pull(current_webui_image)
            except docker.errors.APIError as e:
                raise InstallerError(f"Failed to pull Open WebUI Docker image: {str(e)}")

            # Pull Ollama model
            console.print(f"Pulling Ollama model: {model}...")
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
                f.write(f"""#!/bin/bash
{self.runtime} run -d \\
=======
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

            # Create configuration file
            config = {
                "version": "0.1.0",
                "model": model,
                "port": port,
                "image": current_webui_image,
            }
            with open(os.path.join(self.config_dir, "config.json"), "w") as f:
                json.dump(config, f, indent=2)

            # Start the container after installation
            console.print("Starting Open WebUI container...")
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
                    environment=env_vars,
=======
                    environment={"OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"},
>>>>>>> origin/codex/extend-installer-with-container-management-commands
                    extra_hosts={"host.docker.internal": "host-gateway"},
                    detach=True,
                    restart_policy={"Name": "unless-stopped"},
                )
                console.print(f"✓ Container started with ID: {container.short_id}")

            except docker.errors.APIError as e:
                raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")

        except Exception as e:
            raise InstallerError(f"Installation failed: {str(e)}")

    def uninstall(self):
        """Uninstall Open WebUI."""
        try:
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

>>>>>>> origin/codex/extend-installer-with-container-management-commands
            if os.path.exists(self.config_dir):
                shutil.rmtree(self.config_dir)

            # Remove Docker volume
            try:
                volume = self.docker_client.volumes.get("open-webui")
                volume.remove()
            except docker.errors.NotFound:
                pass

        except Exception as e:
            raise InstallerError(f"Uninstallation failed: {str(e)}")

    def get_status(self) -> Dict:
        """Get installation status."""
        status = {
            "installed": False,
            "version": None,
            "port": None,
            "model": None,
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
                status.update(
                    {
                        "installed": True,
                        "version": config.get("version"),
                        "port": config.get("port"),
                        "model": config.get("model"),
                    }
                )
        except Exception:
            return status

        # Check if running
        try:
            container = self.docker_client.containers.get("open-webui")
            status["running"] = container.status == "running"
        except docker.errors.NotFound:
            pass

        return status

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

        try:
            container = self.docker_client.containers.get("open-webui")
            if container.status != "running":
                container.start()
                console.print(f"✓ Container started with ID: {container.short_id}")
        except docker.errors.NotFound:
            try:
>>>>>>> origin/codex/extend-installer-with-container-management-commands
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
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")

    def stop(self):
        """Stop the Open WebUI container."""
        try:
            container = self.docker_client.containers.get("open-webui")
            container.stop()
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container not found.")
        except docker.errors.APIError as e:
>>>>>>> origin/codex/extend-installer-with-container-management-commands
            raise InstallerError(f"Failed to stop Open WebUI container: {str(e)}")

    def restart(self):
        """Restart the Open WebUI container."""
        try:
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
        try:
            container = self.docker_client.containers.get("open-webui")
            return container.logs(tail=tail).decode()
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container not found.")
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to get logs: {str(e)}")
>>>>>>> origin/codex/extend-installer-with-container-management-commands
