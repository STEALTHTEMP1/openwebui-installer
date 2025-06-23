"""
Command-line interface for Open WebUI Installer
"""

import logging
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
        logger.error("System validation failed: %s", str(e))
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
=======
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
@click.option("--model", "-m", help="Ollama model to install", default="llama2")
@click.option("--port", "-p", help="Port to run Open WebUI on", default=3000, type=int)
@click.option("--force", "-f", is_flag=True, help="Force installation even if already installed")
@click.option("--image", help="Custom Open WebUI image to use")
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> origin/codex/implement-macos-autostart-feature
=======
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
def install(model: str, port: int, force: bool, image: Optional[str]):
>>>>>>> origin/codex/extend-installer-with-container-management-commands
    """Install Open WebUI and configure Ollama integration."""
    try:
<<<<<<< HEAD
        if not validate_system(ctx.obj['runtime']):
=======
        logger.info("CLI install command invoked")
        if not validate_system():
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
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
        logger.info("Installation command completed")
        console.print(f"\nOpen WebUI is now available at: http://localhost:{port}")

    except Exception as e:
        logger.error("Installation command failed: %s", str(e))
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
        logger.info("Uninstallation aborted by user")
        return
    try:
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        installer = Installer(runtime=ctx.obj['runtime'])
=======
        verbose = ctx.obj.get("verbose", False)
        installer = Installer(verbose=verbose)
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
=======
        logger.info("CLI uninstall command invoked")
        installer = Installer()
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
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
        logger.info("Uninstallation command completed")

    except Exception as e:
        logger.error("Uninstallation command failed: %s", str(e))
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
        logger.info("CLI status command invoked")
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
<<<<<<< HEAD
>>>>>>> origin/codex/enhance-_check_system_requirements-and-cli
=======
>>>>>>> origin/codex/implement-macos-autostart-feature
=======
>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
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


<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
=======
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer
@cli.command()
def start():
    """Start the Open WebUI service."""
    try:
        installer = Installer()
        installer.start()
<<<<<<< HEAD
        console.print("[green]✓[/green] Open WebUI started!")
>>>>>>> origin/codex/replace-placeholder-commands-in-install.py
=======
@cli.command()
@click.option('--port', '-p', type=int, help='Port to run Open WebUI on')
def start(port: Optional[int]):
    """Start the Open WebUI container."""
    try:
        installer = Installer()
        installer.start_container(port=port)
        console.print("[green]✓[/green] Open WebUI started")
>>>>>>> origin/codex/implement-start,-stop,-and-update-commands
=======
        console.print("[green]✓[/green] Open WebUI started")
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
<<<<<<< HEAD
<<<<<<< HEAD
def stop():
<<<<<<< HEAD
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
=======
=======
def stop():
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer
    """Stop the Open WebUI service."""
    try:
        installer = Installer()
        installer.stop()
<<<<<<< HEAD
        console.print("[green]✓[/green] Open WebUI stopped!")
>>>>>>> origin/codex/replace-placeholder-commands-in-install.py
=======
@click.option('--remove', '-r', is_flag=True, help='Remove container after stopping')
def stop(remove: bool):
    """Stop the Open WebUI container."""
    try:
        installer = Installer()
        installer.stop_container(remove=remove)
        console.print("[green]✓[/green] Open WebUI stopped")
>>>>>>> origin/codex/implement-start,-stop,-and-update-commands
=======
        console.print("[green]✓[/green] Open WebUI stopped")
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
def restart():
    """Restart the Open WebUI service."""
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer
    try:
        installer = Installer()
        installer.restart()
        console.print("[green]✓[/green] Open WebUI restarted")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


<<<<<<< HEAD
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
=======
@click.option('--image', help='Docker image to use for update')
def update(image: Optional[str]):
    """Update the Open WebUI container image."""
>>>>>>> origin/codex/implement-start,-stop,-and-update-commands
    try:
        installer = Installer()
        installer.update(image=image)
        console.print("[green]✓[/green] Open WebUI updated")
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


<<<<<<< HEAD
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
=======
@click.option('--image', help='Custom Open WebUI image to use')
def update(image: Optional[str]):
    """Update Open WebUI to the latest version."""
    try:
        installer = Installer()
        installer.update(image=image)
        console.print("[green]✓[/green] Update complete!")
>>>>>>> origin/codex/replace-placeholder-commands-in-install.py
    except Exception as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


=======
>>>>>>> origin/codex/implement-start,-stop,-and-update-commands
=======
>>>>>>> origin/codex/implement-or-remove-cli-commands-in-openwebui_installer
=======
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


>>>>>>> origin/codex/integrate-logging-module-and-add-cli-command
def main():
    """Main entry point for the CLI."""
    cli()


if __name__ == "__main__":
    main()
