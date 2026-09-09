"""Validated page and section profiles for the Wikivoyage importer."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable, Mapping


VALID_PAGE_STATES = frozenset({"included", "empty", "excluded", "blocked", "quarantined"})


@dataclass(frozen=True)
class PageProfile:
    pageid: int
    title: str
    lang_code: str | None
    locale_codes: tuple[str, ...] = ()
    reading_schemes: tuple[str, ...] = ()
    status: str = "blocked"
    reason: str | None = None
    allow_tables: bool = False
    split_by_locale: bool = False
    target_first_infoboxes: tuple[str, ...] = ()


@dataclass(frozen=True)
class SectionProfile:
    key: str
    title: str
    position: int
    aliases: tuple[str, ...] = ()
    include: bool = True


@dataclass(frozen=True)
class SectionCatalog:
    sections: tuple[SectionProfile, ...]
    aliases: Mapping[str, str] = field(default_factory=dict)

    def ordered(self) -> tuple[SectionProfile, ...]:
        return tuple(sorted(self.sections, key=lambda item: (item.position, item.key)))


@dataclass(frozen=True)
class RegistryIssue:
    pageid: int
    title: str
    state: str
    reason: str
    lang_code: str | None = None
    locale_codes: tuple[str, ...] = ()


@dataclass(frozen=True)
class RegistryReport:
    pages: tuple[RegistryIssue, ...]

    @property
    def counts(self) -> dict[str, int]:
        result = {state: 0 for state in sorted(VALID_PAGE_STATES)}
        for page in self.pages:
            result[page.state] = result.get(page.state, 0) + 1
        return result

    def to_dict(self) -> dict[str, Any]:
        return {
            "counts": self.counts,
            "pages": [
                {
                    "pageid": page.pageid,
                    "title": page.title,
                    "state": page.state,
                    "reason": page.reason,
                    "lang_code": page.lang_code,
                    "locale_codes": list(page.locale_codes),
                }
                for page in self.pages
            ],
        }


def _read_json(path: Path) -> Mapping[str, Any]:
    value = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(value, Mapping):
        raise ValueError(f"catalog must be an object: {path}")
    return value


def load_page_catalog(path: Path) -> dict[int, PageProfile]:
    payload = _read_json(path)
    raw_pages = payload.get("pages")
    if not isinstance(raw_pages, Mapping):
        raise ValueError("page catalog pages must be an object")
    result: dict[int, PageProfile] = {}
    for raw_id, raw_profile in raw_pages.items():
        if not isinstance(raw_profile, Mapping):
            raise ValueError(f"page profile must be an object: {raw_id}")
        pageid = int(raw_profile.get("pageid", raw_id))
        title = str(raw_profile.get("title", "")).strip()
        if pageid <= 0 or not title:
            raise ValueError(f"page profile needs pageid/title: {raw_id}")
        status = str(raw_profile.get("status", "blocked"))
        if status not in VALID_PAGE_STATES:
            raise ValueError(f"invalid page state {status!r}: {pageid}")
        locales = tuple(str(value).strip() for value in raw_profile.get("locale_codes", ()))
        schemes = tuple(str(value).strip() for value in raw_profile.get("reading_schemes", ()))
        result[pageid] = PageProfile(
            pageid=pageid,
            title=title,
            lang_code=str(raw_profile["lang_code"]).strip() if raw_profile.get("lang_code") else None,
            locale_codes=tuple(value for value in locales if value),
            reading_schemes=tuple(value for value in schemes if value),
            status=status,
            reason=str(raw_profile["reason"]).strip() if raw_profile.get("reason") else None,
            allow_tables=bool(raw_profile.get("allow_tables", False)),
            split_by_locale=bool(raw_profile.get("split_by_locale", False)),
            target_first_infoboxes=tuple(
                str(value).strip()
                for value in raw_profile.get("target_first_infoboxes", ())
                if str(value).strip()
            ),
        )
    return result


def load_section_catalog(path: Path) -> SectionCatalog:
    payload = _read_json(path)
    raw_sections = payload.get("sections")
    if not isinstance(raw_sections, list):
        raise ValueError("section catalog sections must be an array")
    sections: list[SectionProfile] = []
    aliases: dict[str, str] = {}
    for raw in raw_sections:
        if not isinstance(raw, Mapping):
            raise ValueError("section profile must be an object")
        key = str(raw.get("key", "")).strip().lower()
        title = str(raw.get("title", "")).strip()
        if not key or not title:
            raise ValueError("section profile needs key/title")
        profile = SectionProfile(
            key=key,
            title=title,
            position=int(raw.get("position", len(sections) + 1)),
            aliases=tuple(str(value).strip() for value in raw.get("aliases", ()) if str(value).strip()),
            include=bool(raw.get("include", True)),
        )
        sections.append(profile)
        aliases[title.casefold()] = key
        aliases[key.casefold()] = key
        for alias in profile.aliases:
            aliases[alias.casefold()] = key
    if len({profile.key for profile in sections}) != len(sections):
        raise ValueError("duplicate section key")
    return SectionCatalog(tuple(sections), aliases)


def resolve_section(title: str, catalog: SectionCatalog) -> str | None:
    """Resolve only explicit titles/aliases; never use substring matching."""

    normalized = " ".join(str(title).split()).casefold()
    key = catalog.aliases.get(normalized)
    if key is None:
        return None
    profile = next((item for item in catalog.sections if item.key == key), None)
    return key if profile is not None and profile.include else None


def profile_for(pageid: int, title: str, catalog: Mapping[int, PageProfile]) -> PageProfile:
    profile = catalog.get(int(pageid))
    if profile is not None:
        return profile
    return PageProfile(
        pageid=int(pageid),
        title=title,
        lang_code=None,
        status="blocked",
        reason="missing_reviewed_page_profile",
    )


def validate_registry(
    connection: Any,
    discovered_pages: Iterable[tuple[int, str]],
    catalog: Mapping[int, PageProfile],
) -> RegistryReport:
    """Turn missing language/locale identities into explicit blocked states."""

    language_codes = {
        str(row[0])
        for row in connection.execute("SELECT code FROM languages")
    }
    locale_codes = {
        str(row[0])
        for row in connection.execute("SELECT code FROM language_locales")
    }
    rows: list[RegistryIssue] = []
    for pageid, title in sorted(discovered_pages, key=lambda item: item[0]):
        profile = profile_for(pageid, title, catalog)
        state = profile.status
        reason = profile.reason or ""
        if state == "included":
            missing: list[str] = []
            if not profile.lang_code or profile.lang_code not in language_codes:
                missing.append(f"language:{profile.lang_code or '<empty>'}")
            missing.extend(f"locale:{code}" for code in profile.locale_codes if code not in locale_codes)
            if missing:
                state = "blocked"
                reason = "missing_registry_identity:" + ",".join(missing)
        if state not in VALID_PAGE_STATES:
            state = "quarantined"
            reason = "invalid_catalog_state"
        rows.append(RegistryIssue(pageid, title, state, reason, profile.lang_code, profile.locale_codes))
    return RegistryReport(tuple(rows))


def write_registry_report(report: RegistryReport, path: Path) -> None:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_text(json.dumps(report.to_dict(), ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)

