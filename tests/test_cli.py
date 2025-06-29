"""
Tests for the CLI module
"""

from unittest.mock import MagicMock, patch, Mock

import pytest
from click.testing import CliRunner

from openwebui_installer.cli import cli, install, uninstall, status
from openwebui_installer.installer import InstallerError, SystemRequirementsError


@pytest.fixture
def runner():
    """Create a CLI test runner."""
    return CliRunner()


@pytest.fixture
def mock_installer():
    """Mock installer instance supporting context manager usage."""
    with patch("openwebui_installer.cli.Installer") as mock_cls:
        installer = Mock()
        # Configure the mock to behave as a context manager
        mock_instance = mock_cls.return_value
        mock_instance.__enter__.return_value = installer
        mock_instance.__exit__.return_value = False
        yield installer


def test_version(runner):
    """Test version command."""
    result = runner.invoke(cli, ["--version"])
    assert result.exit_code == 0
    assert "version" in result.output.lower()


def test_install_success(runner, mock_installer):
    """Test successful installation."""
    result = runner.invoke(cli, ["install"])
    assert result.exit_code == 0
    mock_installer.install.assert_called_once_with(
        model="llama2", port=3000, force=False, image=None  # Added
    )


def test_install_with_options(runner, mock_installer):
    """Test installation with custom options."""
    result = runner.invoke(cli, ["install", "--model", "codellama", "--port", "8080", "--force"])
    assert result.exit_code == 0
    mock_installer.install.assert_called_once_with(
        model="codellama", port=8080, force=True, image=None  # Added
    )


def test_install_system_requirements_error(runner, mock_installer):
    """Test installation with system requirements error."""
    mock_installer.install.side_effect = SystemRequirementsError("Docker not running")
    result = runner.invoke(cli, ["install"])
    assert result.exit_code == 1
    assert "Docker not running" in result.output


def test_install_error(runner, mock_installer):
    """Test installation with general error."""
    mock_installer.install.side_effect = InstallerError("Installation failed")
    result = runner.invoke(cli, ["install"])
    assert result.exit_code == 1
    assert "Installation failed" in result.output


def test_uninstall_success(runner, mock_installer):
    """Test successful uninstallation."""
    result = runner.invoke(cli, ["uninstall"], input="y\n")
    assert result.exit_code == 0
    mock_installer.uninstall.assert_called_once()


def test_uninstall_abort(runner, mock_installer):
    """Test uninstallation abort."""
    result = runner.invoke(cli, ["uninstall"], input="n\n")
    assert result.exit_code == 0
    mock_installer.uninstall.assert_not_called()


def test_uninstall_error(runner, mock_installer):
    """Test uninstallation with error."""
    mock_installer.uninstall.side_effect = InstallerError("Uninstall failed")
    result = runner.invoke(cli, ["uninstall"], input="y\n")
    assert result.exit_code == 1
    assert "Uninstall failed" in result.output


def test_status_not_installed(runner, mock_installer):
    """Test status command when not installed."""
    mock_installer.get_status.return_value = {
        "installed": False,
        "version": None,
        "port": None,
        "model": None,
        "running": False,
    }
    result = runner.invoke(cli, ["status"])
    assert result.exit_code == 0
    assert "not installed" in result.output.lower()


def test_status_installed_not_running(runner, mock_installer):
    """Test status command when installed but not running."""
    mock_installer.get_status.return_value = {
        "installed": True,
        "version": "0.1.0",
        "port": 3000,
        "model": "llama2",
        "running": False,
    }
    result = runner.invoke(cli, ["status"])
    assert result.exit_code == 0
    assert "installed" in result.output.lower()
    assert "stopped" in result.output.lower()


def test_status_installed_and_running(runner, mock_installer):
    """Test status command when installed and running."""
    mock_installer.get_status.return_value = {
        "installed": True,
        "version": "0.1.0",
        "port": 3000,
        "model": "llama2",
        "running": True,
    }
    result = runner.invoke(cli, ["status"])
    assert result.exit_code == 0
    assert "installed" in result.output.lower()
    assert "running" in result.output.lower()


def test_status_error(runner, mock_installer):
    """Test status command with error."""
    mock_installer.get_status.side_effect = InstallerError("Status check failed")
    result = runner.invoke(cli, ["status"])
    assert result.exit_code == 1
    assert "Status check failed" in result.output


class TestCLI:
    def test_install_command(self, runner, mock_installer):
        """Test install command"""
        # Test successful installation
        result = runner.invoke(cli, ["install"])
        assert result.exit_code == 0
        assert "Installation complete!" in result.output

        # mock_installer._check_system_requirements.assert_called_once() # This is an internal call of the real Installer.install, not directly by CLI
        mock_installer.install.assert_called_once()

        # Test installation failure
        mock_installer.install.side_effect = InstallerError("Installation failed")
        result = runner.invoke(cli, ["install"])
        assert result.exit_code == 1
        assert "Error: Installation failed" in result.output

    def test_uninstall_command(self, runner, mock_installer):
        """Test uninstall command"""
        # Test successful uninstallation
        result = runner.invoke(cli, ["uninstall"], input="y\n")
        assert result.exit_code == 0
        assert "Uninstallation complete!" in result.output

        mock_installer.uninstall.assert_called_once()  # Changed from cleanup

        # Test uninstallation failure
        mock_installer.uninstall.reset_mock()  # Reset mock
        mock_installer.uninstall.side_effect = InstallerError("Uninstallation failed")
        result = runner.invoke(cli, ["uninstall"], input="y\n")
        assert result.exit_code == 1
        assert "Error: Uninstallation failed" in result.output

    def test_status_command(self, runner, mock_installer):
        """Test status command"""
        # Test when Open WebUI is running
        mock_installer.get_status.return_value = {  # Use get_status
            "installed": True,
            "version": "0.1.0",
            "port": 3000,
            "model": "test",
            "running": True,
        }
        result = runner.invoke(cli, ["status"])
        assert result.exit_code == 0
        assert "Open WebUI is installed" in result.output
        assert "Status: Running" in result.output

        # Test when Open WebUI is not running
        mock_installer.get_status.return_value = {  # Use get_status
            "installed": True,
            "version": "0.1.0",
            "port": 3000,
            "model": "test",
            "running": False,
        }
        result = runner.invoke(cli, ["status"])
        assert result.exit_code == 0
        assert "Open WebUI is installed" in result.output
        assert "Status: Stopped" in result.output

        # Test status check failure
        mock_installer.get_status.side_effect = InstallerError(
            "Status check failed"
        )  # Use get_status
        result = runner.invoke(cli, ["status"])
        assert result.exit_code == 1
        assert "Error: Status check failed" in result.output

    def test_version_option(self, runner):
        """Test --version option"""
        from openwebui_installer import __version__  # Import to use in test

        result = runner.invoke(cli, ["--version"])
        assert result.exit_code == 0
        assert f"cli, version {__version__}" in result.output  # New

    def test_help_option(self, runner):
        """Test --help option"""
        result = runner.invoke(cli, ["--help"])
        assert result.exit_code == 0
        assert "Usage:" in result.output
        assert "Options:" in result.output

    def test_install_with_port_option(self, runner, mock_installer):
        """Test install command with custom port"""
        result = runner.invoke(cli, ["install", "--port", "3001"])
        assert result.exit_code == 0

        mock_installer.install.assert_called_once_with(
            model="llama2",  # Default from CLI
            port=3001,  # Provided in test
            force=False,  # Default from CLI
            image=None,  # Added
        )

    def test_install_with_image_option(self, runner, mock_installer):
        """Test install command with custom image"""
        result = runner.invoke(cli, ["install", "--image", "custom/image:tag"])
        assert result.exit_code == 0

        mock_installer.install.assert_called_once_with(
            model="llama2",  # Default from CLI
            port=3000,  # Default from CLI
            force=False,  # Default from CLI
            image="custom/image:tag",  # Provided in test
        )

    def test_logs_tail_and_export(self, runner, tmp_path):
        """Test logs command tail and export options."""
        log_dir = tmp_path / "logs"
        log_dir.mkdir()
        log_file = log_dir / "openwebui_installer.log"
        log_file.write_text("line1\nline2")

        with patch("openwebui_installer.cli.Installer") as mock_inst:
            inst = Mock()
            inst.log_file = str(log_file)
            inst._setup_logger = Mock()
            def fake_show_logs(lines, follow):
                with open(inst.log_file) as f:
                    lines_data = f.read().splitlines()[-lines:]
                    for line in lines_data:
                        print(line)

            inst.show_logs.side_effect = fake_show_logs
            # Support context manager usage
            mock_instance = mock_inst.return_value
            mock_instance.__enter__.return_value = inst
            mock_instance.__exit__.return_value = False

            result = runner.invoke(cli, ["logs", "--lines", "1"])
            assert result.exit_code == 0
            assert "line2" in result.output
