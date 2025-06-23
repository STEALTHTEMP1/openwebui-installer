"""
Command-line interface for Open WebUI Installer
"""

import sys
import logging
from pathlib import Path
from typing import Optional

import click
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

from . import __version__
from .installer import Installer

console = Console()
logger = logging.getLogger("openwebui_installer.cli")
logging.basicConfig(level=logging.INFO)


def validate_system() -> bool:
    """Validate system requirements."""
    try:
        installer = Installer()
        installer._check_system_requirements()
        return True
    except Exception as e:
        logger.error("System validation failed: %s", str(e))
        console.print(f"[red]System validation failed:[/red] {str(e)}")
        return False


@click.group()
@click.version_option(version=__version__)
def cli():
    """Open WebUI Installer - Install and manage Open WebUI with Ollama integration."""
    pass


@cli.command()
@click.option("--model", "-m", help="Ollama model to install", default="llama2")
@click.option("--port", "-p", help="Port to run Open WebUI on", default=3000, type=int)
@click.option("--force", "-f", is_flag=True, help="Force installation even if already installed")
@click.option("--image", help="Custom Open WebUI image to use")
def install(model: str, port: int, force: bool, image: Optional[str]):
    """Install Open WebUI and configure Ollama integration."""
    try:
        logger.info("CLI install command invoked")
        if not validate_system():
            sys.exit(1)

        installer = Installer()
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Installing Open WebUI...", total=None)
            installer.install(model=model, port=port, force=force, image=image)
            progress.update(task, completed=True)

        console.print("[green]✓[/green] Installation complete!")
        logger.info("Installation command completed")
        console.print(f"\nOpen WebUI is now available at: http://localhost:{port}")

    except Exception as e:
        logger.error("Installation command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def uninstall():
    """Uninstall Open WebUI."""
    if not click.confirm("Are you sure you want to uninstall Open WebUI?", default=False):
        console.print("Uninstallation aborted.")
        logger.info("Uninstallation aborted by user")
        return
    try:
        logger.info("CLI uninstall command invoked")
        installer = Installer()
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Uninstalling Open WebUI...", total=None)
            installer.uninstall()
            progress.update(task, completed=True)

        console.print("[green]✓[/green] Uninstallation complete!")
        logger.info("Uninstallation command completed")

    except Exception as e:
        logger.error("Uninstallation command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def status():
    """Check Open WebUI installation status."""
    try:
        logger.info("CLI status command invoked")
        installer = Installer()
        status = installer.get_status()

        if status["installed"]:
            console.print("[green]✓[/green] Open WebUI is installed")
            console.print(f"Version: {status['version']}")
            console.print(f"Port: {status['port']}")
            console.print(f"Model: {status['model']}")
            console.print(f"Status: {'Running' if status['running'] else 'Stopped'}")
        else:
            console.print("[yellow]![/yellow] Open WebUI is not installed")

    except Exception as e:
        logger.error("Status command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.option("--tail", type=int, default=20, help="Show last N lines of the log file")
@click.option("--export", "export_path", type=click.Path(), help="Export log file to destination")
def logs(tail: int, export_path: Optional[str]):
    """View or export installer logs."""
    installer = Installer()
    log_file = installer.log_file
    installer._setup_logger()

    if export_path:
        dest = Path(export_path)
        dest.write_bytes(Path(log_file).read_bytes())
        console.print(f"Logs exported to: {dest}")
        return

    try:
        with open(log_file, "r") as f:
            lines = f.readlines()[-tail:]
            for line in lines:
                click.echo(line.rstrip())
    except FileNotFoundError:
        console.print("Log file not found.")


def main():
    """Main entry point for the CLI."""
    cli()


if __name__ == "__main__":
    main()
