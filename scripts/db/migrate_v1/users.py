from __future__ import annotations


def migrate_users(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    result: list[dict[str, object]] = []
    for row in rows:
        created_at = row.get('created_at') or 'CURRENT_TIMESTAMP'
        result.append({
            'id': row['id'],
            'username': row['username'],
            'email': row['email'],
            'password_hash': row['password_hash'],
            'role': row.get('role') if row.get('role') in ('admin', 'user') else 'user',
            'email_verified': int(row.get('email_verified') or 0),
            'created_at': created_at,
            'updated_at': row.get('updated_at') or created_at,
        })
    return result
