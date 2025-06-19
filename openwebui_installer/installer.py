"""
Core installer functionality for Open WebUI
"""
import os
import platform
import subprocess
import sys
from typing import Dict, Optional

import docker
import psutil
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
        self.webui_image = "ghcr.io/open-webui/open-webui:main"
        self.config_dir = os.path.expanduser("~/.openwebui")
        
    def _check_system_requirements(self):
        """Validate system requirements."""
        # Check macOS
        if platform.system() != "Darwin":
            raise SystemRequirementsError("This installer only supports macOS")
            
        # Check Python version
        if sys.version_info < (3, 8):
            raise SystemRequirementsError("Python 3.8 or higher is required")
            
        # Check Docker
        try:
            self.docker_client.ping()
        except Exception:
            raise SystemRequirementsError("Docker is not running or not installed")
            
        # Check Ollama
        try:
            response = requests.get("http://localhost:11434/api/tags")
            if response.status_code != 200:
                raise SystemRequirementsError("Ollama is not running")
        except Exception:
            raise SystemRequirementsError("Ollama is not installed or not running")
            
    def _ensure_config_dir(self):
        """Ensure configuration directory exists."""
        os.makedirs(self.config_dir, exist_ok=True)
        
    def install(self, model: str = "llama2", port: int = 3000, force: bool = False):
        """Install Open WebUI."""
        try:
            # Validate system
            self._check_system_requirements()
            
            # Check if already installed
            if not force and self.get_status()["installed"]:
                raise InstallerError("Open WebUI is already installed. Use --force to reinstall.")
                
            # Create config directory
            self._ensure_config_dir()
            
            # Pull Docker image
            console.print("Pulling Open WebUI image...")
            self.docker_client.images.pull(self.webui_image)
            
            # Pull Ollama model
            console.print(f"Pulling Ollama model: {model}...")
            subprocess.run(["ollama", "pull", model], check=True)
            
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
    {self.webui_image}
""")
            os.chmod(launch_script, 0o755)
            
            # Create configuration file
            config = {
                "version": "0.1.0",
                "model": model,
                "port": port,
            }
            with open(os.path.join(self.config_dir, "config.json"), "w") as f:
                import json
                json.dump(config, f, indent=2)
                
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
            import shutil
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
                import json
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