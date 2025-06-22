"""
Core installer functionality for Open WebUI
"""
import json
import os
import platform
import shutil
import subprocess
import sys
from typing import Dict, Optional

import docker
import requests
from rich.console import Console

console = Console()


class InstallerError(Exception):
    """Base exception for installer errors."""
    pass


class SystemRequirementsError(InstallerError):
    """Exception for system requirement validation failures."""
    pass


class Installer:
    """Main installer class for Open WebUI."""

    def __init__(self):
        """Initialize the installer."""
        self.docker_client = docker.from_env()
        self.webui_image = "ghcr.io/open-webui/open-webui:main"  # Default image
        self.config_dir = os.path.expanduser("~/.openwebui")

    def _check_system_requirements(self):
        """Validate system requirements."""
        # Check macOS
        if platform.system() != "Darwin":
            raise SystemRequirementsError("This installer only supports macOS")

        # Check Python version (aligned with setup.py)
        if sys.version_info < (3, 9):
            raise SystemRequirementsError("Python 3.9 or higher is required")

        # Check Docker
        try:
            self.docker_client.ping()
        except Exception:
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

    def install(self, model: str = "llama2", port: int = 3000, force: bool = False, image: Optional[str] = None):
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
                f.write(f"""#!/bin/bash
docker run -d \\
    --name open-webui \\
    -p {port}:8080 \\
    -v open-webui:/app/backend/data \\
    -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434/api \\
    --add-host host.docker.internal:host-gateway \\
    {current_webui_image}
""")
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
                container = self.docker_client.containers.run(
                    current_webui_image,
                    name="open-webui",
                    ports={'8080/tcp': port},
                    volumes={"open-webui": {"bind": "/app/backend/data", "mode": "rw"}},
                    environment={
                        "OLLAMA_API_BASE_URL": "http://host.docker.internal:11434/api"
                    },
                    extra_hosts={"host.docker.internal": "host-gateway"},
                    detach=True,
                    restart_policy={"Name": "unless-stopped"}
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
                status.update({
                    "installed": True,
                    "version": config.get("version"),
                    "port": config.get("port"),
                    "model": config.get("model"),
                })
        except Exception:
            return status

        # Check if running
        try:
            container = self.docker_client.containers.get("open-webui")
            status["running"] = container.status == "running"
        except docker.errors.NotFound:
            pass

        return status
