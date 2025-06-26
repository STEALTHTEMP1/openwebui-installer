"""
Command-line interface for Open WebUI Installer
"""

import sys
import logging
from typing import Optional

import click
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

from . import __version__
from .installer import Installer

console = Console()
logger = logging.getLogger(__name__)


def validate_system(runtime: str, verbose: bool = False) -> bool:
    """Validate system requirements."""
    try:
        installer = Installer(runtime=runtime, verbose=verbose)
        installer._check_system_requirements()
        return True
    except Exception as e:
        if verbose:
            logger.error("System validation failed: %s", str(e))
        console.print(f"[red]System validation failed:[/red] {str(e)}")
        return False


@click.group()
@click.version_option(version=__version__)
@click.option(
    "--runtime",
    type=click.Choice(["docker", "podman"]),
    default="docker",
    help="Container runtime to use",
)
@click.option("--verbose", is_flag=True, help="Enable verbose output")
@click.pass_context
def cli(ctx, runtime, verbose):
    """Open WebUI Installer - Install and manage Open WebUI with Ollama integration."""
    ctx.ensure_object(dict)
    ctx.obj["runtime"] = runtime
    ctx.obj["verbose"] = verbose

    if verbose:
        logging.basicConfig(level=logging.INFO)
        logger.info("CLI initialized with runtime: %s, verbose: %s", runtime, verbose)


@cli.command()
@click.option("--model", "-m", help="Ollama model to install", default="llama2")
@click.option("--port", "-p", help="Port to run Open WebUI on", default=3000, type=int)
@click.option("--force", "-f", is_flag=True, help="Force installation even if already installed")
@click.option("--image", help="Custom Open WebUI image to use")
@click.pass_context
def install(ctx, model: str, port: int, force: bool, image: Optional[str]):
    """Install Open WebUI and configure Ollama integration."""
    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI install command invoked with model: %s, port: %d", model, port)

        if not validate_system(runtime, verbose):
            sys.exit(1)

        with Installer(runtime=runtime, verbose=verbose) as installer:
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
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Install command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.pass_context
def uninstall(ctx):
    """Uninstall Open WebUI."""
    if not click.confirm("Are you sure you want to uninstall Open WebUI?", default=False):
        console.print("Uninstallation aborted.")
        return

    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI uninstall command invoked")

        with Installer(runtime=runtime, verbose=verbose) as installer:
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
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Uninstall command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.pass_context
def status(ctx):
    """Check Open WebUI installation status."""
    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI status command invoked")

        with Installer(runtime=runtime, verbose=verbose) as installer:
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
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Status command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.pass_context
def start(ctx):
    """Start Open WebUI container."""
    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI start command invoked")

        with Installer(runtime=runtime, verbose=verbose) as installer:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Starting Open WebUI...", total=None)
                installer.start()
                progress.update(task, completed=True)

        console.print("[green]✓[/green] Open WebUI started!")

    except Exception as e:
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Start command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.pass_context
def stop(ctx):
    """Stop Open WebUI container."""
    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI stop command invoked")

        with Installer(runtime=runtime, verbose=verbose) as installer:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Stopping Open WebUI...", total=None)
                installer.stop()
                progress.update(task, completed=True)

        console.print("[green]✓[/green] Open WebUI stopped!")

    except Exception as e:
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Stop command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.pass_context
def restart(ctx):
    """Restart Open WebUI container."""
    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI restart command invoked")

        with Installer(runtime=runtime, verbose=verbose) as installer:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Restarting Open WebUI...", total=None)
                installer.restart()
                progress.update(task, completed=True)

        console.print("[green]✓[/green] Open WebUI restarted!")

    except Exception as e:
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Restart command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.pass_context
def update(ctx):
    """Update Open WebUI to the latest version."""
    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI update command invoked")

        with Installer(runtime=runtime, verbose=verbose) as installer:
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Updating Open WebUI...", total=None)
                installer.update()
                progress.update(task, completed=True)

        console.print("[green]✓[/green] Open WebUI updated!")

    except Exception as e:
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Update command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.option("--lines", "-n", help="Number of log lines to show", default=50, type=int)
@click.option("--follow", "-f", is_flag=True, help="Follow log output")
@click.pass_context
def logs(ctx, lines: int, follow: bool):
    """Show Open WebUI container logs."""
    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI logs command invoked with lines: %d, follow: %s", lines, follow)

        with Installer(runtime=runtime, verbose=verbose) as installer:
            installer.show_logs(lines=lines, follow=follow)

    except Exception as e:
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Logs command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


@cli.command()
@click.option("--enable/--disable", default=True, help="Enable or disable autostart")
@click.pass_context
def autostart(ctx, enable: bool):
    """Configure Open WebUI to start automatically on boot (macOS only)."""
    try:
        runtime = (ctx.obj or {}).get("runtime", "docker")
        verbose = (ctx.obj or {}).get("verbose", False)

        if verbose:
            logger.info("CLI autostart command invoked with enable: %s", enable)

        with Installer(runtime=runtime, verbose=verbose) as installer:
            if enable:
                installer.enable_autostart()
                console.print("[green]✓[/green] Autostart enabled!")
            else:
                installer.disable_autostart()
                console.print("[green]✓[/green] Autostart disabled!")

    except Exception as e:
        if (ctx.obj or {}).get("verbose", False):
            logger.error("Autostart command failed: %s", str(e))
        console.print(f"[red]Error:[/red] {str(e)}")
        sys.exit(1)


def main():
    """Main entry point for the CLI."""
    cli()


if __name__ == "__main__":
    main()
