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
import time
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
            Enable verbose logging and output.
        """
        load_dotenv()

        self.runtime = runtime
        self.verbose = verbose
        self.webui_image = "ghcr.io/open-webui/open-webui:main"
        self.config_dir = os.path.expanduser("~/.openwebui")

        # Initialize Docker client with runtime fallback
        try:
            self.docker_client = docker.from_env()
            # Test Docker connection
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

        self._setup_logger()

    def __enter__(self):
        """Context manager entry."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()

    def close(self):
        """Close any resources held by the installer."""
        if hasattr(self, 'docker_client') and self.docker_client:
            try:
                self.docker_client.close()
            except Exception:
                pass

    def _setup_logger(self) -> None:
        """Configure logging with rotation under the config directory."""
        self.log_dir = os.path.join(self.config_dir, "logs")
        os.makedirs(self.log_dir, exist_ok=True)
        self.log_file = os.path.join(self.log_dir, "openwebui_installer.log")

        if self.verbose:
            handler = RotatingFileHandler(
                self.log_file, maxBytes=5 * 1024 * 1024, backupCount=3
            )
            handler.setFormatter(
                logging.Formatter(
                    "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
                )
            )
            logger.addHandler(handler)
            logger.setLevel(logging.INFO)

    def _podman_available(self) -> bool:
        """Check if Podman is installed."""
        try:
            result = subprocess.run(
                ["podman", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return False

    def _get_podman_client(self):
        """Get a Podman-compatible Docker client."""
        try:
            # Try to connect to Podman socket
            import docker
            client = docker.DockerClient(base_url='unix:///tmp/podman.sock')
            # Test the connection
            client.ping()
            return client
        except Exception:
            # Fallback to default Docker client
            try:
                import docker
                client = docker.from_env()
                client.ping()
                return client
            except Exception:
                return None

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
        if not self.docker_client:
            if self.runtime == "podman":
                raise SystemRequirementsError("Podman is not available or not installed")
            else:
                raise SystemRequirementsError("Docker is not available or not installed")

        try:
            self.docker_client.ping()
        except Exception as e:
            if self.runtime == "podman":
                raise SystemRequirementsError("Podman is not running or not installed")
            if self._podman_available():
                raise SystemRequirementsError(
                    "Docker is not running or not installed. Podman detected; use --runtime podman"
                )
            raise SystemRequirementsError(
                "Docker service is not running. Start Docker Desktop and ensure the daemon is running."
            ) from e

        # Check Ollama with timeout
        try:
            response = requests.get("http://localhost:11434/api/tags", timeout=10)
            if response.status_code != 200:
                raise SystemRequirementsError("Ollama is not responding correctly")
        except requests.exceptions.RequestException:
            raise SystemRequirementsError(
                "Ollama is not running. Please install and start Ollama first:\n"
                "Visit: https://ollama.ai/"
            )

        # Create config directory
        os.makedirs(self.config_dir, exist_ok=True)

    def _pull_webui_image(self, image: str) -> None:
        """Pull the Open WebUI Docker image."""
        if not self.docker_client:
            raise InstallerError("Docker client not available")

        try:
            if self.verbose:
                logger.info(f"Pulling Docker image: {image}")
            console.print(f"Pulling Open WebUI image: {image}...")
            self.docker_client.images.pull(image)
        except docker.errors.APIError as e:
            raise InstallerError(f"Failed to pull Docker image {image}: {str(e)}")

    def _pull_ollama_model(self, model: str) -> None:
        """Pull Ollama model if not already available."""
        try:
            if self.verbose:
                logger.info(f"Checking Ollama model: {model}")

            # Check if model is already available
            response = requests.get("http://localhost:11434/api/tags", timeout=10)
            if response.status_code == 200:
                models = response.json().get("models", [])
                model_names = [m["name"] for m in models]
                if model in model_names:
                    console.print(f"Model {model} is already available")
                    return

            console.print(f"Pulling Ollama model: {model}...")
            result = subprocess.run(
                ["ollama", "pull", model],
                capture_output=True,
                text=True,
                timeout=300
            )
            if result.returncode != 0:
                raise InstallerError(f"Failed to pull Ollama model {model}: {result.stderr}")

        except requests.exceptions.RequestException:
            raise InstallerError("Failed to communicate with Ollama")
        except subprocess.TimeoutExpired:
            raise InstallerError(f"Timeout pulling Ollama model {model}")

    def _create_launch_script(self, port: int, image: str) -> None:
        """Create launch script for Open WebUI."""
        launch_script = os.path.join(self.config_dir, "launch-openwebui.sh")

        # Environment variables
        ollama_base_url = os.environ.get("OLLAMA_BASE_URL", "http://host.docker.internal:11434")
        ollama_api_base_url = os.environ.get("OLLAMA_API_BASE_URL", "http://host.docker.internal:11434/api")

        script_content = f"""#!/bin/bash
{self.runtime} run -d \\
    --name open-webui \\
    -p {port}:8080 \\
    -v open-webui:/app/backend/data \\
    -e OLLAMA_BASE_URL={ollama_base_url} \\
    -e OLLAMA_API_BASE_URL={ollama_api_base_url} \\
    --add-host host.docker.internal:host-gateway \\
    {image}
"""

        with open(launch_script, "w") as f:
            f.write(script_content)
        os.chmod(launch_script, 0o755)

    def _stop_existing_container(self) -> None:
        """Stop and remove existing Open WebUI container."""
        if not self.docker_client:
            raise InstallerError("Docker client not available")

        try:
            container = self.docker_client.containers.get("open-webui")
            if container.status == "running":
                container.stop()
            container.remove()
            if self.verbose:
                logger.info("Stopped and removed existing container")
        except docker.errors.NotFound:
            pass  # Container doesn't exist, which is fine

    def _start_container(self, port: int, image: str) -> None:
        """Start Open WebUI container."""
        if not self.docker_client:
            raise InstallerError("Docker client not available")

        try:
            # Environment variables
            env_vars = {
                "OLLAMA_BASE_URL": os.environ.get("OLLAMA_BASE_URL", "http://host.docker.internal:11434"),
                "OLLAMA_API_BASE_URL": os.environ.get("OLLAMA_API_BASE_URL", "http://host.docker.internal:11434/api"),
            }

            # Add secret environment variables if they exist
            for secret_var in SECRET_ENV_VARS:
                if secret_var in os.environ:
                    env_vars[secret_var] = os.environ[secret_var]

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

            if self.verbose:
                logger.info(f"Started container: {container.id}")

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
                raise InstallerError("Open WebUI is already installed. Use --force to reinstall.")

            # Use provided image or default
            current_webui_image = image if image else self.webui_image

            # Pull resources and configure installation
            self._pull_webui_image(current_webui_image)
            self._pull_ollama_model(model)
            self._create_launch_script(port, current_webui_image)

            # Create configuration file
            config = {
                "model": model,
                "port": port,
                "image": current_webui_image,
                "installed_at": time.time(),
                "runtime": self.runtime
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

        except Exception as e:
            if self.verbose:
                logger.error(f"Installation failed: {str(e)}")
            raise InstallerError(f"Installation failed: {str(e)}")

    def uninstall(self):
        """Uninstall Open WebUI."""
        if not self.docker_client:
            raise InstallerError("Docker client not available")

        try:
            if self.verbose:
                logger.info("Starting uninstallation")

            # Stop and remove container
            self._stop_existing_container()

            # Remove Docker volume
            try:
                volume = self.docker_client.volumes.get("open-webui")
                volume.remove()
            except docker.errors.NotFound:
                pass

            # Remove configuration
            if os.path.exists(self.config_dir):
                shutil.rmtree(self.config_dir)

            if self.verbose:
                logger.info("Uninstallation completed")

        except Exception as e:
            if self.verbose:
                logger.error(f"Uninstallation failed: {str(e)}")
            raise InstallerError(f"Uninstallation failed: {str(e)}")

    def get_status(self) -> Dict:
        """Get installation and running status."""
        try:
            config_file = os.path.join(self.config_dir, "config.json")

            if not os.path.exists(config_file):
                return {
                    "installed": False,
                    "running": False,
                    "version": None,
                    "port": None,
                    "model": None,
                }

            with open(config_file) as f:
                config = json.load(f)

            # Check if container is running
            running = False
            if self.docker_client:
                try:
                    container = self.docker_client.containers.get("open-webui")
                    running = container.status == "running"
                except docker.errors.NotFound:
                    pass
                except Exception:
                    # If Docker client fails, assume not running
                    pass

            return {
                "installed": True,
                "running": running,
                "version": config.get("image", "unknown"),
                "port": config.get("port", 3000),
                "model": config.get("model", "unknown"),
                "runtime": config.get("runtime", self.runtime)
            }

        except Exception as e:
            if self.verbose:
                logger.error(f"Status check failed: {str(e)}")
            return {
                "installed": False,
                "running": False,
                "version": None,
                "port": None,
                "model": None,
                "error": str(e)
            }

    def start(self):
        """Start Open WebUI container."""
        if not self.docker_client:
            raise InstallerError("Docker client not available")

        try:
            container = self.docker_client.containers.get("open-webui")
            if container.status != "running":
                container.start()
                if self.verbose:
                    logger.info("Started Open WebUI container")
            else:
                console.print("Open WebUI is already running")
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container not found. Please install first.")
        except Exception as e:
            raise InstallerError(f"Failed to start container: {e}")

    def stop(self):
        """Stop Open WebUI container."""
        if not self.docker_client:
            raise InstallerError("Docker client not available")

        try:
            container = self.docker_client.containers.get("open-webui")
            if container.status == "running":
                container.stop()
                if self.verbose:
                    logger.info("Stopped Open WebUI container")
            else:
                console.print("Open WebUI is not running")
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container not found")
        except Exception as e:
            raise InstallerError(f"Failed to stop container: {e}")

    def restart(self):
        """Restart Open WebUI container."""
        if not self.docker_client:
            raise InstallerError("Docker client not available")

        try:
            container = self.docker_client.containers.get("open-webui")
            container.restart()
            if self.verbose:
                logger.info("Restarted Open WebUI container")
        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container not found")
        except Exception as e:
            raise InstallerError(f"Failed to restart container: {e}")

    def update(self, image: Optional[str] = None):
        """Update Open WebUI to latest version."""
        try:
            if self.verbose:
                logger.info("Starting update")

            status = self.get_status()
            if not status["installed"]:
                raise InstallerError("Open WebUI is not installed")

            # Use provided image or current image
            current_image = image if image else status.get("version", self.webui_image)

            # Pull latest image
            self._pull_webui_image(current_image)

            # Get current configuration
            config_file = os.path.join(self.config_dir, "config.json")
            with open(config_file) as f:
                config = json.load(f)

            # Stop current container
            self._stop_existing_container()

            # Start with updated image
            self._start_container(config["port"], current_image)

            # Update config
            config["image"] = current_image
            with open(config_file, "w") as f:
                json.dump(config, f, indent=2)

            if self.verbose:
                logger.info("Update completed")

        except Exception as e:
            if self.verbose:
                logger.error(f"Update failed: {str(e)}")
            raise InstallerError(f"Update failed: {str(e)}")

    def show_logs(self, tail: int = 50, follow: bool = False):
        """Show Open WebUI container logs."""
        if not self.docker_client:
            raise InstallerError("Docker client not available")

        try:
            container = self.docker_client.containers.get("open-webui")

            if follow:
                for log in container.logs(stream=True, follow=True, tail=tail):
                    console.print(log.decode("utf-8").strip())
            else:
                logs = container.logs(tail=tail).decode("utf-8")
                console.print(logs)

        except docker.errors.NotFound:
            raise InstallerError("Open WebUI container not found")

    def enable_autostart(self):
        """Enable autostart on macOS using launchd."""
        if platform.system() != "Darwin":
            raise InstallerError("Autostart is only supported on macOS")

        try:
            launch_agents_dir = os.path.expanduser("~/Library/LaunchAgents")
            os.makedirs(launch_agents_dir, exist_ok=True)

            plist_path = os.path.join(launch_agents_dir, "com.openwebui.installer.plist")
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

            with open(plist_path, "w") as f:
                f.write(plist_content)

            # Load the launch agent
            subprocess.run(["launchctl", "load", plist_path], check=True)

            if self.verbose:
                logger.info(f"Autostart enabled via {plist_path}")

        except Exception as e:
            raise InstallerError(f"Failed to enable autostart: {str(e)}")

    def disable_autostart(self):
        """Disable autostart on macOS."""
        if platform.system() != "Darwin":
            raise InstallerError("Autostart is only supported on macOS")

        try:
            plist_path = os.path.expanduser("~/Library/LaunchAgents/com.openwebui.installer.plist")

            if os.path.exists(plist_path):
                # Unload the launch agent
                subprocess.run(["launchctl", "unload", plist_path], check=False)
                os.remove(plist_path)

            if self.verbose:
                logger.info("Autostart disabled")

        except Exception as e:
            raise InstallerError(f"Failed to disable autostart: {str(e)}")
