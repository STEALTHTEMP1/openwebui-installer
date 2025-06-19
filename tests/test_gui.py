"""
Tests for the GUI module
"""
import sys
from unittest.mock import MagicMock, patch, Mock

import pytest
from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QApplication, QMessageBox
from PyQt6.QtTest import QTest

from openwebui_installer.gui import MainWindow, InstallerWindow
from openwebui_installer.installer import InstallerError

# Create QApplication instance for tests
@pytest.fixture(scope="session")
def qapp():
    """Create a QApplication instance."""
    app = QApplication.instance()
    if app is None:
        app = QApplication(sys.argv)
    yield app

@pytest.fixture
def window(qapp):
    """Create a MainWindow instance."""
    with patch("openwebui_installer.gui.Installer"):
        window = MainWindow()
        yield window
        window.close()

@pytest.fixture
def app():
    return QApplication([])

@pytest.fixture
def installer_mock():
    return Mock()

@pytest.fixture
def installer_window(app, installer_mock):
    return InstallerWindow(installer_mock)

def test_window_title(window):
    """Test window title contains version."""
    assert "Open WebUI Installer" in window.windowTitle()
    assert "v0.1.0" in window.windowTitle()

def test_initial_state(window):
    """Test initial window state."""
    assert window.model_combo.currentText() == "llama2"
    assert window.port_spin.value() == 3000
    assert not window.progress_bar.isVisible()
    assert window.install_button.isEnabled()

def test_model_selection(window):
    """Test model selection combo box."""
    models = ["llama2", "codellama", "mistral"]
    for i, model in enumerate(models):
        assert window.model_combo.itemText(i) == model

def test_port_selection(window):
    """Test port number spinbox."""
    assert window.port_spin.minimum() == 1024
    assert window.port_spin.maximum() == 65535
    window.port_spin.setValue(8080)
    assert window.port_spin.value() == 8080

@pytest.mark.parametrize("installed,running", [
    (False, False),
    (True, False),
    (True, True),
])
def test_status_display(window, installed, running):
    """Test status display for different states."""
    status = {
        "installed": installed,
        "version": "0.1.0" if installed else None,
        "port": 3000 if installed else None,
        "model": "llama2" if installed else None,
        "running": running,
    }
    
    with patch("openwebui_installer.gui.Installer") as mock_installer:
        mock_installer.return_value.get_status.return_value = status
        window.update_status()
        
        if installed:
            assert window.status_label.isVisible()
            assert "Open WebUI is installed" in window.status_label.text()
            assert window.install_button.text() == "Reinstall"
            assert window.uninstall_button.isEnabled()
            if running:
                assert "Running" in window.status_label.text()
            else:
                assert "Stopped" in window.status_label.text()
        else:
            assert not window.status_label.isVisible()
            assert window.install_button.text() == "Install"
            assert not window.uninstall_button.isEnabled()

def test_installation_success(window, qapp):
    """Test successful installation process."""
    with patch("openwebui_installer.gui.InstallerThread") as mock_thread:
        # Start installation
        window.start_installation()
        
        # Verify UI state during installation
        assert window.progress_bar.isVisible()
        assert not window.install_button.isEnabled()
        assert not window.uninstall_button.isEnabled()
        
        # Simulate progress
        window.update_progress("Installing...")
        assert "Installing..." in window.progress_bar.text()
        
        # Simulate completion
        with patch.object(QMessageBox, "information") as mock_info:
            window.handle_success()
            mock_info.assert_called_once()
            assert "Complete" in mock_info.call_args[0][1]
            assert window.install_button.isEnabled()
            assert not window.progress_bar.isVisible()

def test_installation_error(window, qapp):
    """Test installation error handling."""
    error_message = "Installation failed"
    
    with patch.object(QMessageBox, "warning") as mock_warning:
        window.handle_error(error_message)
        mock_warning.assert_called_once()
        assert error_message in mock_warning.call_args[0][2]
        assert window.install_button.isEnabled()
        assert not window.progress_bar.isVisible()

def test_uninstall_confirmation(window, qapp):
    """Test uninstall confirmation dialog."""
    with patch.object(QMessageBox, "question", return_value=QMessageBox.StandardButton.Yes) as mock_question, \
         patch("openwebui_installer.gui.Installer") as mock_installer:
        
        window.uninstall()
        mock_question.assert_called_once()
        mock_installer.return_value.uninstall.assert_called_once()

def test_uninstall_cancel(window, qapp):
    """Test canceling uninstall."""
    with patch.object(QMessageBox, "question", return_value=QMessageBox.StandardButton.No) as mock_question, \
         patch("openwebui_installer.gui.Installer") as mock_installer:
        
        window.uninstall()
        mock_question.assert_called_once()
        mock_installer.return_value.uninstall.assert_not_called()

def test_uninstall_error(window, qapp):
    """Test uninstall error handling."""
    error_message = "Uninstall failed"
    
    with patch.object(QMessageBox, "question", return_value=QMessageBox.StandardButton.Yes), \
         patch("openwebui_installer.gui.Installer") as mock_installer:
        
        mock_installer.return_value.uninstall.side_effect = InstallerError(error_message)
        
        with patch.object(QMessageBox, "warning") as mock_warning:
            window.uninstall()
            mock_warning.assert_called_once()
            assert error_message in mock_warning.call_args[0][2]

class TestInstallerGUI:
    def test_window_title(self, installer_window):
        """Test window title is set correctly"""
        assert installer_window.windowTitle() == "Open WebUI Installer"
        
    def test_initial_state(self, installer_window):
        """Test initial state of the window"""
        assert installer_window.install_button.isEnabled()
        assert not installer_window.progress_bar.isVisible()
        assert installer_window.status_label.text() == "Ready to install"
        
    def test_install_button_click(self, installer_window, installer_mock):
        """Test install button click triggers installation"""
        QTest.mouseClick(installer_window.install_button, Qt.MouseButton.LeftButton)
        
        installer_mock.check_system_requirements.assert_called_once()
        installer_mock.install.assert_called_once()
        
    def test_installation_progress(self, installer_window):
        """Test installation progress updates"""
        installer_window.update_progress("Installing Docker...", 25)
        
        assert installer_window.status_label.text() == "Installing Docker..."
        assert installer_window.progress_bar.value() == 25
        assert installer_window.progress_bar.isVisible()
        
    def test_installation_complete(self, installer_window):
        """Test installation complete state"""
        installer_window.installation_complete()
        
        assert installer_window.status_label.text() == "Installation complete!"
        assert installer_window.progress_bar.value() == 100
        assert not installer_window.install_button.isEnabled()
        
    def test_installation_error(self, installer_window):
        """Test installation error handling"""
        error_msg = "Failed to install Docker"
        installer_window.installation_error(error_msg)
        
        assert installer_window.status_label.text() == f"Error: {error_msg}"
        assert installer_window.install_button.isEnabled()
        
    def test_cancel_button(self, installer_window, installer_mock):
        """Test cancel button functionality"""
        # Start installation
        QTest.mouseClick(installer_window.install_button, Qt.MouseButton.LeftButton)
        
        # Click cancel
        QTest.mouseClick(installer_window.cancel_button, Qt.MouseButton.LeftButton)
        
        installer_mock.cleanup.assert_called_once()
        assert installer_window.install_button.isEnabled()
        assert installer_window.status_label.text() == "Installation cancelled"
        
    @patch('webbrowser.open')
    def test_open_webui_button(self, mock_browser, installer_window, installer_mock):
        """Test open WebUI button"""
        installer_mock.is_open_webui_running.return_value = True
        
        QTest.mouseClick(installer_window.open_webui_button, Qt.MouseButton.LeftButton)
        
        mock_browser.assert_called_once_with('http://localhost:3000')
        
    def test_open_webui_button_disabled(self, installer_window, installer_mock):
        """Test open WebUI button when WebUI is not running"""
        installer_mock.is_open_webui_running.return_value = False
        
        assert not installer_window.open_webui_button.isEnabled()
        
    def test_cleanup_on_close(self, installer_window, installer_mock):
        """Test cleanup is called when window is closed"""
        installer_window.close()
        
        installer_mock.cleanup.assert_called_once() 