import os
from io import BytesIO
from unittest.mock import MagicMock

import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import requests

import pytest

from openwebui_installer.downloader import DownloadError, Downloader


class FakeResponse:
    def __init__(self, data: bytes, status_code: int = 200):
        self._data = data
        self.status_code = status_code
        self.iter_content_called = False

    def raise_for_status(self):
        if self.status_code != 200:
            raise requests.HTTPError(f"Status {self.status_code}")

    def iter_content(self, chunk_size=8192):
        self.iter_content_called = True
        stream = BytesIO(self._data)
        while chunk := stream.read(chunk_size):
            yield chunk


def test_download_skips_when_file_exists(tmp_path, mocker):
    file_path = tmp_path / "file.txt"
    file_path.write_text("hello")
    dl = Downloader(session=MagicMock())

    result = dl.download_if_needed("http://example.com/file", str(file_path))

    assert result == str(file_path)
    assert file_path.read_text() == "hello"


def test_download_fetches_file(tmp_path, mocker):
    session = MagicMock()
    session.get.return_value = FakeResponse(b"data")
    dl = Downloader(session=session)
    dest = tmp_path / "file.txt"

    result = dl.download_if_needed("http://example.com/file", str(dest))

    assert dest.exists()
    assert dest.read_bytes() == b"data"
    assert result == str(dest)
    session.get.assert_called_once()


def test_checksum_mismatch_triggers_redownload(tmp_path, mocker):
    session = MagicMock()
    session.get.return_value = FakeResponse(b"new")
    dl = Downloader(session=session)
    dest = tmp_path / "file.txt"
    dest.write_text("old")

    with pytest.raises(DownloadError):
        dl.download_if_needed("http://example.com/file", str(dest), checksum="invalidchecksum")

    # file should be removed on mismatch
    assert not dest.exists()


def test_failed_download_raises(tmp_path):
    session = MagicMock()
    session.get.side_effect = Exception("network error")
    dl = Downloader(session=session)
    dest = tmp_path / "file.txt"

    with pytest.raises(DownloadError):
        dl.download_if_needed("http://example.com/file", str(dest))
