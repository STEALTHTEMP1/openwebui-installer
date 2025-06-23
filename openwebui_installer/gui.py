"""
GUI interface for Open WebUI Installer
"""
import sys

from PyQt6.QtCore import Qt, QThread, pyqtSignal
from PyQt6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLabel,
    QComboBox,
    QPushButton,
    QSpinBox,
    QProgressBar,
    QMessageBox,
)

from . import __version__
from .installer import Installer

class InstallerThread(QThread):
    """Thread for running installation process."""
    progress = pyqtSignal(str)
    error = pyqtSignal(str)
    finished = pyqtSignal()

    def __init__(self, model: str, port: int, force: bool = False):
        super().__init__()
        self.model = model
        self.port = port
        self.force = force
        self.installer = Installer()

    def run(self):
        """Run installation process."""
        try:
            self.progress.emit("Checking system requirements...")
            self.installer._check_system_requirements()

            self.progress.emit("Installing Open WebUI...")
            self.installer.install(
                model=self.model,
                port=self.port,
                force=self.force
            )

            self.finished.emit()

        except Exception as e:
            self.error.emit(str(e))

class MainWindow(QMainWindow):
    """Main window for the installer GUI."""

    def __init__(self):
        super().__init__()
        self.setWindowTitle(f"Open WebUI Installer v{__version__}")
        self.setMinimumWidth(500)
        self.setMinimumHeight(300)

        # Create central widget and layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)
        layout.setSpacing(20)
        layout.setContentsMargins(20, 20, 20, 20)

        # Add title
        title = QLabel("Open WebUI Installer")
        title.setStyleSheet("font-size: 24px; font-weight: bold;")
        layout.addWidget(title, alignment=Qt.AlignmentFlag.AlignCenter)

        # Model selection
        model_layout = QHBoxLayout()
        model_label = QLabel("Ollama Model:")
        self.model_combo = QComboBox()
        self.model_combo.addItems(["llama2", "codellama", "mistral"])
        model_layout.addWidget(model_label)
        model_layout.addWidget(self.model_combo)
        layout.addLayout(model_layout)

        # Port selection
        port_layout = QHBoxLayout()
        port_label = QLabel("Port:")
        self.port_spin = QSpinBox()
        self.port_spin.setRange(1024, 65535)
        self.port_spin.setValue(3000)
        port_layout.addWidget(port_label)
        port_layout.addWidget(self.port_spin)
        layout.addLayout(port_layout)

        # Progress bar
        self.progress_bar = QProgressBar()
        self.progress_bar.setTextVisible(True)
        self.progress_bar.hide()
        layout.addWidget(self.progress_bar)

        # Status label
        self.status_label = QLabel()
        self.status_label.setWordWrap(True)
        self.status_label.hide()
        layout.addWidget(self.status_label)

        # Buttons
        button_layout = QHBoxLayout()
        self.install_button = QPushButton("Install")
        self.install_button.clicked.connect(self.start_installation)
        self.uninstall_button = QPushButton("Uninstall")
        self.uninstall_button.clicked.connect(self.uninstall)
        button_layout.addWidget(self.install_button)
        button_layout.addWidget(self.uninstall_button)
        layout.addLayout(button_layout)

        # Update UI based on current status
        self.update_status()

    def update_status(self):
        """Update UI based on current installation status."""
        try:
            installer = Installer()
            status = installer.get_status()

            if status["installed"]:
                lines = [
                    "Open WebUI is installed",
                    f"Version: {status['version']}",
                    f"Port: {status['port']}",
                    f"Model: {status['model']}",
                    f"Status: {'Running' if status['running'] else 'Stopped'}",
                ]
                self.status_label.setText("\n".join(lines))
                self.status_label.show()
                self.install_button.setText("Reinstall")
                self.uninstall_button.setEnabled(True)
            else:
                self.status_label.hide()
                self.install_button.setText("Install")
                self.uninstall_button.setEnabled(False)

        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to get status: {str(e)}")

    def start_installation(self):
        """Start the installation process."""
        self.progress_bar.setRange(0, 0)
        self.progress_bar.show()
        self.install_button.setEnabled(False)
        self.uninstall_button.setEnabled(False)

        # Create and start installer thread
        self.installer_thread = InstallerThread(
            model=self.model_combo.currentText(),
            port=self.port_spin.value(),
            force=True if self.install_button.text() == "Reinstall" else False
        )
        self.installer_thread.progress.connect(self.update_progress)
        self.installer_thread.error.connect(self.handle_error)
        self.installer_thread.finished.connect(self.handle_success)
        self.installer_thread.start()

    def uninstall(self):
        """Uninstall Open WebUI."""
        reply = QMessageBox.question(
            self,
            "Confirm Uninstall",
            "Are you sure you want to uninstall Open WebUI?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )

        if reply == QMessageBox.StandardButton.Yes:
            try:
                installer = Installer()
                installer.uninstall()
                QMessageBox.information(self, "Success", "Open WebUI has been uninstalled.")
                self.update_status()
            except Exception as e:
                QMessageBox.warning(self, "Error", f"Failed to uninstall: {str(e)}")
                self.update_status()

    def update_progress(self, message: str):
        """Update progress bar message."""
        self.progress_bar.setFormat(message)

    def handle_error(self, message: str):
        """Handle installation error."""
        self.progress_bar.hide()
        self.install_button.setEnabled(True)
        self.uninstall_button.setEnabled(True)
        QMessageBox.warning(self, "Installation Error", message)
        self.update_status()

    def handle_success(self):
        """Handle successful installation."""
        self.progress_bar.hide()
        self.install_button.setEnabled(True)
        self.uninstall_button.setEnabled(True)
        QMessageBox.information(
            self,
            "Installation Complete",
            f"Open WebUI has been installed and is available at:\nhttp://localhost:{self.port_spin.value()}"
        )
        self.update_status()

def main():
    """Main entry point for the GUI."""
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
