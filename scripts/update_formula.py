#!/usr/bin/env python3
"""Update Homebrew formula with new version and SHA256 checksum."""
import argparse
import hashlib
import re
from pathlib import Path
import subprocess


def compute_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()


def update_formula(version: str, tarball: Path, formula_path: Path) -> str:
    checksum = compute_sha256(tarball)
    content = formula_path.read_text()
    content = re.sub(r'url "[^"]+"',
                     f'url "https://github.com/open-webui/openwebui-installer/archive/refs/tags/{version}.tar.gz"',
                     content)
    content = re.sub(r'sha256 "[^"]+"', f'sha256 "{checksum}"', content)
    formula_path.write_text(content)
    return checksum


def main() -> None:
    parser = argparse.ArgumentParser(description="Update Homebrew formula file")
    parser.add_argument("version", help="Release version e.g. v1.2.3")
    parser.add_argument("tarball", help="Path to release tarball")
    parser.add_argument("tap_path", help="Path to Homebrew tap repository")
    parser.add_argument("--commit", action="store_true", help="Commit the change")
    args = parser.parse_args()

    tap_path = Path(args.tap_path)
    formula = tap_path / "Formula" / "openwebui-installer.rb"
    checksum = update_formula(args.version, Path(args.tarball), formula)

    if args.commit:
        subprocess.run(["git", "add", str(formula)], cwd=tap_path, check=True)
        subprocess.run([
            "git",
            "commit",
            "-m",
            f"Update openwebui-installer to {args.version}",
            "-m",
            f"SHA256: {checksum}",
        ], cwd=tap_path, check=True)

    print(f"Updated {formula} with SHA256 {checksum}")


if __name__ == "__main__":
    main()
