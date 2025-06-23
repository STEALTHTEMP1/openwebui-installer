"""Download-on-demand utilities."""

from __future__ import annotations

import hashlib
import os
from typing import Optional

import requests


class DownloadError(Exception):
    """Raised when a download fails or checksum mismatch occurs."""


def _sha256(path: str) -> str:
    """Calculate SHA256 hash of a file."""
    hash_obj = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            hash_obj.update(chunk)
    return hash_obj.hexdigest()


class Downloader:
    """Simple download manager that fetches files only when needed."""

    def __init__(self, session: Optional[requests.Session] = None) -> None:
        self.session = session or requests.Session()

    def download_if_needed(self, url: str, dest: str, checksum: Optional[str] = None) -> str:
        """Download ``url`` to ``dest`` if ``dest`` is missing or checksum mismatch.

        Args:
            url: The remote file URL.
            dest: Path on disk to store the file.
            checksum: Optional SHA256 checksum to validate the download.

        Returns:
            The path to the downloaded or existing file.

        Raises:
            DownloadError: If the download fails or checksum verification fails.
        """
        if os.path.exists(dest):
            if checksum:
                if _sha256(dest) == checksum:
                    return dest
            else:
                return dest

        try:
            response = self.session.get(url, stream=True, timeout=30)
            response.raise_for_status()
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
        except Exception as exc:  # pragma: no cover - real network errors
            raise DownloadError(f"Failed to download {url}: {exc}")

        if checksum and _sha256(dest) != checksum:
            os.remove(dest)
            raise DownloadError("Checksum mismatch after download")
        return dest
