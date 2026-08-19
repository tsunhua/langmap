from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys

if __package__ in (None, ''):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from scripts.db.migrate_v1.expressions import migrate_expressions
from scripts.db.migrate_v1.generate_sql import generate_sql_files
from scripts.db.migrate_v1.handbooks import migrate_handbooks
from scripts.db.migrate_v1.mappings import migrate_mappings
from scripts.db.migrate_v1.parse_sql import load_table
from scripts.db.migrate_v1.users import migrate_users


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description='Generate v1 to v2 migration SQL.')
    parser.add_argument('--source', choices=('fixtures', 'remote'), default='fixtures')
    parser.add_argument('--source-dir', type=Path, default=None)
    parser.add_argument('--output-dir', type=Path, required=True)
    parser.add_argument('--apply-local', action='store_true')
    parser.add_argument('--apply-remote', action='store_true')
    parser.add_argument('--database-name', default=None)
    parser.add_argument('--confirm-production', default=None)
    return parser


def run(source_dir: Path, output_dir: Path) -> dict[str, object]:
    users = load_table((source_dir / 'remote-users.sql').read_text(encoding='utf-8'), 'users')
    expressions = load_table((source_dir / 'remote-expressions.sql').read_text(encoding='utf-8'), 'expressions')
    expression_meanings = load_table((source_dir / 'remote-expression_meaning.sql').read_text(encoding='utf-8'), 'expression_meaning')
    handbooks = load_table((source_dir / 'remote-handbooks.sql').read_text(encoding='utf-8'), 'handbooks')
    pages = load_table((source_dir / 'remote-handbook_pages.sql').read_text(encoding='utf-8'), 'handbook_pages')
    migrated_users = migrate_users(users)
    users_by_name = {str(row['username']): int(row['id']) for row in migrated_users}
    expression_result = migrate_expressions(expressions, users_by_name)
    mappings = migrate_mappings(expression_meanings, expression_result['expression_map'])
    handbook_result = migrate_handbooks(handbooks, pages, expression_result['expression_map'], {int(value): int(value) for value in users_by_name.values()})
    for row in expression_result['expressions'] + expression_result['attestations'] + expression_result['readings']:
        row['source_id'] = 'v1-migration'
    report = {
        **expression_result['report'],
        **handbook_result['report'],
        'source_counts': {'users': len(users), 'expressions': len(expressions), 'handbooks': len(handbooks), 'handbook_pages': len(pages)},
        'output_counts': {'users': len(migrated_users), 'expressions': len(expression_result['expressions']), 'attestations': len(expression_result['attestations']), 'readings': len(expression_result['readings']), 'mappings': len(mappings), 'handbooks': len(handbook_result['handbooks']), 'sections': len(handbook_result['sections']), 'items': len(handbook_result['items'])},
    }
    generate_sql_files({**expression_result, **handbook_result, 'mappings': mappings, 'users': migrated_users, 'report': report}, output_dir)
    return report


def apply_sql(output_dir: Path, *, remote: bool, database_name: str | None = None) -> None:
    if remote and not database_name:
        raise SystemExit('--apply-remote requires --database-name')
    if remote:
        files = ['users.sql', 'sources.sql', 'expressions.sql', 'attestations.sql', 'readings.sql', 'mappings.sql', 'handbooks.sql', 'sections.sql', 'items.sql']
    else:
        files = ['users.sql', 'sources.sql', 'expressions.sql', 'attestations.sql', 'readings.sql', 'mappings.sql', 'handbooks.sql', 'sections.sql', 'items.sql']
    wrangler = Path(__file__).resolve().parents[3] / 'backend' / 'node_modules' / '.bin' / 'wrangler'
    if not wrangler.exists():
        raise SystemExit(f'wrangler not found: {wrangler}')
    for filename in (['languages_seed.sql'] + files):
        for chunk_file in sorted(output_dir.glob(f'{filename[:-4]}*.sql')):
            command = [str(wrangler), 'd1', 'execute', database_name or 'DB']
            command.append('--remote' if remote else '--local')
            command.extend(['--file', str(chunk_file)])
            subprocess.run(command, cwd=wrangler.parents[2], check=True)


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    source_dir = args.source_dir or Path(__file__).resolve().parents[3] / 'scripts' / 'v2'
    if args.source == 'remote' and args.source_dir is None:
        raise SystemExit('--source remote requires --source-dir')
    report = run(source_dir, args.output_dir)
    print(json.dumps(report, ensure_ascii=False))
    if args.apply_remote:
        if args.confirm_production != 'I_UNDERSTAND_PRODUCTION_MIGRATION':
            raise SystemExit('--apply-remote requires --confirm-production I_UNDERSTAND_PRODUCTION_MIGRATION')
        apply_sql(args.output_dir, remote=True, database_name=args.database_name)
    elif args.apply_local:
        apply_sql(args.output_dir, remote=False)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
