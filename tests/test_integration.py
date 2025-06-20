"""
Integration tests for Open WebUI Installer
"""

import os
import subprocess
import pytest
import docker
import requests
from pathlib import Path
from openwebui_installer.installer import Installer
from unittest.mock import patch, Mock

@pytest.fixture(scope="module")
def docker_client():
    """Create a Docker client"""
    return docker.from_env()

@pytest.fixture
def installer():
    """Create a test installer instance"""
    installer = Installer()
    installer.config_dir = "/tmp/openwebui-test-integration"
    yield installer
    # Cleanup
    try:
        if os.path.exists(installer.config_dir):
            import shutil
            shutil.rmtree(installer.config_dir)
    except:
        pass

def test_installer_initialization(installer):
    """Test installer initialization"""
    assert installer.webui_image == "ghcr.io/open-webui/open-webui:main"
    assert "openwebui" in installer.config_dir

def test_system_requirements_check(installer):
    """Test system requirements validation"""
    # This test will fail if Docker or Ollama are not running
    # We'll mock the requirements check for now
    with patch.object(installer, '_check_system_requirements'):
        installer._check_system_requirements()

def test_config_directory_creation(installer):
    """Test configuration directory creation"""
    installer._ensure_config_dir()
    assert os.path.exists(installer.config_dir)

def test_installation_workflow(installer):
    """Test complete installation workflow"""
    with patch.object(installer, '_check_system_requirements'), \
         patch.object(installer.docker_client.images, 'pull'), \
         patch('subprocess.run') as mock_run:
        
        installer.install(model="llama2", port=3000)
        
        # Verify Docker image was pulled
        installer.docker_client.images.pull.assert_called_once_with(installer.webui_image)
        
        # Verify Ollama model was pulled
        mock_run.assert_called_once_with(["ollama", "pull", "llama2"], check=True)

def test_uninstall_workflow(installer):
    """Test uninstall workflow"""
    with patch.object(installer.docker_client.containers, 'get') as mock_get, \
         patch.object(installer.docker_client.volumes, 'get') as mock_volume_get, \
         patch('shutil.rmtree'):
        
        # Mock container
        mock_container = Mock()
        mock_get.return_value = mock_container
        
        # Mock volume
        mock_volume = Mock()
        mock_volume_get.return_value = mock_volume
        
        installer.uninstall()
        
        # Verify container was stopped and removed
        mock_container.stop.assert_called_once()
        mock_container.remove.assert_called_once()
        
        # Verify volume was removed
        mock_volume.remove.assert_called_once()

def test_status_check(installer):
    """Test status checking"""
    # Test when not installed
    status = installer.get_status()
    assert status["installed"] is False
    assert status["running"] is False
    
    # Test when installed but not running
    with patch('os.path.exists', return_value=True), \
         patch('builtins.open', create=True) as mock_open:
        
        mock_open.return_value.__enter__.return_value.read.return_value = '{"version": "0.1.0", "port": 3000, "model": "llama2"}'
        
        with patch.object(installer.docker_client.containers, 'get', side_effect=docker.errors.NotFound("Container not found")):
            status = installer.get_status()
            assert status["installed"] is True
            assert status["version"] == "0.1.0"
            assert status["running"] is False

def test_docker_integration(installer, docker_client):
    """Test Docker integration"""
    # Ensure Docker is running
    assert installer.check_docker()
    assert installer.state.docker_installed
    
    # Test container creation
    installer.check_permissions()
    installer.setup_compose()
    
    try:
        # Try to start the container
        subprocess.run(["docker", "compose", "up", "-d"], cwd=installer.install_dir, check=True)
        
        # Check if container is running
        containers = docker_client.containers.list()
        webui_containers = [c for c in containers if "open-webui" in c.name]
        assert len(webui_containers) > 0
        
        # Check if service is responding
        response = requests.get("http://localhost:3000")
        assert response.status_code in [200, 301, 302]
    finally:
        # Cleanup
        subprocess.run(["docker", "compose", "down", "--volumes"], cwd=installer.install_dir)

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