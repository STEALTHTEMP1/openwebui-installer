"""
Command-line interface for Open WebUI Installer
"""

import sys
from typing import Optional

import click
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

from . import __version__
from .installer import Installer

console = Console()


def validate_system() -> bool:
    """Validate system requirements."""
    try:
        with Installer() as installer:
            installer._check_system_requirements()
        return True
    except Exception as e:
        console.print(f"[red]System validation failed:[/red] {str(e)}")
        return False


@click.group()
@click.version_option(version=__version__)
def cli():
    """Open WebUI Installer - Install and manage Open WebUI with Ollama integration."""
    pass


@cli.command()
@click.option('--model', '-m', help='Ollama model to install', default='llama2')
@click.option('--port', '-p', help='Port to run Open WebUI on', default=3000, type=int)
@click.option('--force', '-f', is_flag=True, help='Force installation even if already installed')
@click.option('--image', help='Custom Open WebUI image to use')
def install(model: str, port: int, force: bool, image: Optional[str]):
    """Install Open WebUI and configure Ollama integration."""
    try:
        if not validate_system():
            sys.exit(1)

        with Installer() as installer:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Installing Open WebUI...", total=None)
                installer.install(model=model, port=port, force=force, image=image)
                progress.update(task, completed=True)

        console.print("[green]✓[/green] Installation complete!")
        console.print(f"\nOpen WebUI is now available at: http://localhost:{port}")

    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def uninstall():
    """Uninstall Open WebUI."""
    if not click.confirm("Are you sure you want to uninstall Open WebUI?", default=False):
        console.print("Uninstallation aborted.")
        return
    try:
        with Installer() as installer:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Uninstalling Open WebUI...", total=None)
                installer.uninstall()
                progress.update(task, completed=True)

        console.print("[green]✓[/green] Uninstallation complete!")

    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def status():
    """Check Open WebUI installation status."""
    try:
        with Installer() as installer:
            status = installer.get_status()

        if status['installed']:
            console.print("[green]✓[/green] Open WebUI is installed")
            console.print(f"Version: {status['version']}")
            console.print(f"Port: {status['port']}")
            console.print(f"Model: {status['model']}")
            console.print(f"Status: {'Running' if status['running'] else 'Stopped'}")
        else:
            console.print("[yellow]![/yellow] Open WebUI is not installed")

    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


def main():
    """Main entry point for the CLI."""
    cli()


if __name__ == "__main__":
    main()
