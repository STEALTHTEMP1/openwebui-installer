"""
Integration tests for Open WebUI Installer
"""

import os
import subprocess
import pytest
import docker
import requests
from pathlib import Path
from openwebui_installer.installer import OpenWebUIInstaller

@pytest.fixture(scope="module")
def docker_client():
    """Create a Docker client"""
    return docker.from_env()

@pytest.fixture
def installer():
    """Create a test installer instance"""
    installer = OpenWebUIInstaller()
    installer.install_dir = Path("/tmp/openwebui-test-integration")
    yield installer
    # Cleanup
    try:
        subprocess.run(["docker", "compose", "down"], cwd=installer.install_dir)
    except:
        pass
    if installer.install_dir.exists():
        for container in docker_client.containers.list(all=True):
            if "open-webui" in container.name:
                container.remove(force=True)

def test_docker_integration(installer, docker_client):
    """Test Docker integration"""
    # Ensure Docker is running
    assert installer.check_docker()
    assert installer.state.docker_installed
    
    # Test container creation
    installer.check_permissions()
    installer.setup_compose()
    
    # Try to start the container
    subprocess.run(["docker", "compose", "up", "-d"], cwd=installer.install_dir)
    
    # Check if container is running
    containers = docker_client.containers.list()
    webui_containers = [c for c in containers if "open-webui" in c.name]
    assert len(webui_containers) > 0
    
    # Check if service is responding
    response = requests.get("http://localhost:3000")
    assert response.status_code in [200, 301, 302]

def test_ollama_integration(installer):
    """Test Ollama integration"""
    # Check Ollama installation
    assert installer.check_ollama()
    assert installer.state.ollama_installed
    
    # Test model setup
    assert installer.setup_ollama_model("llama2")
    assert installer.state.selected_model == "llama2"
    
    # Verify model is downloaded
    result = subprocess.run(["ollama", "list"], capture_output=True, text=True)
    assert "llama2" in result.stdout

def test_launcher_integration(installer):
    """Test launcher script integration"""
    installer.check_permissions()
    installer.create_launcher()
    
    launcher_path = installer.install_dir / "launch-openwebui.sh"
    assert launcher_path.exists()
    assert os.access(launcher_path, os.X_OK)
    
    # Test launcher execution (don't actually launch)
    with open(launcher_path, "r") as f:
        content = f.read()
    assert "open -a Docker" in content
    assert "docker compose up -d" in content
    assert "open http://localhost:3000" in content

def test_error_handling(installer):
    """Test error handling in integration scenarios"""
    # Test invalid model
    assert not installer.setup_ollama_model("nonexistent-model")
    assert "Model setup error" in installer.state.errors[0]
    
    # Test Docker Compose errors
    installer.check_permissions()
    with open(installer.install_dir / "docker-compose.yml", "w") as f:
        f.write("invalid: yaml: content")
    
    result = subprocess.run(
        ["docker", "compose", "up", "-d"],
        cwd=installer.install_dir,
        capture_output=True
    )
    assert result.returncode != 0

def test_system_requirements(installer):
    """Test system requirements validation"""
    # Test macOS version check
    assert installer.check_system_requirements()
    
    # Mock unsupported version
    def mock_check_output(*args, **kwargs):
        if args[0][0] == "sw_vers":
            return b"11.0.0\n"
        return subprocess.check_output(*args, **kwargs)
    
    with pytest.MonkeyPatch.context() as mp:
        mp.setattr(subprocess, "check_output", mock_check_output)
        assert not installer.check_system_requirements()
        assert "Unsupported macOS version" in installer.state.errors[-1] 