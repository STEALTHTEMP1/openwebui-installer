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
from logging.handlers import RotatingFileHandler
from typing import Dict, Optional

from dotenv import load_dotenv
import docker
import requests
from rich.console import Console

logger = logging.getLogger(__name__)
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

    def __init__(self, runtime: str = "docker", verbose: bool = False):
        """Initialize the installer.

        Parameters
        ----------
        runtime: str
            Container runtime to use. Either ``docker`` or ``podman``. If
            ``docker`` is selected but unavailable, the installer will attempt
            to fall back to Podman if it is detected.
        verbose: bool
            Enable verbose logging output.
        """
        load_dotenv()

        self.runtime = runtime
        self.verbose = verbose
        self.webui_image = "ghcr.io/open-webui/open-webui:main"
        self.config_dir = os.path.expanduser("~/.openwebui")
        self._setup_logger()

        # Initialize container runtime
        try:
            self.docker_client = docker.from_env()
            # Test connection
            self.docker_client.ping()
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

    def __enter__(self):
        """Context manager entry."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()

    def close(self):
        """Close any resources held by the installer."""
        if hasattr(self, 'docker_client'):
            try:
                self.docker_client.close()
            except Exception:
                pass

    def _setup_logger(self) -> None:
        """Configure logging with rotation under the config directory."""
        self.log_dir = os.path.join(self.config_dir, "logs")
        os.makedirs(self.log_dir, exist_ok=True)
        self.log_file = os.path.join(self.log_dir, "openwebui_installer.log")

        if not logger.handlers:
            # Rotating file handler (10MB max, 5 backups)
            handler = RotatingFileHandler(
                self.log_file, maxBytes=10 * 1024 * 1024, backupCount=5
            )
            formatter = logging.Formatter(
                "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            logger.setLevel(logging.DEBUG if self.verbose else logging.INFO)

    def _podman_available(self) -> bool:
        """Check if Podman is installed."""
        try:
            result = subprocess.run(
                ["podman", "--version"],
                capture_output=True,
                text=True,
                check=False
            )
            return result.returncode == 0
        except FileNotFoundError:
            return False

    def _get_podman_client(self):
        """Get a Podman-compatible Docker client."""
        try:
            # Try to connect to Podman socket
            import docker
            client = docker.DockerClient(base_url="unix:///run/user/1000/podman/podman.sock")
            client.ping()
            return client
        except Exception:
            # Fallback to default socket locations
            try:
                client = docker.DockerClient(base_url="unix:///var/run/podman/podman.sock")
                client.ping()
                return client
            except Exception:
                # Last resort: system socket
                client = docker.DockerClient(base_url="unix:///run/podman/podman.sock")
                client.ping()
                return client

    def _check_system_requirements(self):
        """Validate system requirements."""
        if self.verbose:
            logger.info("Validating system requirements")

        # Check supported operating systems (macOS and Linux)
        system = platform.system()
        if system not in ("Darwin", "Linux"):
            raise SystemRequirementsError(
                "This installer supports macOS and Linux. Windows support coming soon."
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
            response = requests.get("http://localhost:11434/api/version", timeout=5)
            if response.status_code != 200:
                console.print(
                    "[yellow]Warning:[/yellow] Ollama is not running. "
                    "Install Ollama from https://ollama.ai for full functionality."
                )
        except requests.RequestException:
            console.print(
                "[yellow]Warning:[/yellow] Ollama is not accessible. "
                "Install Ollama from https://ollama.ai for full functionality."
            )

        # Create config directory
        os.makedirs(self.config_dir, exist_ok=True)

    def _pull_webui_image(self, image: str) -> None:
        """Pull the Open WebUI Docker image."""
        try:
            logger.info(f"Pulling Open WebUI image: {image}")
            console.print(f"Pulling Open WebUI image: {image}...")

            # Pull image with progress
            self.docker_client.images.pull(image)
            console.print(f"[green]✓[/green] Successfully pulled {image}")

        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to pull Open WebUI image: {str(e)}")

    def _pull_ollama_model(self, model: str) -> None:
        """Pull the specified Ollama model."""
        try:
            logger.info(f"Pulling Ollama model: {model}")
            console.print(f"Pulling Ollama model: {model}...")

            # Check if Ollama is available
            try:
                response = requests.get("http://localhost:11434/api/version", timeout=5)
                if response.status_code == 200:
                    # Pull model via Ollama API
                    pull_response = requests.post(
                        "http://localhost:11434/api/pull",
                        json={"name": model},
                        timeout=300
                    )
                    if pull_response.status_code == 200:
                        console.print(f"[green]✓[/green] Successfully pulled model {model}")
                    else:
                        console.print(f"[yellow]Warning:[/yellow] Could not pull model {model}")
                else:
                    console.print(f"[yellow]Warning:[/yellow] Ollama not available, skipping model pull")
            except requests.RequestException:
                console.print(f"[yellow]Warning:[/yellow] Ollama not available, skipping model pull")

        except Exception as e:
            logger.warning(f"Failed to pull Ollama model {model}: {str(e)}")
            console.print(f"[yellow]Warning:[/yellow] Could not pull model {model}: {str(e)}")

    def _create_launch_script(self, port: int, image: str) -> None:
        """Create launch script for Open WebUI."""
        launch_script = os.path.join(self.config_dir, "launch-openwebui.sh")

        # Environment variables with fallbacks
        ollama_base_url = os.environ.get("OLLAMA_BASE_URL", "http://host.docker.internal:11434")
        ollama_api_base_url = os.environ.get("OLLAMA_API_BASE_URL", "http://host.docker.internal:11434/api")

        script_content = f"""#!/bin/bash
# Open WebUI Launch Script
# Generated by openwebui-installer

{self.runtime} run -d \\
    --name open-webui \\
    -p {port}:8080 \\
    -v open-webui:/app/backend/data \\
    -e OLLAMA_BASE_URL={ollama_base_url} \\
    -e OLLAMA_API_BASE_URL={ollama_api_base_url} \\
    --add-host host.docker.internal:host-gateway \\
    {image}

echo "Open WebUI started on http://localhost:{port}"
"""

        with open(launch_script, "w") as f:
            f.write(script_content)
        os.chmod(launch_script, 0o755)

        logger.info(f"Created launch script: {launch_script}")

    def _stop_existing_container(self) -> None:
        """Stop and remove existing Open WebUI container."""
        try:
            # Try to get existing container
            try:
                container = self.docker_client.containers.get("open-webui")
                logger.info("Stopping existing Open WebUI container")
                container.stop(timeout=10)
                container.remove()
                console.print("Stopped and removed existing Open WebUI container")
            except docker.errors.NotFound:
                # No existing container, that's fine
                pass
        except docker.errors.APIError as e:
            logger.warning(f"Error stopping existing container: {str(e)}")

    def _start_container(self, port: int, image: str) -> None:
        """Start the Open WebUI container."""
        try:
            logger.info("Starting Open WebUI container")

            # Environment variables
            env_vars = {
                "OLLAMA_BASE_URL": os.environ.get("OLLAMA_BASE_URL", "http://host.docker.internal:11434"),
                "OLLAMA_API_BASE_URL": os.environ.get("OLLAMA_API_BASE_URL", "http://host.docker.internal:11434/api"),
            }

            # Add any secret environment variables that are set
            for secret_var in SECRET_ENV_VARS:
                if secret_var in os.environ:
                    env_vars[secret_var] = os.environ[secret_var]

            # Start container
            container = self.docker_client.containers.run(
                image,
                name="open-webui",
                ports={"8080/tcp": port},
                volumes={"open-webui": {"bind": "/app/backend/data", "mode": "rw"}},
                environment=env_vars,
                extra_hosts={"host.docker.internal": "host-gateway"},
                detach=True,
                restart_policy={"Name": "unless-stopped"}
            )

            logger.info(f"Started Open WebUI container: {container.id}")
            console.print(f"[green]✓[/green] Open WebUI container started successfully")

        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to start Open WebUI container: {str(e)}")

    def install(
        self,
        model: str = "llama2",
        port: int = 3000,
        force: bool = False,
        image: Optional[str] = None,
    ):
        """Install Open WebUI."""
        try:
            if self.verbose:
                logger.info("Starting installation")

            # Check if already installed
            if not force and self.get_status()["installed"]:
                raise InstallerError(
                    "Open WebUI is already installed. Use --force to reinstall."
                )

            # Use provided image or default
            current_webui_image = image if image else self.webui_image

            # Pull resources and configure installation
            self._pull_webui_image(current_webui_image)
            self._pull_ollama_model(model)
            self._create_launch_script(port, current_webui_image)

            # Create configuration file
            config = {
                "version": "1.0",
                "image": current_webui_image,
                "port": port,
                "model": model,
                "runtime": self.runtime,
                "installed_at": subprocess.check_output(["date", "+%Y-%m-%d %H:%M:%S"]).decode().strip(),
            }

            config_file = os.path.join(self.config_dir, "config.json")
            with open(config_file, "w") as f:
                json.dump(config, f, indent=2)

            # Start the container after installation
            console.print("Starting Open WebUI container...")
            if self.verbose:
                logger.info("Starting Open WebUI container")

            self._stop_existing_container()
            self._start_container(port, current_webui_image)

            console.print(f"[green]✓[/green] Installation completed successfully!")
            console.print(f"Open WebUI is available at: http://localhost:{port}")

            if self.verbose:
                logger.info("Installation completed successfully")

        except Exception as e:
            logger.error(f"Installation failed: {str(e)}")
            raise InstallerError(f"Installation failed: {str(e)}")

    def uninstall(self):
        """Uninstall Open WebUI."""
        try:
            if self.verbose:
                logger.info("Starting uninstallation")

            # Stop and remove container
            self._stop_existing_container()

            # Remove Docker image
            try:
                config_file = os.path.join(self.config_dir, "config.json")
                if os.path.exists(config_file):
                    with open(config_file, "r") as f:
                        config = json.load(f)
                    image_name = config.get("image", self.webui_image)

                    try:
                        self.docker_client.images.remove(image_name, force=True)
                        console.print(f"Removed Docker image: {image_name}")
                    except docker.errors.ImageNotFound:
                        pass
            except Exception as e:
                logger.warning(f"Could not remove Docker image: {str(e)}")

            # Remove volume
            try:
                volume = self.docker_client.volumes.get("open-webui")
                volume.remove()
                console.print("Removed Docker volume: open-webui")
            except docker.errors.NotFound:
                pass

            # Remove configuration directory
            if os.path.exists(self.config_dir):
                shutil.rmtree(self.config_dir)
                console.print(f"Removed configuration directory: {self.config_dir}")

            if self.verbose:
                logger.info("Uninstallation completed successfully")

        except Exception as e:
            logger.error(f"Uninstallation failed: {str(e)}")
            raise InstallerError(f"Uninstallation failed: {str(e)}")

    def get_status(self) -> Dict[str, any]:
        """Get installation and runtime status."""
        config_file = os.path.join(self.config_dir, "config.json")

        if not os.path.exists(config_file):
            return {
                "installed": False,
                "running": False,
                "version": None,
                "port": None,
                "model": None,
            }

        try:
            with open(config_file, "r") as f:
                config = json.load(f)

            # Check if container is running
            running = False
            try:
                container = self.docker_client.containers.get("open-webui")
                running = container.status == "running"
            except docker.errors.NotFound:
                running = False

            return {
                "installed": True,
                "running": running,
                "version": config.get("version"),
                "port": config.get("port"),
                "model": config.get("model"),
                "runtime": config.get("runtime", self.runtime),
                "image": config.get("image"),
            }

        except Exception as e:
            logger.error(f"Error getting status: {str(e)}")
            return {
                "installed": False,
                "running": False,
                "version": None,
                "port": None,
                "model": None,
                "error": str(e),
            }

    def start(self):
        """Start Open WebUI container."""
        try:
            if self.verbose:
                logger.info("Starting Open WebUI")

            status = self.get_status()
            if not status["installed"]:
                raise InstallerError("Open WebUI is not installed. Run 'install' first.")

            try:
                container = self.docker_client.containers.get("open-webui")
                if container.status != "running":
                    container.start()
                    console.print("Started Open WebUI container")
                else:
                    console.print("Open WebUI is already running")
            except docker.errors.NotFound:
                # Container doesn't exist, recreate it
                port = status.get("port", 3000)
                image = status.get("image", self.webui_image)
                self._start_container(port, image)

        except Exception as e:
            logger.error(f"Failed to start Open WebUI: {str(e)}")
            raise InstallerError(f"Failed to start Open WebUI: {str(e)}")

    def stop(self):
        """Stop Open WebUI container."""
        try:
            if self.verbose:
                logger.info("Stopping Open WebUI")

            try:
                container = self.docker_client.containers.get("open-webui")
                if container.status == "running":
                    container.stop(timeout=10)
                    console.print("Stopped Open WebUI container")
                else:
                    console.print("Open WebUI is not running")
            except docker.errors.NotFound:
                console.print("Open WebUI container not found")

        except Exception as e:
            logger.error(f"Failed to stop Open WebUI: {str(e)}")
            raise InstallerError(f"Failed to stop Open WebUI: {str(e)}")

    def restart(self):
        """Restart Open WebUI container."""
        try:
            if self.verbose:
                logger.info("Restarting Open WebUI")

            self.stop()
            self.start()

        except Exception as e:
            logger.error(f"Failed to restart Open WebUI: {str(e)}")
            raise InstallerError(f"Failed to restart Open WebUI: {str(e)}")

    def update(self, image: Optional[str] = None):
        """Update Open WebUI to the latest version."""
        try:
            if self.verbose:
                logger.info("Updating Open WebUI")

            status = self.get_status()
            if not status["installed"]:
                raise InstallerError("Open WebUI is not installed. Run 'install' first.")

            # Use provided image or default
            new_image = image if image else self.webui_image

            # Pull latest image
            self._pull_webui_image(new_image)

            # Stop existing container
            self._stop_existing_container()

            # Start with new image
            port = status.get("port", 3000)
            self._start_container(port, new_image)

            # Update configuration
            config_file = os.path.join(self.config_dir, "config.json")
            if os.path.exists(config_file):
                with open(config_file, "r") as f:
                    config = json.load(f)
                config["image"] = new_image
                config["updated_at"] = subprocess.check_output(["date", "+%Y-%m-%d %H:%M:%S"]).decode().strip()
                with open(config_file, "w") as f:
                    json.dump(config, f, indent=2)

            console.print("Open WebUI updated successfully!")

        except Exception as e:
            logger.error(f"Failed to update Open WebUI: {str(e)}")
            raise InstallerError(f"Failed to update Open WebUI: {str(e)}")

    def show_logs(self, lines: int = 50, follow: bool = False):
        """Show Open WebUI container logs."""
        try:
            if self.verbose:
                logger.info(f"Showing logs (lines: {lines}, follow: {follow})")

            container = self.docker_client.containers.get("open-webui")

            if follow:
                # Stream logs
                for log_line in container.logs(stream=True, follow=True, tail=lines):
                    console.print(log_line.decode().strip())
            else:
                # Get logs
                logs = container.logs(tail=lines).decode()
                console.print(logs)

        except docker.errors.NotFound:
            console.print("Open WebUI container not found")
        except Exception as e:
            logger.error(f"Failed to get logs: {str(e)}")
            raise InstallerError(f"Failed to get logs: {str(e)}")

    def enable_autostart(self):
        """Enable autostart on macOS."""
        if platform.system() != "Darwin":
            raise InstallerError("Autostart is only supported on macOS")

        try:
            if self.verbose:
                logger.info("Enabling autostart")

            plist_dir = os.path.expanduser("~/Library/LaunchAgents")
            os.makedirs(plist_dir, exist_ok=True)

            plist_file = os.path.join(plist_dir, "com.openwebui.installer.plist")
            launch_script = os.path.join(self.config_dir, "launch-openwebui.sh")

            plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openwebui.installer</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>{launch_script}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>"""

            with open(plist_file, "w") as f:
                f.write(plist_content)

            # Load the launch agent
            subprocess.run(["launchctl", "load", plist_file], check=True)
            console.print(f"Autostart enabled via {plist_file}")

        except Exception as e:
            logger.error(f"Failed to enable autostart: {str(e)}")
            raise InstallerError(f"Failed to enable autostart: {str(e)}")

    def disable_autostart(self):
        """Disable autostart on macOS."""
        if platform.system() != "Darwin":
            raise InstallerError("Autostart is only supported on macOS")

        try:
            if self.verbose:
                logger.info("Disabling autostart")

            plist_file = os.path.expanduser("~/Library/LaunchAgents/com.openwebui.installer.plist")

            if os.path.exists(plist_file):
                # Unload the launch agent
                subprocess.run(["launchctl", "unload", plist_file], check=False)
                os.remove(plist_file)
                console.print("Autostart disabled")
            else:
                console.print("Autostart is not enabled")

        except Exception as e:
            logger.error(f"Failed to disable autostart: {str(e)}")
            raise InstallerError(f"Failed to disable autostart: {str(e)}")
