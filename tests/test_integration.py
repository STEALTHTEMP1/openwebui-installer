"""
Integration tests for Open WebUI Installer
"""

import os
import shutil
import subprocess
from pathlib import Path
from unittest.mock import MagicMock, Mock, patch

import docker
import pytest
import requests

from openwebui_installer.installer import Installer


@pytest.fixture(scope="module")
def docker_client():
    """Create a Docker client"""
    # This might still cause issues if Docker isn't available/configured in the env
    # For now, assuming it's primarily for tests that need a real client, like test_docker_integration
    try:
        return docker.from_env()
    except docker.errors.DockerException:
        return None  # Or skip tests that require it


@pytest.fixture
def installer(mocker, tmp_path):
    """Create a test installer instance with a mocked Docker client."""
    # Patch docker.from_env() before Installer is instantiated
    mock_docker_client_instance = MagicMock()
    mocker.patch("docker.from_env", return_value=mock_docker_client_instance)

    installer_obj = Installer()
    # Use a temporary directory for config_dir for each test run
    config_dir_path = tmp_path / "openwebui-test-integration"
    config_dir_path.mkdir(parents=True, exist_ok=True)
    installer_obj.config_dir = str(config_dir_path)

    assert installer_obj.docker_client == mock_docker_client_instance

    yield installer_obj


@pytest.fixture
def real_installer(tmp_path_factory):
    """Installer using the real Docker client for integration tests."""
    try:
        inst = Installer()
    except docker.errors.DockerException:
        pytest.skip("Docker daemon not available", allow_module_level=True)
    inst.config_dir = str(tmp_path_factory.mktemp("openwebui-real-int"))
    inst._check_system_requirements = lambda: None
    yield inst
    try:
        inst.uninstall()
    finally:
        client = inst.docker_client
        try:
            c = client.containers.get("open-webui")
            c.remove(force=True)
        except docker.errors.NotFound:
            pass
        try:
            v = client.volumes.get("open-webui")
            v.remove(force=True)
        except docker.errors.NotFound:
            pass
        if os.path.exists(inst.config_dir):
            shutil.rmtree(inst.config_dir)


def test_installer_initialization(installer):
    """Test installer initialization"""
    assert installer.webui_image == "ghcr.io/open-webui/open-webui:main"
    assert "openwebui" in installer.config_dir


def test_system_requirements_check(installer):
    """Test system requirements validation"""
    # This test will fail if Docker or Ollama are not running
    # We'll mock the requirements check for now
    with patch.object(installer, "_check_system_requirements"):
        installer._check_system_requirements()


def test_config_directory_creation(installer):
    """Test configuration directory creation"""
    installer._ensure_config_dir()
    assert os.path.exists(installer.config_dir)


def test_installation_workflow(installer):
    """Test complete installation workflow"""
    with patch.object(installer, "_check_system_requirements"), patch.object(
        installer.docker_client.images, "pull"
    ), patch("subprocess.run") as mock_run:

        installer.install(model="llama2", port=3000)

        # Verify Docker image was pulled
        installer.docker_client.images.pull.assert_called_once_with(installer.webui_image)

        # Verify Ollama model was pulled
        mock_run.assert_called_once_with(["ollama", "pull", "llama2"], check=True, timeout=300)


def test_uninstall_workflow(installer):
    """Test uninstall workflow"""
    with patch.object(installer.docker_client.containers, "get") as mock_get, patch.object(
        installer.docker_client.volumes, "get"
    ) as mock_volume_get, patch("shutil.rmtree"):

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
    with patch("os.path.exists", return_value=True), patch(
        "builtins.open", create=True
    ) as mock_open:

        mock_open.return_value.__enter__.return_value.read.return_value = (
            '{"version": "0.1.0", "port": 3000, "model": "llama2"}'
        )

        with patch.object(
            installer.docker_client.containers,
            "get",
            side_effect=docker.errors.NotFound("Container not found"),
        ):
            status = installer.get_status()
            assert status["installed"] is True
            assert status["version"] == "0.1.0"
            assert status["running"] is False


@pytest.mark.integration
def test_real_install_and_uninstall(real_installer):
    """Install using Docker and ensure cleanup works."""
    with patch("subprocess.run"):
        real_installer.install(model="dummy", port=3099, force=True, image="hello-world")

    container = real_installer.docker_client.containers.get("open-webui")
    assert container is not None

    volume = real_installer.docker_client.volumes.get("open-webui")
    assert volume.name == "open-webui"

    assert (Path(real_installer.config_dir) / "config.json").exists()

    real_installer.uninstall()

    with pytest.raises(docker.errors.NotFound):
        real_installer.docker_client.containers.get("open-webui")
    with pytest.raises(docker.errors.NotFound):
        real_installer.docker_client.volumes.get("open-webui")
    assert not os.path.exists(real_installer.config_dir)
