"""Tests for the GUI module."""
import sys
from unittest.mock import patch, MagicMock

import pytest
from openwebui_installer.gui import PYQT_AVAILABLE

pytestmark = pytest.mark.skipif(not PYQT_AVAILABLE, reason="PyQt6 not available")

if PYQT_AVAILABLE:  # Only import when available to avoid ImportError
    from PyQt6.QtWidgets import QApplication, QMessageBox
    from openwebui_installer.gui import MainWindow
    from openwebui_installer import __version__

@pytest.fixture
def window(qapp):
    """Create a MainWindow instance for testing, ensuring it's closed after."""
    with patch.object(MainWindow, 'update_status'):
        win = MainWindow()
        yield win
        # Ensure the window is closed and events are processed
        win.close()
        qapp.processEvents()

def test_window_title(window):
    """Test the main window title is set correctly."""
    assert window.windowTitle() == f"Open WebUI Installer v{__version__}"

@patch("openwebui_installer.gui.Installer")
def test_initial_status_call(mock_installer, qapp):
    """Test that update_status is called on initialization."""
    with patch.object(MainWindow, 'update_status') as mock_update:
        # Create and immediately close the window to test initialization
        win = MainWindow()
        mock_update.assert_called_once()
        win.close()
        qapp.processEvents()

def test_start_installation(window):
    """Test that the UI is disabled and the installer thread is started."""
    with patch("openwebui_installer.gui.InstallerThread") as mock_thread_class, \
         patch.object(window.install_button, 'setEnabled') as mock_set_install_enabled, \
         patch.object(window.uninstall_button, 'setEnabled') as mock_set_uninstall_enabled, \
         patch.object(window.progress_bar, 'show') as mock_show_progress:

        mock_thread_instance = mock_thread_class.return_value
        window.start_installation()

        mock_set_install_enabled.assert_called_with(False)
        mock_set_uninstall_enabled.assert_called_with(False)
        mock_show_progress.assert_called_once()
        mock_thread_class.assert_called_once()
        mock_thread_instance.start.assert_called_once()

@patch("openwebui_installer.gui.QMessageBox")
def test_handle_success(mock_msg_box, window):
    """Test the UI state after a successful installation."""
    with patch.object(window, 'update_status') as mock_update, \
         patch.object(window.install_button, 'setEnabled') as mock_set_enabled, \
         patch.object(window.uninstall_button, 'setEnabled') as mock_uninstall_set_enabled, \
         patch.object(window.progress_bar, 'hide') as mock_hide:
        window.handle_success()
        mock_set_enabled.assert_called_with(True)
        mock_uninstall_set_enabled.assert_called_with(True)
        mock_hide.assert_called_once()
        mock_update.assert_called_once()
        mock_msg_box.information.assert_called_once()

@patch("openwebui_installer.gui.QMessageBox")
def test_handle_error(mock_msg_box, window):
    """Test the UI state after a failed installation."""
    with patch.object(window, 'update_status') as mock_update, \
         patch.object(window.install_button, 'setEnabled') as mock_set_enabled, \
         patch.object(window.uninstall_button, 'setEnabled') as mock_uninstall_set_enabled, \
         patch.object(window.progress_bar, 'hide') as mock_hide:
        error_message = "A wild error appeared!"
        window.handle_error(error_message)
        mock_set_enabled.assert_called_with(True)
        mock_uninstall_set_enabled.assert_called_with(True)
        mock_hide.assert_called_once()
        mock_update.assert_called_once()
        mock_msg_box.warning.assert_called_with(window, "Installation Error", error_message)

def test_update_progress(window):
    """Test that the progress bar format is updated correctly."""
    with patch.object(window.progress_bar, 'setFormat') as mock_set_format:
        message = "Updating..."
        window.update_progress(message)
        mock_set_format.assert_called_with(message)

def test_uninstall_confirmed(window):
    """Test that installer.uninstall is called when the user confirms."""
    # Let's mock QMessageBox at the window level instead
    with patch.object(window, 'update_status') as mock_update:
        with patch("openwebui_installer.gui.Installer") as mock_installer_class:
            with patch("PyQt6.QtWidgets.QMessageBox.question", return_value=QMessageBox.StandardButton.Yes) as mock_question:
                with patch("PyQt6.QtWidgets.QMessageBox.information") as mock_information:

                    # Mock installer instance
                    mock_installer_instance = mock_installer_class.return_value
                    mock_installer_instance.uninstall = MagicMock()

                    window.uninstall()

                    # Check that question was asked
                    mock_question.assert_called_once()
                    # Check that installer was created and uninstall called
                    mock_installer_class.assert_called_once()
                    mock_installer_instance.uninstall.assert_called_once()
                    # Check success message was shown
                    mock_information.assert_called_once()
                    mock_update.assert_called_once()

@patch("openwebui_installer.gui.QMessageBox")
@patch("openwebui_installer.gui.Installer")
def test_uninstall_cancelled(mock_installer_class, mock_msg_box, window):
    """Test that installer.uninstall is NOT called when the user cancels."""
    mock_msg_box.question.return_value = QMessageBox.StandardButton.No
    mock_installer_instance = mock_installer_class.return_value

    window.uninstall()

    mock_msg_box.question.assert_called_once()
    mock_installer_instance.uninstall.assert_not_called()

def test_uninstall_with_error(window):
    """Test the error handling logic during uninstallation."""
    with patch.object(window, 'update_status') as mock_update:
        with patch("openwebui_installer.gui.Installer") as mock_installer_class:
            with patch("PyQt6.QtWidgets.QMessageBox.question", return_value=QMessageBox.StandardButton.Yes) as mock_question:
                with patch("PyQt6.QtWidgets.QMessageBox.warning") as mock_warning:

                    # Mock installer to raise exception
                    error_message = "Could not uninstall."
                    mock_installer_instance = mock_installer_class.return_value
                    mock_installer_instance.uninstall.side_effect = Exception(error_message)

                    window.uninstall()

                    # Check that installer was created and uninstall called
                    mock_installer_class.assert_called_once()
                    mock_installer_instance.uninstall.assert_called_once()
                    # Check error message was shown
                    mock_warning.assert_called_once()
                    # Check that the warning contains our error message
                    warning_args = mock_warning.call_args[0]
                    assert "Could not uninstall" in warning_args[2]  # message is third argument
                    mock_update.assert_called_once()
