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
    'zh-Hans': PROJECT_ROOT / 'scripts/i18n/zh-Hans-CN.json',
    'zh-Hant': PROJECT_ROOT / 'scripts/i18n/zh-Hant-TW.json',
    'es': PROJECT_ROOT / 'scripts/i18n/es-ES.json',
    'ja': PROJECT_ROOT / 'scripts/i18n/ja-JP.json',
}
REQUIRED_LOCALE_CODES = ('es', 'ja', 'zh-Hans', 'zh-Hant')
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
):
    return {
        locale_code: i18n_sql.build_translation_rows(
            locale_code,
            locale_snapshot.translations,
            snapshot.source_map,
            expression_id_fn=expression_id_fn,
            stable_edge_id_fn=stable_edge_id_fn,
        )
        for locale_code, locale_snapshot in snapshot.locales.items()
    }


def validate_deterministic_ids(source_map, rows_by_locale) -> None:
    expression_registry: dict[int, tuple[str, str]] = {}
    edge_registry: dict[str, tuple[int, int]] = {}

    for key in sorted(source_map.keys()):
        expr_id = i18n_sql.expression_id(i18n_sql.SOURCE_LANGUAGE_CODE, source_map[key])
        payload = (i18n_sql.SOURCE_LANGUAGE_CODE, source_map[key])
        existing = expression_registry.get(expr_id)
        if existing is not None and existing != payload:
            raise ValueError(
                f'expression_id collision for source key {key}: {expr_id} maps to {existing!r} and {payload!r}'
            )
        expression_registry[expr_id] = payload

    for locale_code in sorted(rows_by_locale.keys()):
        for row in rows_by_locale[locale_code]:
            for expr_id, payload, label in (
                (row.source_expression_id, (i18n_sql.SOURCE_LANGUAGE_CODE, row.source_text), f'source {row.key}'),
                (row.target_expression_id, (locale_code, row.translation_text), f'target {locale_code}:{row.key}'),
            ):
                existing = expression_registry.get(expr_id)
                if existing is not None and existing != payload:
                    raise ValueError(
                        f'expression_id collision for {label}: {expr_id} maps to {existing!r} and {payload!r}'
                    )
                expression_registry[expr_id] = payload

            edge_payload = (min(row.source_expression_id, row.target_expression_id), max(row.source_expression_id, row.target_expression_id))
            existing_edge = edge_registry.get(row.edge_id)
            if existing_edge is not None and existing_edge != edge_payload:
                raise ValueError(
                    f'edge_id collision for {locale_code}:{row.key}: {row.edge_id} maps to {existing_edge!r} and {edge_payload!r}'
                )
            edge_registry[row.edge_id] = edge_payload


def render_bundle_sql(source_map, rows_by_locale) -> str:
    lines: list[str] = []
    lines.append('-- Generated managed system UI translation bundle')
    lines.append(f'-- Project: {i18n_sql.PROJECT_ID}')
    lines.append(f'-- Ownership scope: {OWNERSHIP_SCOPE}')
    lines.append('')
    lines.append('-- 1. Upsert locale metadata')
    for locale_code in sorted(rows_by_locale.keys()):
        lines.append(f'-- Locale {locale_code}')
        lines.append(
            f"""
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT '{i18n_sql.PROJECT_ID}', '{locale_code}', l.name, l.direction, 'active'
FROM languages l WHERE l.code = '{locale_code}'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;
""".strip()
        )
        lines.append('')

    lines.append(f'-- 2. Source messages ({len(source_map)} keys)')
    for key in sorted(source_map.keys()):
        source_text = source_map[key]
        source_expression_id = i18n_sql.expression_id(i18n_sql.SOURCE_LANGUAGE_CODE, source_text)
        source_ref = f'{i18n_sql.PROJECT_ID}:{key}'
        lines.append(
            f"""
-- {key}
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES ({source_expression_id}, '{i18n_sql.q(source_text)}', '{i18n_sql.SOURCE_LANGUAGE_CODE}', 'ui_i18n', '{source_ref}', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('{i18n_sql.PROJECT_ID}', '{key}', {source_expression_id}, '[]', '{source_expression_id}', 'active');
""".strip()
        )
        lines.append('')

    translation_count = sum(len(rows) for rows in rows_by_locale.values())
    lines.append(f'-- 3. Translation expressions and edges ({translation_count} rows)')
    for locale_code in sorted(rows_by_locale.keys()):
        lines.append(f'-- Locale {locale_code}')
        for row in rows_by_locale[locale_code]:
            lines.append(
                f"""
-- {row.key}
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES ({row.target_expression_id}, '{i18n_sql.q(row.translation_text)}', '{locale_code}', 'ui_i18n', '{row.source_ref}', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('{row.edge_id}', {row.source_expression_id}, {row.target_expression_id}, 0, 'ui_i18n');
""".strip()
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
) -> dict:
    return {
        'schema_version': SCHEMA_VERSION,
        'project_id': i18n_sql.PROJECT_ID,
        'ownership_scope': OWNERSHIP_SCOPE,
        'locale_codes': list(snapshot.locales.keys()),
        'counts': {
            'locale_count': len(snapshot.locales),
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
            }
        },
    }


def stage_artifacts(output_dir: Path, sql_text: str, manifest: dict) -> tuple[Path, Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    staging_dir = Path(tempfile.mkdtemp(prefix='system-ui-bundle.', dir=output_dir.parent))
    sql_path = staging_dir / 'system-ui.sql'
    manifest_path = staging_dir / 'manifest.json'
    sql_path.write_text(sql_text, encoding='utf-8')
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    return staging_dir, sql_path, manifest_path


def replace_artifacts(
    output_dir: Path,
    staged_sql_path: Path,
    staged_manifest_path: Path,
    *,
    copy_fn=shutil.copy2,
    replace_fn=None,
    rollback_replace_fn=None,
) -> None:
    forward_replace = replace_fn or (lambda src, dst: Path(src).replace(dst))
    rollback_replace = rollback_replace_fn or (lambda src, dst: Path(src).replace(dst))
    targets = {
        output_dir / 'system-ui.sql': staged_sql_path,
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
    validate_deterministic_ids(snapshot.source_map, rows_by_locale)
    sql_text = render_bundle_sql(snapshot.source_map, rows_by_locale)
    manifest = build_manifest(
        snapshot=snapshot,
        source_map=snapshot.source_map,
        rows_by_locale=rows_by_locale,
        sql_text=sql_text,
    )
    staging_dir, staged_sql_path, staged_manifest_path = stage_artifacts(output_dir, sql_text, manifest)
    try:
        replace_artifacts(output_dir, staged_sql_path, staged_manifest_path)
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
