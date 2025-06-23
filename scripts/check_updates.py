#!/usr/bin/env python3
"""
Dependency Update Checker for OpenWebUI Installer

This script checks for outdated dependencies and generates a report
with recommendations for updates.
"""

import subprocess
import sys
import json
import re
from typing import Dict, List, Tuple, Optional
from pathlib import Path
from datetime import datetime

try:
    import requests
    from packaging import version
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich import box
except ImportError:
    print("Installing required packages...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "packaging", "rich"])
    import requests
    from packaging import version
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich import box

console = Console()


class DependencyChecker:
    """Check for outdated dependencies in the project."""

    def __init__(self, project_root: Path = Path.cwd()):
        self.project_root = project_root
        self.pypi_url = "https://pypi.org/pypi/{}/json"
        self.results = {
            "outdated": [],
            "current": [],
            "errors": [],
            "inconsistencies": []
        }

    def parse_requirement(self, requirement: str) -> Tuple[str, Optional[str], str]:
        """Parse a requirement string into package name, operator, and version."""
        # Remove comments and whitespace
        requirement = requirement.split("#")[0].strip()
        if not requirement:
            return "", None, ""

        # Match package name and version specifier
        match = re.match(r'^([a-zA-Z0-9\-_\.]+)([<>=!]+)(.+)$', requirement)
        if match:
            return match.group(1), match.group(2), match.group(3)
        else:
            # Package without version specifier
            return requirement, None, ""

    def get_latest_version(self, package_name: str) -> Optional[str]:
        """Get the latest version of a package from PyPI."""
        try:
            response = requests.get(self.pypi_url.format(package_name), timeout=5)
            if response.status_code == 200:
                data = response.json()
                return data["info"]["version"]
        except Exception as e:
            self.results["errors"].append(f"{package_name}: {str(e)}")
        return None

    def check_file(self, filepath: Path) -> Dict[str, List[str]]:
        """Check dependencies in a single file."""
        if not filepath.exists():
            return {"errors": [f"File not found: {filepath}"]}

        results = {"outdated": [], "current": [], "errors": []}

        with open(filepath, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue

                package_name, operator, specified_version = self.parse_requirement(line)
                if not package_name:
                    continue

                latest_version = self.get_latest_version(package_name)
                if not latest_version:
                    results["errors"].append(f"{package_name}: Failed to fetch version")
                    continue

                if operator and specified_version:
                    # Compare versions
                    try:
                        specified = version.parse(specified_version.split(",")[0])
                        latest = version.parse(latest_version)

                        if operator.startswith(">=") and latest > specified:
                            results["outdated"].append({
                                "package": package_name,
                                "current": specified_version,
                                "latest": latest_version,
                                "line": line
                            })
                        else:
                            results["current"].append({
                                "package": package_name,
                                "current": specified_version,
                                "latest": latest_version,
                                "line": line
                            })
                    except Exception as e:
                        results["errors"].append(f"{package_name}: {str(e)}")
                else:
                    results["current"].append({
                        "package": package_name,
                        "current": "any",
                        "latest": latest_version,
                        "line": line
                    })

        return results

    def check_inconsistencies(self, files: List[Path]) -> List[Dict]:
        """Check for version inconsistencies between files."""
        package_versions = {}
        inconsistencies = []

        for filepath in files:
            if not filepath.exists():
                continue

            with open(filepath, "r") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue

                    package_name, _, specified_version = self.parse_requirement(line)
                    if not package_name:
                        continue

                    if package_name not in package_versions:
                        package_versions[package_name] = {}

                    package_versions[package_name][str(filepath.name)] = specified_version or "any"

        # Find inconsistencies
        for package, versions in package_versions.items():
            unique_versions = set(versions.values())
            if len(unique_versions) > 1:
                inconsistencies.append({
                    "package": package,
                    "versions": versions
                })

        return inconsistencies

    def run_checks(self) -> None:
        """Run all dependency checks."""
        console.print("\n[bold blue]🔍 Checking Dependencies...[/bold blue]\n")

        # Files to check
        files_to_check = [
            self.project_root / "requirements.txt",
            self.project_root / "requirements-dev.txt",
            self.project_root / "requirements-container.txt",
            self.project_root / "setup.py"
        ]

        # Check each file
        for filepath in files_to_check:
            if filepath.exists():
                console.print(f"Checking [cyan]{filepath.name}[/cyan]...")
                results = self.check_file(filepath)

                # Aggregate results
                self.results["outdated"].extend(results.get("outdated", []))
                self.results["current"].extend(results.get("current", []))
                self.results["errors"].extend(results.get("errors", []))

        # Check for inconsistencies
        self.results["inconsistencies"] = self.check_inconsistencies(files_to_check)

    def generate_report(self) -> None:
        """Generate and display the dependency report."""
        # Outdated packages table
        if self.results["outdated"]:
            table = Table(title="📦 Outdated Dependencies", box=box.ROUNDED)
            table.add_column("Package", style="cyan")
            table.add_column("Current", style="yellow")
            table.add_column("Latest", style="green")
            table.add_column("Update Command", style="magenta")

            for dep in self.results["outdated"]:
                update_cmd = f"pip install {dep['package']}>={dep['latest']}"
                table.add_row(
                    dep["package"],
                    dep["current"],
                    dep["latest"],
                    update_cmd
                )

            console.print(table)
            console.print()

        # Inconsistencies
        if self.results["inconsistencies"]:
            console.print(Panel.fit(
                "[bold red]⚠️  Version Inconsistencies Found[/bold red]",
                box=box.ROUNDED
            ))

            for inconsistency in self.results["inconsistencies"]:
                console.print(f"\n[yellow]{inconsistency['package']}:[/yellow]")
                for file, version in inconsistency["versions"].items():
                    console.print(f"  • {file}: {version}")

        # Summary
        console.print("\n[bold]📊 Summary:[/bold]")
        console.print(f"  • Outdated packages: [red]{len(self.results['outdated'])}[/red]")
        console.print(f"  • Current packages: [green]{len(self.results['current'])}[/green]")
        console.print(f"  • Inconsistencies: [yellow]{len(self.results['inconsistencies'])}[/yellow]")
        console.print(f"  • Errors: [red]{len(self.results['errors'])}[/red]")

        # Generate update script
        if self.results["outdated"]:
            self.generate_update_script()

    def generate_update_script(self) -> None:
        """Generate a script to update all outdated dependencies."""
        script_path = self.project_root / "update_dependencies.sh"

        with open(script_path, "w") as f:
            f.write("#!/bin/bash\n")
            f.write(f"# Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("# Script to update outdated dependencies\n\n")
            f.write("set -e\n\n")
            f.write("echo '📦 Updating dependencies...'\n\n")

            for dep in self.results["outdated"]:
                f.write(f"echo 'Updating {dep['package']}...'\n")
                f.write(f"pip install '{dep['package']}>={dep['latest']}'\n\n")

            f.write("echo '✅ All dependencies updated!'\n")

        script_path.chmod(0o755)
        console.print(f"\n[green]✅ Update script generated:[/green] {script_path}")

    def check_security_advisories(self) -> None:
        """Check for security advisories (requires pip-audit)."""
        console.print("\n[bold blue]🔐 Checking Security Advisories...[/bold blue]\n")

        try:
            result = subprocess.run(
                ["pip-audit", "--format", "json"],
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                advisories = json.loads(result.stdout)
                if advisories:
                    console.print("[bold red]⚠️  Security Vulnerabilities Found![/bold red]\n")
                    for advisory in advisories:
                        console.print(f"Package: [red]{advisory['name']}[/red]")
                        console.print(f"Installed: {advisory['version']}")
                        console.print(f"Vulnerability: {advisory['vulns'][0]['id']}")
                        console.print(f"Description: {advisory['vulns'][0]['description']}\n")
                else:
                    console.print("[green]✅ No security vulnerabilities found![/green]")
            else:
                console.print("[yellow]⚠️  pip-audit not installed. Run: pip install pip-audit[/yellow]")
        except FileNotFoundError:
            console.print("[yellow]⚠️  pip-audit not installed. Run: pip install pip-audit[/yellow]")
        except Exception as e:
            console.print(f"[red]Error running security check: {e}[/red]")


def main():
    """Main entry point."""
    console.print(Panel.fit(
        "[bold]🔧 OpenWebUI Installer - Dependency Update Checker[/bold]",
        box=box.DOUBLE
    ))

    checker = DependencyChecker()

    try:
        checker.run_checks()
        checker.generate_report()
        checker.check_security_advisories()
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        console.print(f"\n[red]Error: {e}[/red]")
        sys.exit(1)


if __name__ == "__main__":
    main()
