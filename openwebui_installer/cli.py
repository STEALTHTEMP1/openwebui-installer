"""
Command-line interface for Open WebUI Installer
"""

import logging
import sys
from typing import Optional

import click
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

from . import __version__
from .installer import Installer

console = Console()


<<<<<<< HEAD
def validate_system(runtime: str) -> bool:
    """Validate system requirements."""
    try:
<<<<<<< HEAD
        installer = Installer(runtime=runtime)
=======
def validate_system(verbose: bool = False) -> bool:
    """Validate system requirements."""
    try:
        installer = Installer(verbose=verbose)
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
        installer._check_system_requirements()
=======
        with Installer() as installer:
            installer._check_system_requirements()
>>>>>>> origin/codex/add-context-manager-and-close-method
        return True
    except Exception as e:
        console.print(f"[red]System validation failed:[/red] {str(e)}")
        if verbose:
            console.print_exception()
        return False


@click.group()
@click.option("--verbose", is_flag=True, help="Enable verbose output")
@click.version_option(version=__version__)
<<<<<<< HEAD
@click.option('--runtime', type=click.Choice(['docker', 'podman']), default='docker', help='Container runtime to use')
@click.pass_context
def cli(ctx, runtime):
    """Open WebUI Installer - Install and manage Open WebUI with Ollama integration."""
    ctx.obj = {'runtime': runtime}


@cli.command()
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
@click.option('--model', '-m', help='Ollama model to install', default='llama2')
@click.option('--port', '-p', help='Port to run Open WebUI on', default=3000, type=int)
@click.option('--force', '-f', is_flag=True, help='Force installation even if already installed')
@click.option('--image', help='Custom Open WebUI image to use')
@click.pass_context
def install(ctx, model: str, port: int, force: bool, image: Optional[str]):
=======
=======
>>>>>>> origin/codex/extend-installer-with-container-management-methods
=======
>>>>>>> origin/codex/add-cli-methods-and-update-tests
=======
@click.pass_context
def cli(ctx: click.Context, verbose: bool):
    """Open WebUI Installer - Install and manage Open WebUI with Ollama integration."""
    logging.basicConfig(level=logging.DEBUG if verbose else logging.INFO, format="%(message)s")
    ctx.obj = {"verbose": verbose}


@cli.command()
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
=======
>>>>>>> origin/codex/implement-macos-autostart-feature
@click.option("--model", "-m", help="Ollama model to install", default="llama2")
@click.option("--port", "-p", help="Port to run Open WebUI on", default=3000, type=int)
@click.option("--force", "-f", is_flag=True, help="Force installation even if already installed")
@click.option("--image", help="Custom Open WebUI image to use")
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> origin/codex/implement-macos-autostart-feature
def install(model: str, port: int, force: bool, image: Optional[str]):
>>>>>>> origin/codex/extend-installer-with-container-management-commands
    """Install Open WebUI and configure Ollama integration."""
    try:
        if not validate_system(ctx.obj['runtime']):
            sys.exit(1)

<<<<<<< HEAD
        installer = Installer(runtime=ctx.obj['runtime'])
=======
@click.pass_context
def install(ctx: click.Context, model: str, port: int, force: bool, image: Optional[str]):
    """Install Open WebUI and configure Ollama integration."""
    try:
        verbose = ctx.obj.get("verbose", False)
        if not validate_system(verbose=verbose):
            sys.exit(1)

        installer = Installer(verbose=verbose)
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Installing Open WebUI...", total=None)
            installer.install(model=model, port=port, force=force, image=image)
            progress.update(task, completed=True)
=======
        with Installer() as installer:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Installing Open WebUI...", total=None)
                installer.install(model=model, port=port, force=force, image=image)
                progress.update(task, completed=True)
>>>>>>> origin/codex/add-context-manager-and-close-method

        console.print("[green]✓[/green] Installation complete!")
        console.print(f"\nOpen WebUI is now available at: http://localhost:{port}")

    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.pass_context
<<<<<<< HEAD
def uninstall(ctx):
=======
def uninstall(ctx: click.Context):
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
    """Uninstall Open WebUI."""
    if not click.confirm("Are you sure you want to uninstall Open WebUI?", default=False):
        console.print("Uninstallation aborted.")
        return
    try:
<<<<<<< HEAD
<<<<<<< HEAD
        installer = Installer(runtime=ctx.obj['runtime'])
=======
        verbose = ctx.obj.get("verbose", False)
        installer = Installer(verbose=verbose)
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Uninstalling Open WebUI...", total=None)
            installer.uninstall()
            progress.update(task, completed=True)
=======
        with Installer() as installer:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Uninstalling Open WebUI...", total=None)
                installer.uninstall()
                progress.update(task, completed=True)
>>>>>>> origin/codex/add-context-manager-and-close-method

        console.print("[green]✓[/green] Uninstallation complete!")

    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
<<<<<<< HEAD
<<<<<<< HEAD
@click.pass_context
def status(ctx):
=======
def start():
    """Start the Open WebUI container."""
    try:
<<<<<<< HEAD
        installer = Installer()
        installer.start()
        console.print("[green]✓[/green] Open WebUI started")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def stop():
    """Stop the Open WebUI container."""
    try:
        installer = Installer()
        installer.stop()
        console.print("[green]✓[/green] Open WebUI stopped")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def restart():
    """Restart the Open WebUI container."""
    try:
        installer = Installer()
        installer.restart()
        console.print("[green]✓[/green] Open WebUI restarted")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def update():
    """Update the Open WebUI container."""
    try:
        installer = Installer()
        installer.update()
        console.print("[green]✓[/green] Open WebUI updated")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.option("--tail", default=100, help="Number of log lines to show")
def logs(tail: int):
    """Show logs from the Open WebUI container."""
    try:
        installer = Installer()
        output = installer.logs(tail=tail)
        console.print(output)
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command("enable-autostart")
def enable_autostart():
    """Enable autostart on macOS."""
    try:
        installer = Installer()
        path = installer.enable_autostart()
        console.print(f"[green]✓[/green] Autostart enabled via {path}")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def status():
>>>>>>> origin/codex/extend-installer-with-container-management-methods
    """Check Open WebUI installation status."""
    try:
        installer = Installer(runtime=ctx.obj['runtime'])
        status = installer.get_status()
=======
        with Installer() as installer:
            status = installer.get_status()
>>>>>>> origin/codex/add-context-manager-and-close-method

=======
@click.pass_context
def status(ctx: click.Context):
    """Check Open WebUI installation status."""
    try:
        verbose = ctx.obj.get("verbose", False)
        installer = Installer(verbose=verbose)
        status = installer.get_status()

<<<<<<< HEAD
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
=======
>>>>>>> origin/codex/implement-macos-autostart-feature
        if status["installed"]:
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


<<<<<<< HEAD
@cli.command()
def start():
<<<<<<< HEAD
<<<<<<< HEAD
    """Start Open WebUI."""
    try:
        if not validate_system():
            sys.exit(1)

        installer = Installer()
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Starting Open WebUI...", total=None)
            installer.start()
            progress.update(task, completed=True)

        console.print("[green]✓[/green] Open WebUI started!")

=======
    """Start the Open WebUI container."""
=======
    """Start Open WebUI container."""
>>>>>>> origin/codex/add-cli-methods-and-update-tests
    try:
        installer = Installer()
        installer.start()
        console.print("[green]✓[/green] Open WebUI started")
<<<<<<< HEAD
>>>>>>> origin/codex/extend-installer-with-container-management-commands
=======
>>>>>>> origin/codex/add-cli-methods-and-update-tests
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def stop():
<<<<<<< HEAD
<<<<<<< HEAD
    """Stop Open WebUI."""
    try:
        installer = Installer()
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Stopping Open WebUI...", total=None)
            installer.stop()
            progress.update(task, completed=True)

        console.print("[green]✓[/green] Open WebUI stopped!")

=======
    """Stop the Open WebUI container."""
=======
    """Stop Open WebUI container."""
>>>>>>> origin/codex/add-cli-methods-and-update-tests
    try:
        installer = Installer()
        installer.stop()
        console.print("[green]✓[/green] Open WebUI stopped")
<<<<<<< HEAD
>>>>>>> origin/codex/extend-installer-with-container-management-commands
=======
>>>>>>> origin/codex/add-cli-methods-and-update-tests
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
def restart():
<<<<<<< HEAD
<<<<<<< HEAD
    """Restart Open WebUI."""
    try:
        if not validate_system():
            sys.exit(1)

        installer = Installer()
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Restarting Open WebUI...", total=None)
            installer.restart()
            progress.update(task, completed=True)

        console.print("[green]✓[/green] Open WebUI restarted!")

=======
    """Restart the Open WebUI container."""
=======
    """Restart Open WebUI container."""
>>>>>>> origin/codex/add-cli-methods-and-update-tests
    try:
        installer = Installer()
        installer.restart()
        console.print("[green]✓[/green] Open WebUI restarted")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
<<<<<<< HEAD
@click.option("--image", help="Docker image to use when updating")
def update(image: Optional[str]):
    """Update the Open WebUI Docker image and restart."""
=======
@click.option("--image", help="Custom Open WebUI image to use")
def update(image: Optional[str]):
    """Update Open WebUI Docker image."""
>>>>>>> origin/codex/add-cli-methods-and-update-tests
    try:
        installer = Installer()
        installer.update(image=image)
        console.print("[green]✓[/green] Open WebUI updated")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
<<<<<<< HEAD
@click.option("--tail", default=100, help="Number of log lines to display", type=int)
def logs(tail: int):
    """Show logs from the Open WebUI container."""
    try:
        installer = Installer()
        output = installer.logs(tail=tail)
        console.print(output)
>>>>>>> origin/codex/extend-installer-with-container-management-commands
=======
@click.option("--lines", "-n", default=100, help="Number of log lines to show")
def logs(lines: int):
    """Show Open WebUI container logs."""
    try:
        installer = Installer()
        output = installer.logs(tail=lines)
        console.print(output)
>>>>>>> origin/codex/add-cli-methods-and-update-tests
=======
@cli.command(name="enable-autostart")
def enable_autostart_cmd():
    """Configure macOS to start Open WebUI automatically at login."""
    try:
        installer = Installer()
        installer.enable_autostart()
        console.print("[green]✓[/green] Autostart enabled")
>>>>>>> origin/codex/implement-macos-autostart-feature
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


def main():
    """Main entry point for the CLI."""
    cli()


if __name__ == "__main__":
    main()
