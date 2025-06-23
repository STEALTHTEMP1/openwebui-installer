"""Integration tests that exercise the installer with a real Docker engine."""

import os
import shutil
import subprocess

import docker
import pytest

from openwebui_installer.installer import Installer


@pytest.fixture(scope="module")
def docker_client():
    """Return a real Docker client or skip if Docker is unavailable."""
    try:
        client = docker.from_env()
        client.ping()
    except docker.errors.DockerException as exc:
        pytest.skip(f"Docker daemon not available: {exc}")
    yield client
    # Clean up any leftover container or volume after the suite
    for name in ["open-webui"]:
        try:
            c = client.containers.get(name)
            c.remove(force=True)
        except docker.errors.NotFound:
            pass
    try:
        v = client.volumes.get("open-webui")
        v.remove(force=True)
    except docker.errors.NotFound:
        pass


@pytest.fixture
def installer(docker_client, tmp_path, monkeypatch):
    """Return an Installer using the real Docker client."""
    inst = Installer()
    inst.docker_client = docker_client
    inst.webui_image = os.environ.get("TEST_WEBUI_IMAGE", "hello-world")
    inst.config_dir = str(tmp_path / "openwebui-test-integration")

    # Skip system requirement checks and model pulls for testing
    monkeypatch.setattr(inst, "_check_system_requirements", lambda: None)
    monkeypatch.setattr(
        subprocess,
        "run",
        lambda *a, **k: subprocess.CompletedProcess(a, 0),
    )

    yield inst

    # Cleanup container, volume and config directory
    try:
        docker_client.containers.get("open-webui").remove(force=True)
    except docker.errors.NotFound:
        pass
    try:
        docker_client.volumes.get("open-webui").remove(force=True)
    except docker.errors.NotFound:
        pass
    shutil.rmtree(inst.config_dir, ignore_errors=True)


def test_installer_initialization(installer):
    """Test installer initialization"""
    assert installer.webui_image == "ghcr.io/open-webui/open-webui:main"
    assert "openwebui" in installer.config_dir


def test_system_requirements_check(installer):
    """Ensure the patched requirements check executes without error."""
    installer._check_system_requirements()


def test_config_directory_creation(installer):
    """Test configuration directory creation"""
    installer._ensure_config_dir()
    assert os.path.exists(installer.config_dir)


def test_installation_workflow(installer, docker_client):
    """Install the container and verify it exists."""
    installer.install(model="llama2", port=3000)

    container = docker_client.containers.get("open-webui")
    assert container is not None
    volume = docker_client.volumes.get("open-webui")
    assert volume is not None


def test_uninstall_workflow(installer, docker_client):
    """Install then uninstall and ensure cleanup."""
    installer.install(model="llama2", port=3001)
    installer.uninstall()

    with pytest.raises(docker.errors.NotFound):
        docker_client.containers.get("open-webui")
    with pytest.raises(docker.errors.NotFound):
        docker_client.volumes.get("open-webui")


def test_status_check(installer):
    """Verify status reporting before and after install."""
    status = installer.get_status()
    assert status["installed"] is False

    installer.install(port=3002)

    status = installer.get_status()
    assert status["installed"] is True
    assert status["version"] == "0.1.0"
    # hello-world exits immediately so running should be False
    assert status["running"] is False
