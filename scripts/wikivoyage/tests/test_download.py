from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts.wikivoyage.download import (
    DownloadError,
    MediaWikiClient,
    discover_pages,
    download_snapshot,
)


def test_discover_pages_follows_continuation_and_ignores_subcategories() -> None:
    responses = iter([
        {
            "query": {"categorymembers": [
                {"pageid": 3, "ns": 14, "title": "Category:Asia"},
                {"pageid": 20, "ns": 0, "title": "Japanese phrasebook"},
            ]},
            "continue": {"cmcontinue": "next", "continue": "-||"},
        },
        {"query": {"categorymembers": [{"pageid": 10, "ns": 0, "title": "Arabic phrasebook"}]}},
    ])

    result = discover_pages(lambda _params: next(responses))

    assert result == ((10, "Arabic phrasebook"), (20, "Japanese phrasebook"))


def test_download_snapshot_writes_revision_checksum_and_reuses_pinned_file(tmp_path: Path) -> None:
    calls: list[dict[str, str]] = []

    class FakeClient:
        def category_pages(self, _category: str):
            return ((20, "Japanese phrasebook"),)

        def latest_revision(self, _pageid: int, _title: str):
            return 123, "2026-09-07T00:00:00Z", b"; Where is the toilet? : ...\n"

    first = download_snapshot(FakeClient(), tmp_path)
    snapshot = tmp_path / "pages/20-123.wikitext"
    original_mtime = snapshot.stat().st_mtime_ns
    second = download_snapshot(FakeClient(), tmp_path)

    assert first.pages[0].snapshot_sha256 == second.pages[0].snapshot_sha256
    assert snapshot.read_bytes().startswith(b";")
    assert snapshot.stat().st_mtime_ns == original_mtime
    manifest = json.loads((tmp_path / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["schema_version"] == 1
    assert manifest["pages"][0]["canonical_url"].endswith("Japanese_phrasebook")
    assert not list(tmp_path.glob("**/*.tmp"))
    assert calls == []


def test_client_retries_retryable_http_status_and_honors_retry_after() -> None:
    class Response:
        def __enter__(self):
            return self

        def __exit__(self, *_args):
            return False

        def read(self):
            return b'{"query": {}}'

    class ErrorHeaders:
        def get(self, key):
            return "3" if key == "Retry-After" else None

    attempts = iter([
        __import__("urllib.error", fromlist=["HTTPError"]).HTTPError("http://example", 429, "slow", ErrorHeaders(), None),
        Response(),
    ])
    delays: list[float] = []

    def opener(_request, timeout):
        assert timeout == 4
        value = next(attempts)
        if isinstance(value, Exception):
            raise value
        return value

    result = MediaWikiClient(max_retries=1, timeout=4, sleep=delays.append, opener=opener).request({"action": "query"})

    assert result == {"query": {}}
    assert delays == [3.0]


def test_client_reports_permanent_http_status() -> None:
    from urllib.error import HTTPError

    def opener(_request, timeout):
        del timeout
        raise HTTPError("http://example", 400, "bad", {}, None)

    with pytest.raises(DownloadError, match="HTTP 400"):
        MediaWikiClient(max_retries=3, opener=opener).request({"action": "query"})

