"""
Tests for the installer module
"""
import json
import platform
import shutil
from unittest.mock import MagicMock, mock_open

import docker
import pytest
from openwebui_installer.installer import (Installer, InstallerError,
                                           SystemRequirementsError)


@pytest.fixture
def installer(tmp_path):
    """Fixture to create a test installer instance with a mocked config directory."""
    config_dir = tmp_path / "openwebui"
    config_dir.mkdir()
    installer_instance = Installer()
    installer_instance.config_dir = str(config_dir)
    # Patch the docker client directly on the instance for all tests
    installer_instance.docker_client = MagicMock()
    return installer_instance


class TestInstallerSuite:
    """A comprehensive and corrected test suite for the Installer class."""

    def test_check_system_requirements_success(self, installer, mocker):
        """Test that system requirements check passes on macOS with Docker and Ollama running."""
        mocker.patch('platform.system', return_value='Darwin')
        mocker.patch('sys.version_info', (3, 8, 0))
        installer.docker_client.ping.return_value = True
        mock_requests_get = mocker.patch('requests.get')
        mock_requests_get.return_value.status_code = 200
        
        # This should not raise any exception
        installer._check_system_requirements()

    def test_check_system_requirements_wrong_os(self, installer, mocker):
        """Test that system requirements check fails on a non-macOS system."""
        mocker.patch('platform.system', return_value='Linux')
        with pytest.raises(SystemRequirementsError, match="This installer only supports macOS"):
            installer._check_system_requirements()

    def test_check_system_requirements_wrong_python(self, installer, mocker):
        """Test that system requirements check fails on an old Python version."""
        mocker.patch('platform.system', return_value='Darwin')
        mocker.patch('sys.version_info', (3, 7, 0))
        with pytest.raises(SystemRequirementsError, match="Python 3.8 or higher is required"):
            installer._check_system_requirements()

    def test_check_system_requirements_docker_not_running(self, installer, mocker):
        """Test that system requirements check fails if Docker is not running."""
        mocker.patch('platform.system', return_value='Darwin')
        mocker.patch('sys.version_info', (3, 8, 0))
        installer.docker_client.ping.side_effect = Exception("Docker not running")
        
        with pytest.raises(SystemRequirementsError, match="Docker is not running or not installed"):
            installer._check_system_requirements()

    def test_check_system_requirements_ollama_not_running(self, installer, mocker):
        """Test that system requirements check fails if Ollama is not running."""
        mocker.patch('platform.system', return_value='Darwin')
        mocker.patch('sys.version_info', (3, 8, 0))
        installer.docker_client.ping.return_value = True
        mock_requests_get = mocker.patch('requests.get')
        mock_requests_get.side_effect = Exception("Connection failed")
        
        with pytest.raises(SystemRequirementsError, match="Ollama is not installed or not running"):
            installer._check_system_requirements()

    def test_install_full_run_success(self, installer, mocker):
        """Test a complete, successful installation run from a clean state."""
        mocker.patch.object(installer, '_check_system_requirements')
        mocker.patch.object(installer, 'get_status', return_value={'installed': False})
        mock_open_patch = mocker.patch('builtins.open', mock_open())
        mocker.patch('os.makedirs')
        mock_json_dump = mocker.patch('json.dump')
        mock_subprocess_run = mocker.patch('subprocess.run')
        mocker.patch('os.chmod')

        installer.install(model="test-model", port=1234, force=False)

        installer._check_system_requirements.assert_called_once()
        installer.docker_client.images.pull.assert_called_with(installer.webui_image)
        mock_subprocess_run.assert_called_with(["ollama", "pull", "test-model"], check=True)
        assert mock_json_dump.call_args[0][0]['port'] == 1234
        assert mock_json_dump.call_args[0][0]['model'] == "test-model"

    def test_install_stops_if_already_installed_without_force(self, installer, mocker):
        """Test that installation stops if already installed and force=False."""
        mocker.patch.object(installer, 'get_status', return_value={'installed': True})
        with pytest.raises(InstallerError, match="Open WebUI is already installed. Use --force to reinstall."):
            installer.install(force=False)

    def test_uninstall_success(self, installer, mocker):
        """Test a successful uninstall removes container, volume, and config directory."""
        mock_rmtree = mocker.patch('shutil.rmtree')
        mocker.patch('os.path.exists', return_value=True)

        mock_container = MagicMock()
        mock_volume = MagicMock()
        
        installer.docker_client.containers.get.return_value = mock_container
        installer.docker_client.volumes.get.return_value = mock_volume

        installer.uninstall()

        mock_container.stop.assert_called_once()
        mock_container.remove.assert_called_once()
        mock_volume.remove.assert_called_once()
        mock_rmtree.assert_called_with(installer.config_dir)

    def test_uninstall_container_and_volume_not_found(self, installer, mocker):
        """Test uninstall when container and volume don't exist."""
        mock_rmtree = mocker.patch('shutil.rmtree')
        mocker.patch('os.path.exists', return_value=True)

        installer.docker_client.containers.get.side_effect = docker.errors.NotFound("not found")
        installer.docker_client.volumes.get.side_effect = docker.errors.NotFound("not found")

        # Should not raise an exception
        installer.uninstall()
        mock_rmtree.assert_called_with(installer.config_dir)

    def test_get_status_not_installed(self, installer, mocker):
        """Test get_status correctly reports not installed when config dir is missing."""
        mocker.patch('os.path.exists', return_value=False)
        status = installer.get_status()
        assert not status["installed"]

    def test_get_status_installed_and_running(self, installer, mocker):
        """Test get_status reports correctly when installed and the container is running."""
        mock_file_content = '{"version": "1.0", "port": 8080, "model": "test-model"}'
        mocker.patch('builtins.open', mock_open(read_data=mock_file_content))
        mocker.patch('os.path.exists', return_value=True)
        
        mock_container = MagicMock()
        mock_container.status = "running"
        installer.docker_client.containers.get.return_value = mock_container
        
        status = installer.get_status()
        
        assert status["installed"]
        assert status["running"]
        assert status["version"] == "1.0"

    def test_get_status_installed_not_running(self, installer, mocker):
        """Test get_status reports correctly when installed but the container is not running."""
        mock_file_content = '{"version": "1.0", "port": 8080, "model": "test-model"}'
        mocker.patch('builtins.open', mock_open(read_data=mock_file_content))
        mocker.patch('os.path.exists', return_value=True)
        
        installer.docker_client.containers.get.side_effect = docker.errors.NotFound("not found")
        
        status = installer.get_status()
        assert status["installed"]
        assert not status["running"]

    def test_ensure_config_dir(self, installer, mocker):
        """Test that config directory is created."""
        mock_makedirs = mocker.patch('os.makedirs')
        installer._ensure_config_dir()
        mock_makedirs.assert_called_once_with(installer.config_dir, exist_ok=True)

    def test_pull_open_webui_failure(self, installer, mocker):
        """Test error handling when pulling the webui image fails."""
        mocker.patch('docker.from_env').return_value.images.pull.side_effect = docker.errors.APIError("pull failed")
        with pytest.raises(InstallerError, match="Failed to pull Open WebUI Docker image"):
            installer.pull_open_webui()
            
    def test_start_open_webui(self, installer, mocker):
        """Test starting Open WebUI container."""
        mock_docker_client = mocker.patch('docker.from_env').return_value
        container = MagicMock()
        mock_docker_client.containers.run.return_value = container
        
        installer.start_open_webui(port=3000)
        
        mock_docker_client.containers.run.assert_called_with(
            installer.webui_image,
            name='open-webui',
            ports={'3000/tcp': 3000},
            environment=['OLLAMA_API_BASE_URL=http://host.docker.internal:11434/api'],
            volumes={f'{installer.config_dir}/data': {'bind': '/app/backend/data', 'mode': 'rw'}},
            detach=True,
            restart_policy={"Name": "unless-stopped"}
        )

    def test_pull_ollama_model_failure(self, installer, mocker):
        """Test error handling when pulling an Ollama model fails."""
        mock_subprocess_run = mocker.patch('subprocess.run')
        mock_subprocess_run.side_effect = Exception("pull failed")
        with pytest.raises(InstallerError, match="Failed to pull Ollama model"):
            installer.pull_ollama_model("test-model")

    def test_stop_open_webui(self, installer, mocker):
        """Test stopping open webui."""
        mock_docker_client = mocker.patch('docker.from_env').return_value
        mock_container = MagicMock()
        mock_docker_client.containers.get.return_value = mock_container
        installer.stop_open_webui()
        mock_container.stop.assert_called_once()
        mock_container.remove.assert_called_once()

    def test_is_open_webui_running(self, installer, mocker):
        """Test checking if open webui is running."""
        mock_docker_client = mocker.patch('docker.from_env').return_value
        mock_docker_client.containers.get.return_value = MagicMock()
        assert installer.is_open_webui_running() is True
        mock_docker_client.containers.get.side_effect = docker.errors.NotFound("not found")
        assert installer.is_open_webui_running() is False

    def test_cleanup(self, installer, mocker):
        """Test cleanup."""
        mock_docker_client = mocker.patch('docker.from_env').return_value
        mock_container = MagicMock()
        mock_volume = MagicMock()
        mock_docker_client.containers.get.return_value = mock_container
        mock_docker_client.volumes.get.return_value = mock_volume
        mock_rmtree = mocker.patch('shutil.rmtree')
        
        installer.cleanup()
        
        mock_container.stop.assert_called_once()
        mock_container.remove.assert_called_once()
        mock_volume.remove.assert_called_once()
        mock_rmtree.assert_called_once()

    def test_check_docker_installed(self, installer, mocker):
        """Test Docker installation check."""
        mock_docker_client = mocker.patch('docker.from_env').return_value
        mock_docker_client.ping.return_value = True
        assert installer.check_docker_installed() is True
        mock_docker_client.ping.side_effect = Exception("Docker not running")
        assert installer.check_docker_installed() is False

    def test_check_ollama_installed(self, installer, mocker):
        """Test Ollama installation check."""
        mock_subprocess_run = mocker.patch('subprocess.run')
        mock_subprocess_run.return_value.returncode = 0
        assert installer.check_ollama_installed() is True
        mock_subprocess_run.return_value.returncode = 1
        assert installer.check_ollama_installed() is False

    def test_install_docker(self, installer, mocker):
        """Test Docker installation."""
        mock_browser = mocker.patch('webbrowser.open')
        installer.install_docker()
        mock_browser.assert_called_once_with('https://www.docker.com/products/docker-desktop')

    def test_install_ollama(self, installer, mocker):
        """Test Ollama installation."""
        mock_subprocess_run = mocker.patch('subprocess.run')
        mock_subprocess_run.return_value.returncode = 0
        installer.install_ollama()
        mock_subprocess_run.assert_called_with(['brew', 'install', 'ollama'], check=True)
        
        mock_subprocess_run.side_effect = Exception("Installation failed")
        with pytest.raises(InstallerError):
            installer.install_ollama() 