#!/usr/bin/env python3
"""Generate the managed system UI translation bundle."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import importlib.util
import json
import shutil
import sys
import tempfile
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE_CATALOG = PROJECT_ROOT / 'web/src/locales/en.ts'
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / 'scripts/i18n/artifacts/system-ui'
DEFAULT_LOCALE_PATHS = {
    'cmn-Hans-CN': PROJECT_ROOT / 'scripts/i18n/cmn-Hans-CN.json',
    'cmn-Hant-TW': PROJECT_ROOT / 'scripts/i18n/cmn-Hant-TW.json',
    'spa-Latn-ES': PROJECT_ROOT / 'scripts/i18n/spa-Latn-ES.json',
    'jpn-Jpan-JP': PROJECT_ROOT / 'scripts/i18n/jpn-Jpan-JP.json',
}
REQUIRED_LOCALE_CODES = ('cmn-Hans-CN', 'cmn-Hant-TW', 'spa-Latn-ES', 'jpn-Jpan-JP')
SCHEMA_VERSION = 1
OWNERSHIP_SCOPE = 'managed-system-ui'


def _load_i18n_sql_module():
    module_path = Path(__file__).with_name('generate-i18n-sql.py')
    spec = importlib.util.spec_from_file_location('generate_i18n_sql', module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f'unable to load {module_path}')
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


i18n_sql = _load_i18n_sql_module()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


@dataclass(frozen=True)
class LocaleSnapshot:
    path: Path
    raw_bytes: bytes
    translations: dict[str, str]


@dataclass(frozen=True)
class BundleSnapshot:
    source_catalog_path: Path
    source_catalog_bytes: bytes
    source_map: dict[str, str]
    locales: dict[str, LocaleSnapshot]


def normalize_locale_paths(locale_paths: dict[str, Path]) -> dict[str, Path]:
    normalized = {code: Path(path).resolve() for code, path in locale_paths.items()}
    expected = set(REQUIRED_LOCALE_CODES)
    actual = set(normalized.keys())
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if missing or extra:
        problems: list[str] = []
        if missing:
            problems.append(f'missing locale(s): {", ".join(missing)}')
        if extra:
            problems.append(f'unexpected locale(s): {", ".join(extra)}')
        raise ValueError(
            f'bundle locale set must be exactly {", ".join(REQUIRED_LOCALE_CODES)}; '
            + '; '.join(problems)
        )
    return {code: normalized[code] for code in REQUIRED_LOCALE_CODES}


def load_bundle_snapshot(
    source_catalog_path: Path,
    locale_paths: dict[str, Path],
    *,
    read_bytes_fn=None,
) -> BundleSnapshot:
    reader = read_bytes_fn or Path.read_bytes
    normalized_locale_paths = normalize_locale_paths(locale_paths)
    source_catalog_path = Path(source_catalog_path).resolve()
    source_catalog_bytes = reader(source_catalog_path)
    source_map = i18n_sql.parse_en_ts_bytes(source_catalog_bytes)
    locales: dict[str, LocaleSnapshot] = {}
    for locale_code, path in normalized_locale_paths.items():
        locale_bytes = reader(path)
        locales[locale_code] = LocaleSnapshot(
            path=path,
            raw_bytes=locale_bytes,
            translations=i18n_sql.load_translations_bytes(locale_bytes),
        )
    return BundleSnapshot(
        source_catalog_path=source_catalog_path,
        source_catalog_bytes=source_catalog_bytes,
        source_map=source_map,
        locales=locales,
    )


def build_rows_by_locale(
    snapshot: BundleSnapshot,
    *,
    expression_id_fn=i18n_sql.expression_id,
    stable_edge_id_fn=i18n_sql.stable_edge_id,
    stable_attestation_id_fn=i18n_sql.stable_attestation_id,
):
    return {
        locale_code: i18n_sql.build_translation_rows(
            locale_code,
            locale_snapshot.translations,
            snapshot.source_map,
            expression_id_fn=expression_id_fn,
            stable_edge_id_fn=stable_edge_id_fn,
            stable_attestation_id_fn=stable_attestation_id_fn,
        )
        for locale_code, locale_snapshot in snapshot.locales.items()
    }


def build_clique_edges(source_map, rows_by_locale, *, stable_edge_id_fn=i18n_sql.stable_edge_id) -> dict[str, list[tuple[str, str, str]]]:
    """Per-key clique edges, matching runtime createEdgesBatch semantics.

    For each key, collect the source expression plus every locale target
    expression, then emit one edge for each unordered pair (the full clique),
    so translations connect to each other — not only to the English source.
    Returns {key: [(edge_id, lo, hi), ...]} with lo < hi (string order).
    """
    key_ids: dict[str, set[str]] = {}
    for key, source_text in source_map.items():
        key_ids.setdefault(key, set()).add(
            i18n_sql.expression_id(i18n_sql.SOURCE_LANG_CODE, source_text)
        )
    for rows in rows_by_locale.values():
        for row in rows:
            key_ids.setdefault(row.key, set()).add(row.target_expression_id)

    cliques: dict[str, list[tuple[str, str, str]]] = {}
    for key in sorted(key_ids):
        ordered = sorted(key_ids[key])
        cliques[key] = [
            (stable_edge_id_fn(a, b), a, b)
            for i, a in enumerate(ordered)
            for b in ordered[i + 1:]
        ]
    return cliques


def validate_deterministic_ids(source_map, rows_by_locale, *, stable_edge_id_fn=i18n_sql.stable_edge_id) -> None:
    # expression_id (string) -> (lang_code, canonical_text). The same id mapping
    # to the same payload (shared translation text) is NOT a collision; only
    # same id → different payload is.
    expression_registry: dict[str, tuple[str, str]] = {}
    edge_registry: dict[str, tuple[str, str]] = {}

    for key in sorted(source_map.keys()):
        expr_id = i18n_sql.expression_id(i18n_sql.SOURCE_LANG_CODE, source_map[key])
        payload = (i18n_sql.SOURCE_LANG_CODE, i18n_sql.canonicalize_expression_text(source_map[key]))
        existing = expression_registry.get(expr_id)
        if existing is not None and existing != payload:
            raise ValueError(
                f'expression_id collision for source key {key}: {expr_id} maps to {existing!r} and {payload!r}'
            )
        expression_registry[expr_id] = payload

    for locale_code in sorted(rows_by_locale.keys()):
        for row in rows_by_locale[locale_code]:
            for expr_id, payload, label in (
                (row.source_expression_id, (i18n_sql.SOURCE_LANG_CODE, row.source_text), f'source {row.key}'),
                (row.target_expression_id, (row.lang_code, row.translation_text), f'target {locale_code}:{row.key}'),
            ):
                existing = expression_registry.get(expr_id)
                if existing is not None and existing != payload:
                    raise ValueError(
                        f'expression_id collision for {label}: {expr_id} maps to {existing!r} and {payload!r}'
                    )
                expression_registry[expr_id] = payload

    # Clique edges (including the source↔target edges the rows reference): an
    # edge_id must map to a unique canonical (lo, hi) pair.
    for key, edges in build_clique_edges(source_map, rows_by_locale, stable_edge_id_fn=stable_edge_id_fn).items():
        for edge_id, lo, hi in edges:
            existing_edge = edge_registry.get(edge_id)
            if existing_edge is not None and existing_edge != (lo, hi):
                raise ValueError(
                    f'edge_id collision for {key}: {edge_id} maps to {existing_edge!r} and {(lo, hi)!r}'
                )
            edge_registry[edge_id] = (lo, hi)


def render_bundle_sql(source_map, rows_by_locale, *, stable_edge_id_fn=i18n_sql.stable_edge_id) -> str:
    return render_canonical_bundle_sql(source_map, rows_by_locale)


def render_canonical_bundle_sql(source_map, rows_by_locale) -> str:
    """Render against the canonical integer-ID schema.

    IDs are deliberately resolved in SQL through the natural keys.  This keeps
    the artifact deterministic while allowing SQLite to allocate compact IDs.
    """
    return render_compact_canonical_bundle_sql(source_map, rows_by_locale)


def render_compact_canonical_bundle_sql(source_map, rows_by_locale) -> str:
    """Seed UI source and translation expressions in set-based SQL."""
    lines: list[str] = [
        '-- AUTO-GENERATED by scripts/i18n/generate-bundle.py. Do not edit.',
        f'-- Project: {i18n_sql.PROJECT_ID}',
        "INSERT OR IGNORE INTO sources(type, name) VALUES ('system', 'system-ui');",
        '',
    ]
    managed_locale_codes = sorted({i18n_sql.SOURCE_LANGUAGE_CODE, *rows_by_locale.keys()})
    locale_values = ', '.join(f"'{code}'" for code in managed_locale_codes)
    lines.append(
        "INSERT OR IGNORE INTO ui_locales(project_id, locale_id, status, mapping_revision, activation_source, activated_at) "
        f"SELECT '{i18n_sql.PROJECT_ID}', ll.id, 'active', 0, 'system', CURRENT_TIMESTAMP FROM language_locales ll WHERE ll.code IN ({locale_values});"
    )
    values: list[str] = []
    for key in sorted(source_map):
        text = i18n_sql.canonicalize_expression_text(source_map[key])
        placeholders = json.dumps(i18n_sql.extract_placeholders(text))
        values.append(f"('{i18n_sql.q(key)}', '{i18n_sql.q(text)}', '{i18n_sql.q(placeholders)}')")
    rows = ',\n  '.join(values)
    seed_cte = f'WITH system_ui_seed(message_key, source_text, placeholders_json) AS (VALUES\n  {rows}\n) '
    lines.extend([
        seed_cte + "INSERT OR IGNORE INTO expressions(language_id, text, source_id) SELECT l.id, s.source_text, src.id FROM system_ui_seed s JOIN languages l ON l.code='eng' JOIN sources src ON src.type='system' AND src.name='system-ui';",
        seed_cte + "INSERT OR IGNORE INTO ui_messages(project_id, message_key, source_expression_id, source_text, placeholders_json, status) SELECT 'langmap-web', s.message_key, e.id, s.source_text, s.placeholders_json, 'active' FROM system_ui_seed s JOIN languages l ON l.code='eng' JOIN expressions e ON e.language_id=l.id AND e.text=s.source_text AND e.homograph_index=1;",
    ])
    translation_values: list[str] = []
    for locale_code in sorted(rows_by_locale):
        for row in rows_by_locale[locale_code]:
            translation_values.append(
                f"('{locale_code}', '{row.lang_code}', '{i18n_sql.q(row.key)}', '{i18n_sql.q(row.translation_text)}')"
            )
    # Keep each statement below D1's SQL-size limit while still applying each
    # chunk as set operations rather than one query per translated phrase.
    for start in range(0, len(translation_values), 100):
        translations = ',\n  '.join(translation_values[start:start + 100])
        translation_cte = f'WITH ui_translation_seed(locale_code, lang_code, message_key, text) AS (VALUES\n  {translations}\n) '
        lines.extend([
            translation_cte + "INSERT OR IGNORE INTO expressions(language_id, text, source_id) SELECT l.id, t.text, src.id FROM ui_translation_seed t JOIN languages l ON l.code=t.lang_code JOIN sources src ON src.type='system' AND src.name='system-ui';",
            translation_cte + "INSERT OR IGNORE INTO expression_locale_links(expression_id, locale_id) SELECT e.id, ll.id FROM ui_translation_seed t JOIN languages l ON l.code=t.lang_code JOIN expressions e ON e.language_id=l.id AND e.text=t.text AND e.homograph_index=1 JOIN language_locales ll ON ll.code=t.locale_code;",
        ])
    lines.append('-- Done')
    return '\n'.join(lines)


def render_ui_edge_sql_chunks(rows_by_locale) -> list[str]:
    """Render bounded D1 artifacts for direct source-to-translation edges."""
    header = [
        '-- AUTO-GENERATED by scripts/i18n/generate-bundle.py. Do not edit.',
        f'-- Project: {i18n_sql.PROJECT_ID}; direct UI translation semantic edges.',
    ]
    statements: list[str] = []
    translation_values: list[str] = []
    for locale_code in sorted(rows_by_locale):
        for row in rows_by_locale[locale_code]:
            translation_values.append(
                f"('{locale_code}', '{row.lang_code}', '{i18n_sql.q(row.key)}', '{i18n_sql.q(row.translation_text)}')"
            )

    # UI message keys define the semantic correspondence. Materialize direct
    # source→translation edges without retaining another mapping table.
    for start in range(0, len(translation_values), 5):
        translations = ',\n  '.join(translation_values[start:start + 5])
        translation_cte = f'WITH ui_translation_seed(locale_code, lang_code, message_key, text) AS (VALUES\n  {translations}\n) '
        statements.append(
            translation_cte
            + "INSERT OR IGNORE INTO expression_edges(expression_a_id, expression_b_id, relation_mask) "
            "SELECT CASE WHEN m.source_expression_id < e.id THEN m.source_expression_id ELSE e.id END, "
            "CASE WHEN m.source_expression_id < e.id THEN e.id ELSE m.source_expression_id END, 1 "
            "FROM ui_translation_seed t JOIN ui_messages m ON m.project_id='langmap-web' AND m.message_key=t.message_key "
            "JOIN languages l ON l.code=t.lang_code "
            "JOIN expressions e ON e.language_id=l.id AND e.text=t.text AND e.homograph_index=1 "
            "WHERE m.source_expression_id<>e.id;"
        )
    statements_per_file = 60
    return [
        '\n'.join([*header, *statements[start:start + statements_per_file], '-- Done'])
        for start in range(0, len(statements), statements_per_file)
    ]

    # Legacy string-ID renderer retained below temporarily for fixture
    # comparison; it is unreachable for the canonical schema.
    lines: list[str] = []
    lines.append('-- AUTO-GENERATED by scripts/i18n/generate-bundle.py. Do not edit.')
    lines.append(f'-- Project: {i18n_sql.PROJECT_ID}')
    lines.append(f'-- Ownership scope: {OWNERSHIP_SCOPE}')
    lines.append('')

    # 1. Activate the managed UI locales (FK → language_locales; must already
    #    be seeded in schema.sql). INSERT OR IGNORE is idempotent on re-import.
    managed_locale_codes = sorted({i18n_sql.SOURCE_LANGUAGE_CODE, *rows_by_locale.keys()})
    lines.append(f'-- 1. Activate UI locales ({len(managed_locale_codes)} locales)')
    for locale_code in managed_locale_codes:
        lines.append(
            "INSERT OR IGNORE INTO ui_locales "
            "(project_id, language_locale_code, status, mapping_revision, activation_source, activated_at) "
            f"VALUES ('{i18n_sql.PROJECT_ID}', '{locale_code}', 'active', 0, 'system', CURRENT_TIMESTAMP);"
        )
    lines.append('')

    # 2. Source (English) expressions + ui_messages. Columns/values mirror
    #    generate-ui-seed.py so source ids are stable and match runtime.
    lines.append(f'-- 2. Source messages ({len(source_map)} keys)')
    for key in sorted(source_map.keys()):
        source_text = i18n_sql.canonicalize_expression_text(source_map[key])
        source_hash = i18n_sql.compute_text_hash(source_text)
        source_expression_id = i18n_sql.build_expression_id(i18n_sql.SOURCE_LANG_CODE, source_hash)
        placeholders = json.dumps(i18n_sql.extract_placeholders(source_text))
        source_ref = f'ui:{i18n_sql.PROJECT_ID}:{key}:1'
        lines.append(
            f"""
-- {key}
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by)
VALUES ('{source_expression_id}', '{i18n_sql.SOURCE_LANG_CODE}', '{i18n_sql.q(source_text)}', '{source_hash}', 1, '', '[]', '{i18n_sql.SOURCE_ID}', '{source_ref}', 'approved', NULL);

INSERT OR IGNORE INTO ui_messages (project_id, message_key, source_expression_id, source_text, placeholders_json, status)
VALUES ('{i18n_sql.PROJECT_ID}', '{key}', '{source_expression_id}', '{i18n_sql.q(source_text)}', '{i18n_sql.q(placeholders)}', 'active');
""".strip()
        )
        lines.append('')

    # 3. Per locale: target expressions → attestations. FK-safe: expressions
    #    before attestations. (Edges follow in section 4.)
    translation_count = sum(len(rows) for rows in rows_by_locale.values())
    lines.append(f'-- 3. Translation expressions and attestations ({translation_count} rows)')
    for locale_code in sorted(rows_by_locale.keys()):
        lines.append(f'-- Locale {locale_code}')
        for row in rows_by_locale[locale_code]:
            target_hash = i18n_sql.compute_text_hash(row.translation_text)
            lines.append(
                f"""
-- {row.key}
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by)
VALUES ('{row.target_expression_id}', '{row.lang_code}', '{i18n_sql.q(row.translation_text)}', '{target_hash}', 1, '', '[]', '{i18n_sql.SOURCE_ID}', '{i18n_sql.q(row.source_ref)}', 'approved', NULL);

INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by)
VALUES ('{row.attestation_id}', '{row.target_expression_id}', '{locale_code}', NULL, NULL, NULL);
""".strip()
            )
            lines.append('')

    # 4. Mapping edges as a per-key clique (source + every locale target, all
    #    unordered pairs), matching runtime createEdgesBatch so translations
    #    connect to each other — not only to the English source.
    clique_edges = build_clique_edges(source_map, rows_by_locale, stable_edge_id_fn=stable_edge_id_fn)
    edge_total = sum(len(edges) for edges in clique_edges.values())
    lines.append(f'-- 4. Translation mapping edges ({edge_total} clique edges)')
    for key in sorted(clique_edges.keys()):
        lines.append(f'-- Clique: {key}')
        for edge_id, lo, hi in clique_edges[key]:
            lines.append(
                f"INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) "
                f"VALUES ('{edge_id}', '{lo}', '{hi}', 0, 'translation', NULL);"
            )
        lines.append('')

    lines.append('-- Done')
    return '\n'.join(lines)


def build_manifest(
    *,
    snapshot: BundleSnapshot,
    source_map,
    rows_by_locale,
    sql_text: str,
    edge_sql_texts: list[str],
) -> dict:
    return {
        'schema_version': SCHEMA_VERSION,
        'project_id': i18n_sql.PROJECT_ID,
        'ownership_scope': OWNERSHIP_SCOPE,
        'locale_codes': sorted({i18n_sql.SOURCE_LANGUAGE_CODE, *snapshot.locales.keys()}),
        'counts': {
            'locale_count': len(snapshot.locales) + 1,
            'message_count': len(source_map),
            'translation_count': sum(len(rows) for rows in rows_by_locale.values()),
        },
        'inputs': {
            'source_catalog': {
                'path': str(snapshot.source_catalog_path),
                'sha256': sha256_bytes(snapshot.source_catalog_bytes),
            },
            'locales': {
                locale_code: {
                    'path': str(locale_snapshot.path),
                    'sha256': sha256_bytes(locale_snapshot.raw_bytes),
                }
                for locale_code, locale_snapshot in snapshot.locales.items()
            },
        },
        'artifacts': {
            'system_ui_sql': {
                'path': 'system-ui.sql',
                'sha256': sha256_text(sql_text),
            },
            'system_ui_edges_sql': [
                {'path': f'system-ui-edges-{index:03d}.sql', 'sha256': sha256_text(text)}
                for index, text in enumerate(edge_sql_texts, start=1)
            ]
        },
    }


def stage_artifacts(output_dir: Path, sql_text: str, edge_sql_texts: list[str], manifest: dict) -> tuple[Path, dict[str, Path], Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    staging_dir = Path(tempfile.mkdtemp(prefix='system-ui-bundle.', dir=output_dir.parent))
    sql_path = staging_dir / 'system-ui.sql'
    manifest_path = staging_dir / 'manifest.json'
    sql_path.write_text(sql_text, encoding='utf-8')
    staged_sql_paths = {'system-ui.sql': sql_path}
    for index, edge_sql_text in enumerate(edge_sql_texts, start=1):
        filename = f'system-ui-edges-{index:03d}.sql'
        edge_sql_path = staging_dir / filename
        edge_sql_path.write_text(edge_sql_text, encoding='utf-8')
        staged_sql_paths[filename] = edge_sql_path
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    return staging_dir, staged_sql_paths, manifest_path


def replace_artifacts(
    output_dir: Path,
    staged_sql_paths: dict[str, Path] | Path,
    staged_manifest_path: Path,
    *,
    copy_fn=shutil.copy2,
    replace_fn=None,
    rollback_replace_fn=None,
) -> None:
    forward_replace = replace_fn or (lambda src, dst: Path(src).replace(dst))
    rollback_replace = rollback_replace_fn or (lambda src, dst: Path(src).replace(dst))
    if isinstance(staged_sql_paths, Path):
        staged_sql_paths = {'system-ui.sql': staged_sql_paths}
    targets = {
        **{output_dir / filename: staged_path for filename, staged_path in staged_sql_paths.items()},
        output_dir / 'manifest.json': staged_manifest_path,
    }
    backups: dict[Path, Path] = {}
    existed_before: dict[Path, bool] = {}
    replaced_targets: list[Path] = []
    try:
        for target in targets:
            existed_before[target] = target.exists()
            if target.exists():
                backup_path = target.with_suffix(target.suffix + '.bak')
                copy_fn(target, backup_path)
                backups[target] = backup_path
        for target, staged_path in targets.items():
            forward_replace(staged_path, target)
            replaced_targets.append(target)
    except Exception:
        for target in replaced_targets:
            backup_path = backups.get(target)
            if backup_path is not None and backup_path.exists():
                rollback_replace(backup_path, target)
            elif not existed_before.get(target, False) and target.exists():
                target.unlink()
        raise
    finally:
        for backup_path in backups.values():
            if backup_path.exists():
                backup_path.unlink()


def generate_bundle(
    *,
    source_catalog_path: Path,
    locale_paths: dict[str, Path],
    output_dir: Path,
    expression_id_fn=i18n_sql.expression_id,
    stable_edge_id_fn=i18n_sql.stable_edge_id,
    read_bytes_fn=None,
) -> dict:
    output_dir = Path(output_dir).resolve()
    snapshot = load_bundle_snapshot(
        source_catalog_path,
        locale_paths,
        read_bytes_fn=read_bytes_fn,
    )
    rows_by_locale = build_rows_by_locale(
        snapshot,
        expression_id_fn=expression_id_fn,
        stable_edge_id_fn=stable_edge_id_fn,
    )
    validate_deterministic_ids(snapshot.source_map, rows_by_locale, stable_edge_id_fn=stable_edge_id_fn)
    sql_text = render_bundle_sql(snapshot.source_map, rows_by_locale, stable_edge_id_fn=stable_edge_id_fn)
    edge_sql_texts = render_ui_edge_sql_chunks(rows_by_locale)
    manifest = build_manifest(
        snapshot=snapshot,
        source_map=snapshot.source_map,
        rows_by_locale=rows_by_locale,
        sql_text=sql_text,
        edge_sql_texts=edge_sql_texts,
    )
    staging_dir, staged_sql_paths, staged_manifest_path = stage_artifacts(output_dir, sql_text, edge_sql_texts, manifest)
    try:
        replace_artifacts(output_dir, staged_sql_paths, staged_manifest_path)
    finally:
        shutil.rmtree(staging_dir, ignore_errors=True)
    return manifest


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-catalog', type=Path, default=DEFAULT_SOURCE_CATALOG)
    parser.add_argument('--output-dir', type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument(
        '--locale',
        action='append',
        default=[],
        help='Override locale input as LOCALE_CODE=/path/to/file.json; may be passed multiple times.',
    )
    return parser.parse_args()


def parse_locale_args(items: list[str]) -> dict[str, Path]:
    if not items:
        return DEFAULT_LOCALE_PATHS
    locale_paths: dict[str, Path] = {}
    for item in items:
        if '=' not in item:
            raise ValueError(f'invalid --locale value "{item}": expected LOCALE_CODE=/path/to/file.json')
        locale_code, raw_path = item.split('=', 1)
        if locale_code in locale_paths:
            raise ValueError(f'duplicate locale override: {locale_code}')
        locale_paths[locale_code] = Path(raw_path)
    return locale_paths


def main() -> int:
    try:
        args = parse_args()
        manifest = generate_bundle(
            source_catalog_path=args.source_catalog,
            locale_paths=parse_locale_args(args.locale),
            output_dir=args.output_dir,
        )
    except (OSError, ValueError) as exc:
        print(f'i18n-bundle: {exc}', file=sys.stderr)
        return 1

    print(json.dumps(manifest, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
