"""
Tests for the installer module
"""
import os
import platform
import shutil
from unittest.mock import MagicMock, patch, Mock

import docker
import pytest
import requests
import webbrowser

from openwebui_installer.installer import Installer, InstallerError, SystemRequirementsError

@pytest.fixture
def installer():
    """Create a test installer instance."""
    inst = Installer()
    inst.config_dir = "/tmp/openwebui-test"
    return inst

@pytest.fixture
def mock_docker():
    """Mock Docker client."""
    with patch("docker.from_env") as mock:
        client = Mock()
        mock.return_value = client
        yield client

@pytest.fixture
def mock_requests():
    """Mock requests."""
    with patch("requests.get") as mock:
        response = MagicMock()
        response.status_code = 200
        mock.return_value = response
        yield mock

@pytest.fixture
def mock_ollama():
    with patch('openwebui_installer.installer.subprocess') as mock:
        yield mock

def test_system_requirements_success(installer, mock_docker, mock_requests):
    """Test system requirements check success."""
    with patch("platform.system", return_value="Darwin"):
        installer._check_system_requirements()

def test_system_requirements_wrong_os(installer):
    """Test system requirements check fails on non-macOS."""
    with patch("platform.system", return_value="Linux"):
        with pytest.raises(SystemRequirementsError, match="only supports macOS"):
            installer._check_system_requirements()

def test_system_requirements_docker_not_running(installer, mock_docker):
    """Test system requirements check fails when Docker is not running."""
    with patch("platform.system", return_value="Darwin"):
        mock_docker.ping.side_effect = docker.errors.APIError("Docker not running")
        with pytest.raises(SystemRequirementsError, match="Docker is not running"):
            installer._check_system_requirements()

def test_system_requirements_ollama_not_running(installer, mock_docker, mock_requests):
    """Test system requirements check fails when Ollama is not running."""
    with patch("platform.system", return_value="Darwin"):
        mock_requests.return_value.status_code = 500
        with pytest.raises(SystemRequirementsError, match="Ollama is not running"):
            installer._check_system_requirements()

def test_install_success(installer, mock_docker, mock_requests):
    """Test successful installation."""
    with patch("platform.system", return_value="Darwin"), \
         patch("subprocess.run") as mock_run, \
         patch("os.makedirs"), \
         patch("os.chmod"), \
         patch("builtins.open", create=True):
        
        installer.install(model="llama2", port=3000)
        
        # Check Docker image was pulled
        mock_docker.images.pull.assert_called_once_with(installer.webui_image)
        
        # Check Ollama model was pulled
        mock_run.assert_called_once_with(["ollama", "pull", "llama2"], check=True)

def test_install_already_installed(installer, mock_docker, mock_requests):
    """Test installation fails when already installed."""
    with patch("platform.system", return_value="Darwin"), \
         patch.object(installer, "get_status") as mock_status:
        
        mock_status.return_value = {"installed": True}
        
        with pytest.raises(InstallerError, match="already installed"):
            installer.install(model="llama2", port=3000)

def test_uninstall_success(installer, mock_docker):
    """Test successful uninstallation."""
    with patch("shutil.rmtree"), \
         patch("os.path.exists", return_value=True):
        
        container = MagicMock()
        mock_docker.containers.get.return_value = container
        
        volume = MagicMock()
        mock_docker.volumes.get.return_value = volume
        
        installer.uninstall()
        
        # Check container was stopped and removed
        container.stop.assert_called_once()
        container.remove.assert_called_once()
        
        # Check volume was removed
        volume.remove.assert_called_once()

def test_get_status_not_installed(installer):
    """Test get_status when not installed."""
    with patch("os.path.exists", return_value=False):
        status = installer.get_status()
        assert status == {
            "installed": False,
            "version": None,
            "port": None,
            "model": None,
            "running": False,
        }

def test_get_status_installed_not_running(installer, mock_docker):
    """Test get_status when installed but not running."""
    config = {
        "version": "0.1.0",
        "port": 3000,
        "model": "llama2",
    }
    
    with patch("os.path.exists", return_value=True), \
         patch("builtins.open", create=True) as mock_open:
        
        mock_open.return_value.__enter__.return_value.read.return_value = str(config)
        mock_docker.containers.get.side_effect = docker.errors.NotFound("Container not found")
        
        status = installer.get_status()
        assert status["installed"] is True
        assert status["version"] == "0.1.0"
        assert status["port"] == 3000
        assert status["model"] == "llama2"
        assert status["running"] is False

def test_get_status_installed_and_running(installer, mock_docker):
    """Test get_status when installed and running."""
    config = {
        "version": "0.1.0",
        "port": 3000,
        "model": "llama2",
    }
    
    with patch("os.path.exists", return_value=True), \
         patch("builtins.open", create=True) as mock_open:
        
        mock_open.return_value.__enter__.return_value.read.return_value = str(config)
        container = MagicMock()
        container.status = "running"
        mock_docker.containers.get.return_value = container
        
        status = installer.get_status()
        assert status["installed"] is True
        assert status["version"] == "0.1.0"
        assert status["port"] == 3000
        assert status["model"] == "llama2"
        assert status["running"] is True

class TestInstaller:
    def test_check_system_requirements(self, installer):
        """Test system requirements check"""
        # Should pass on macOS
        assert installer.check_system_requirements() is True
        
    def test_check_docker_installed(self, installer, mock_docker):
        """Test Docker installation check"""
        # Test when Docker is running
        mock_docker.ping.return_value = True
        assert installer.check_docker_installed() is True
        
        # Test when Docker is not running
        mock_docker.ping.side_effect = Exception("Docker not running")
        assert installer.check_docker_installed() is False
        
    def test_check_ollama_installed(self, installer, mock_ollama):
        """Test Ollama installation check"""
        # Test when Ollama is installed
        mock_ollama.run.return_value.returncode = 0
        assert installer.check_ollama_installed() is True
        
        # Test when Ollama is not installed
        mock_ollama.run.return_value.returncode = 1
        assert installer.check_ollama_installed() is False
        
    def test_install_docker(self, installer, mock_docker):
        """Test Docker installation"""
        with patch('webbrowser.open') as mock_browser:
            installer.install_docker()
            mock_browser.assert_called_once_with('https://www.docker.com/products/docker-desktop')
            
    def test_install_ollama(self, installer, mock_ollama):
        """Test Ollama installation"""
        # Test successful installation
        mock_ollama.run.return_value.returncode = 0
        installer.install_ollama()
        mock_ollama.run.assert_called_with(['brew', 'install', 'ollama'], check=True)
        
        # Test failed installation
        mock_ollama.run.side_effect = Exception("Installation failed")
        with pytest.raises(InstallerError):
            installer.install_ollama()
            
    def test_pull_open_webui(self, installer, mock_docker):
        """Test pulling Open WebUI Docker image"""
        # Test successful pull
        installer.pull_open_webui()
        mock_docker.images.pull.assert_called_with('ghcr.io/open-webui/open-webui:latest')
        
        # Test failed pull
        mock_docker.images.pull.side_effect = Exception("Pull failed")
        with pytest.raises(InstallerError):
            installer.pull_open_webui()
            
    def test_start_open_webui(self, installer, mock_docker):
        """Test starting Open WebUI container"""
        container = Mock()
        mock_docker.containers.run.return_value = container
        
        installer.start_open_webui()
        
        mock_docker.containers.run.assert_called_with(
            'ghcr.io/open-webui/open-webui:latest',
            name='open-webui',
            ports={'3000/tcp': 3000},
            environment=['OLLAMA_API_BASE_URL=http://host.docker.internal:11434/api'],
            detach=True
        )
        
    def test_stop_open_webui(self, installer, mock_docker):
        """Test stopping Open WebUI container"""
        container = Mock()
        mock_docker.containers.get.return_value = container
        
        installer.stop_open_webui()
        
        mock_docker.containers.get.assert_called_with('open-webui')
        container.stop.assert_called_once()
        container.remove.assert_called_once()
        
    def test_is_open_webui_running(self, installer, mock_docker):
        """Test checking if Open WebUI is running"""
        # Test when container is running
        container = Mock()
        container.status = 'running'
        mock_docker.containers.get.return_value = container
        
        assert installer.is_open_webui_running() is True
        
        # Test when container is not running
        container.status = 'stopped'
        assert installer.is_open_webui_running() is False
        
        # Test when container doesn't exist
        mock_docker.containers.get.side_effect = Exception("Container not found")
        assert installer.is_open_webui_running() is False
        
    def test_cleanup(self, installer, mock_docker):
        """Test cleanup process"""
        container = Mock()
        mock_docker.containers.get.return_value = container
        
        installer.cleanup()
        
        mock_docker.containers.get.assert_called_with('open-webui')
        container.stop.assert_called_once()
        container.remove.assert_called_once() 