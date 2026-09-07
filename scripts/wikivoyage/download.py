#!/usr/bin/env python3
"""Download immutable English Wikivoyage phrasebook revisions.

The downloader deliberately keeps discovery and revision content separate from
the parser.  A successful run leaves a manifest only after every pinned page
has been written and checksummed, so a partial network failure cannot look like
a complete corpus to the next pipeline stage.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import time
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Mapping, Protocol
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen


DEFAULT_API_URL = "https://en.wikivoyage.org/w/api.php"
DEFAULT_SITE = "enwikivoyage"
DEFAULT_CATEGORY = "Category:Phrasebooks"
DEFAULT_USER_AGENT = "LangMap/1.0 (phrasebook-import; https://github.com/tsunhua/langmap)"
RETRYABLE_STATUS = frozenset({429, 500, 502, 503, 504})


class JsonRequester(Protocol):
    def __call__(self, params: Mapping[str, str]) -> Mapping[str, Any]: ...


@dataclass(frozen=True)
class PageDescriptor:
    pageid: int
    title: str
    canonical_url: str
    revision: int
    revision_timestamp: str
    snapshot_file: str
    snapshot_sha256: str


@dataclass(frozen=True)
class SnapshotManifest:
    schema_version: int
    site: str
    category: str
    license: str
    discovered_at: str
    pages: tuple[PageDescriptor, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema_version": self.schema_version,
            "site": self.site,
            "category": self.category,
            "license": self.license,
            "discovered_at": self.discovered_at,
            "pages": [asdict(page) for page in self.pages],
        }


class DownloadError(RuntimeError):
    """Raised when a page or the discovery response cannot be downloaded."""


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _canonical_url(title: str) -> str:
    return "https://en.wikivoyage.org/wiki/" + quote(title.replace(" ", "_"), safe="()/:,_-")


def discover_pages(
    fetch_json: JsonRequester,
    category: str = DEFAULT_CATEGORY,
) -> tuple[tuple[int, str], ...]:
    """Return namespace-0 page ids/titles from one category, sorted by id.

    The callback boundary keeps pagination testable without making tests issue
    real Wikimedia requests.
    """

    continuation: dict[str, str] = {}
    pages: dict[int, str] = {}
    while True:
        params = {
            "action": "query",
            "list": "categorymembers",
            "cmtitle": category,
            "cmnamespace": "0",
            "cmlimit": "max",
            "format": "json",
            "formatversion": "2",
            **continuation,
        }
        payload = fetch_json(params)
        query = payload.get("query")
        if not isinstance(query, Mapping):
            raise DownloadError("category response has no query object")
        members = query.get("categorymembers", [])
        if not isinstance(members, list):
            raise DownloadError("category response has invalid categorymembers")
        for member in members:
            if not isinstance(member, Mapping):
                continue
            try:
                namespace = int(member.get("ns", -1))
                pageid = int(member["pageid"])
                title = str(member["title"]).strip()
            except (KeyError, TypeError, ValueError):
                continue
            if namespace == 0 and pageid > 0 and title:
                pages[pageid] = title
        raw_continue = payload.get("continue")
        if not isinstance(raw_continue, Mapping):
            break
        continuation = {
            str(key): str(value)
            for key, value in raw_continue.items()
            if value is not None
        }
        if not continuation:
            break
    return tuple(sorted(pages.items(), key=lambda item: item[0]))


def _revision_from_payload(payload: Mapping[str, Any], pageid: int, title: str) -> tuple[int, str, bytes]:
    query = payload.get("query")
    pages = query.get("pages") if isinstance(query, Mapping) else None
    page: Mapping[str, Any] | None = None
    if isinstance(pages, list):
        for candidate in pages:
            if isinstance(candidate, Mapping) and int(candidate.get("pageid", -1)) == pageid:
                page = candidate
                break
    elif isinstance(pages, Mapping):
        candidate = pages.get(str(pageid)) or pages.get(pageid)
        if isinstance(candidate, Mapping):
            page = candidate
    if page is None:
        raise DownloadError(f"revision response has no page {pageid}: {title}")
    revisions = page.get("revisions")
    if not isinstance(revisions, list) or not revisions or not isinstance(revisions[0], Mapping):
        raise DownloadError(f"page has no revision {pageid}: {title}")
    revision = revisions[0]
    revision_id = int(revision.get("revid", 0))
    timestamp = str(revision.get("timestamp", ""))
    slots = revision.get("slots")
    content: Any = None
    if isinstance(slots, Mapping):
        main = slots.get("main")
        if isinstance(main, Mapping):
            content = main.get("content")
    if content is None:
        content = revision.get("content")
    if revision_id <= 0 or not timestamp or not isinstance(content, str):
        raise DownloadError(f"incomplete revision {pageid}: {title}")
    return revision_id, timestamp, content.encode("utf-8")


class MediaWikiClient:
    """Small MediaWiki API client with bounded retry/backoff."""

    def __init__(
        self,
        api_url: str = DEFAULT_API_URL,
        *,
        user_agent: str = DEFAULT_USER_AGENT,
        timeout: float = 30.0,
        max_retries: int = 4,
        sleep: Callable[[float], None] = time.sleep,
        opener: Callable[..., Any] = urlopen,
    ) -> None:
        if max_retries < 0:
            raise ValueError("max_retries must be non-negative")
        self.api_url = api_url
        self.user_agent = user_agent
        self.timeout = timeout
        self.max_retries = max_retries
        self.sleep = sleep
        self.opener = opener

    def request(self, params: Mapping[str, str]) -> Mapping[str, Any]:
        query = urlencode(sorted((str(key), str(value)) for key, value in params.items()))
        request = Request(
            f"{self.api_url}?{query}",
            headers={"User-Agent": self.user_agent, "Accept": "application/json"},
        )
        last_error: Exception | None = None
        for attempt in range(self.max_retries + 1):
            try:
                with self.opener(request, timeout=self.timeout) as response:
                    payload = json.loads(response.read().decode("utf-8"))
                if not isinstance(payload, Mapping):
                    raise DownloadError("MediaWiki response is not an object")
                return payload
            except HTTPError as error:
                last_error = error
                if error.code not in RETRYABLE_STATUS or attempt >= self.max_retries:
                    raise DownloadError(f"MediaWiki HTTP {error.code}") from error
                retry_after = error.headers.get("Retry-After") if error.headers else None
                delay = _retry_delay(attempt, retry_after)
            except (URLError, TimeoutError, OSError, json.JSONDecodeError) as error:
                last_error = error
                if attempt >= self.max_retries:
                    raise DownloadError(f"MediaWiki request failed: {error}") from error
                delay = _retry_delay(attempt, None)
            self.sleep(delay)
        raise DownloadError(f"MediaWiki request failed: {last_error}")

    def category_pages(self, category: str) -> tuple[tuple[int, str], ...]:
        return discover_pages(self.request, category)

    def category_revisions(self, category: str) -> dict[int, tuple[int, str, bytes]]:
        """Fetch one latest revision per category page using a generator.

        MediaWiki rejects ``rvlimit`` when a generator yields multiple pages;
        omitting it requests the default latest revision and keeps the number
        of HTTPS round trips bounded by continuation pages.
        """

        continuation: dict[str, str] = {}
        result: dict[int, tuple[int, str, bytes]] = {}
        while True:
            payload = self.request({
                "action": "query",
                "generator": "categorymembers",
                "gcmtitle": category,
                "gcmnamespace": "0",
                "gcmlimit": "max",
                "prop": "revisions",
                "rvprop": "ids|timestamp|content",
                "rvslots": "main",
                "format": "json",
                "formatversion": "2",
                **continuation,
            })
            query = payload.get("query")
            pages = query.get("pages") if isinstance(query, Mapping) else None
            if not isinstance(pages, list):
                raise DownloadError("revision generator response has no pages")
            for page in pages:
                if not isinstance(page, Mapping):
                    continue
                try:
                    pageid = int(page["pageid"])
                    title = str(page["title"])
                except (KeyError, TypeError, ValueError):
                    continue
                if page.get("revisions"):
                    result[pageid] = _revision_from_payload({"query": {"pages": [page]}}, pageid, title)
            raw_continue = payload.get("continue")
            if not isinstance(raw_continue, Mapping):
                break
            continuation = {str(key): str(value) for key, value in raw_continue.items() if value is not None}
            if not continuation:
                break
        return result

    def latest_revision(self, pageid: int, title: str) -> tuple[int, str, bytes]:
        payload = self.request({
            "action": "query",
            "pageids": str(pageid),
            "prop": "revisions",
            "rvprop": "ids|timestamp|content",
            "rvslots": "main",
            "rvlimit": "1",
            "format": "json",
            "formatversion": "2",
        })
        return _revision_from_payload(payload, pageid, title)


def _retry_delay(attempt: int, retry_after: str | None) -> float:
    if retry_after:
        try:
            return min(max(float(retry_after), 0.0), 30.0)
        except ValueError:
            pass
    return min(2.0**attempt, 30.0)


def _write_atomic(path: Path, content: bytes | str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{time.time_ns()}.tmp")
    try:
        if isinstance(content, bytes):
            temporary.write_bytes(content)
        else:
            temporary.write_text(content, encoding="utf-8")
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()


def _read_previous_manifest(path: Path) -> dict[int, dict[str, Any]]:
    if not path.is_file():
        return {}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    pages = payload.get("pages") if isinstance(payload, Mapping) else None
    if not isinstance(pages, list):
        return {}
    result: dict[int, dict[str, Any]] = {}
    for page in pages:
        if isinstance(page, Mapping):
            try:
                result[int(page["pageid"])] = dict(page)
            except (KeyError, TypeError, ValueError):
                continue
    return result


def download_snapshot(
    client: MediaWikiClient,
    output_dir: Path,
    *,
    category: str = DEFAULT_CATEGORY,
    site: str = DEFAULT_SITE,
    license_name: str = "CC BY-SA 4.0",
) -> SnapshotManifest:
    """Download all pinned revisions and atomically publish ``manifest.json``."""

    output_dir = Path(output_dir)
    manifest_path = output_dir / "manifest.json"
    previous = _read_previous_manifest(manifest_path)
    pages = client.category_pages(category)
    batch_revisions = client.category_revisions(category) if hasattr(client, "category_revisions") else {}
    descriptors: list[PageDescriptor] = []
    for pageid, title in pages:
        revision_value = batch_revisions.get(pageid)
        revision, timestamp, content = revision_value if revision_value is not None else client.latest_revision(pageid, title)
        digest = _sha256_bytes(content)
        snapshot_file = f"pages/{pageid}-{revision}.wikitext"
        snapshot_path = output_dir / snapshot_file
        previous_page = previous.get(pageid)
        reusable = (
            previous_page is not None
            and int(previous_page.get("revision", -1)) == revision
            and str(previous_page.get("snapshot_file", "")) == snapshot_file
            and str(previous_page.get("snapshot_sha256", "")) == digest
            and snapshot_path.is_file()
            and _sha256_bytes(snapshot_path.read_bytes()) == digest
        )
        if not reusable:
            _write_atomic(snapshot_path, content)
        descriptors.append(PageDescriptor(
            pageid=pageid,
            title=title,
            canonical_url=_canonical_url(title),
            revision=revision,
            revision_timestamp=timestamp,
            snapshot_file=snapshot_file,
            snapshot_sha256=digest,
        ))
    manifest = SnapshotManifest(
        schema_version=1,
        site=site,
        category=category,
        license=license_name,
        discovered_at=datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        pages=tuple(sorted(descriptors, key=lambda item: item.pageid)),
    )
    encoded = json.dumps(manifest.to_dict(), ensure_ascii=False, sort_keys=True, indent=2) + "\n"
    _write_atomic(manifest_path, encoded)
    return manifest


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--category", default=DEFAULT_CATEGORY)
    parser.add_argument("--api-url", default=DEFAULT_API_URL)
    parser.add_argument("--user-agent", default=DEFAULT_USER_AGENT)
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--max-retries", type=int, default=4)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    manifest = download_snapshot(
        MediaWikiClient(
            args.api_url,
            user_agent=args.user_agent,
            timeout=args.timeout,
            max_retries=args.max_retries,
        ),
        args.output_dir,
        category=args.category,
    )
    print(json.dumps(manifest.to_dict(), ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
