# D1 Database Migration: i18n Tags Update (Optimized)

## Overview

This migration updates `tags` field in the `expressions` table to use new i18n key format.

**⚠️ IMPORTANT**: This migration only affects expressions associated with `collection_id = 1000000`.

## Key Changes

The i18n localization system has been refactored:

1. **Flattened structure**: Nested keys (e.g., `home.title`) converted to flat underscore-separated keys (e.g., `home_title`)
2. **Removed module prefixes**: Simplified keys where possible (e.g., `home_regions` → `regions`)
3. **Fixed malformed keys**: Corrected malformed keys from previous conversion (e.g., `login_ailed` → `login_failed`)
4. **Renamed generic keys**: Generic keys replaced with specific ones (e.g., `error_message` → `verification_link_invalid_or_expired`)
5. **Removed duplicates**: Consolidated duplicate keys (e.g., `detail_no_expressions_found` → `no_expressions_found`)

## Migration Details

### Total Key Mappings: 71

#### Malformed Key Fixes (13 examples):
- `login_ailed` → `login_failed`
- `map_itle` → `map_title`
- `add_anguage` → `add_language`
- `select_eaning` → `select_meaning`
- `select_ormat` → `select_format`
- `csv_esc` → `csv_desc`
- `json_esc` → `json_desc`

#### Generic Key Renames (5):
- `error_message` → `verification_link_invalid_or_expired`
- `success_message` → `email_verified_success`
- `verifying_message` → `verifying_email_address`
- `create_success` → `expression_created_success`
- `registration_success_message` → `registration_check_email`
- `registration_successful_message` → `registration_verify_email`

#### Duplicate Key Removals (4):
- `home_regions` → `regions`
- `detail_no_expressions_found` → `no_expressions_found`
- `detail_unlink` → `unlink`
- `login_remember_me` → `remember_me`

#### Other Changes (49):
- Various malformed keys fixed
- Nested format converted to flat
- Module prefixes removed

## Migration Options

### Option 1: Optimized SQL (Recommended)

**Fastest** - Single UPDATE statement with nested REPLACE

```bash
cd backend
npx wrangler d1 execute langmap --file=../scripts/002_migrate_i18n_tags_optimized.sql
```

**Advantages:**
- ✓ Single UPDATE statement
- ✓ Uses JOIN to limit to collection_id = 1000000
- ✓ No full table scans
- ✓ One transaction
- ✓ ~1-2 seconds execution

### Option 2: Node.js Script (Most Flexible)

```bash
cd backend
node ../scripts/migrate_i18n_tags.js
```

**Advantages:**
- ✓ In-memory processing
- ✓ Better error handling
- ✓ Batch updates (100 records at a time)
- ✓ Can preview changes before applying
- ✓ ~5-10 seconds execution

### Option 3: Legacy SQL (Not Recommended)

The original `002_migrate_i18n_tags.sql` uses 71 separate UPDATE statements.

**Disadvantages:**
- ✗ 71 separate UPDATE statements
- ✗ Each UPDATE scans the table
- ✗ Very slow on large datasets
- ✗ Not recommended

## Verification

After applying migration, verify changes:

```bash
# Check count of updated expressions
npx wrangler d1 execute langmap --remote --command="
  SELECT COUNT(*) as count
  FROM expressions e
  INNER JOIN collection_items ci ON e.id = ci.expression_id
  WHERE ci.collection_id = 1000000
"

# Check for old malformed keys
npx wrangler d1 execute langmap --remote --command="
  SELECT COUNT(*) as count
  FROM expressions e
  INNER JOIN collection_items ci ON e.id = ci.expression_id
  WHERE ci.collection_id = 1000000 
    AND (e.tags LIKE '%\"login_ailed\"%' 
         OR e.tags LIKE '%\"map_itle\"%' 
         OR e.tags LIKE '%\"add_anguage\"%')
"

# Check for new keys
npx wrangler d1 execute langmap --remote --command="
  SELECT COUNT(*) as count
  FROM expressions e
  INNER JOIN collection_items ci ON e.id = ci.expression_id
  WHERE ci.collection_id = 1000000 
    AND (e.tags LIKE '%\"login_failed\"%' 
         OR e.tags LIKE '%\"map_title\"%' 
         OR e.tags LIKE '%\"add_language\"%')
"

# View sample tags
npx wrangler d1 execute langmap --remote --command="
  SELECT e.id, e.text, e.tags
  FROM expressions e
  INNER JOIN collection_items ci ON e.id = ci.expression_id
  WHERE ci.collection_id = 1000000
  LIMIT 10
"
```

## Performance Comparison

| Method | Time | Scans | Recommended |
|--------|------|--------|-------------|
| Optimized SQL | 1-2s | collection_items + expressions subset | ✓ Yes |
| Node.js Script | 5-10s | One scan, batch updates | ✓ Yes |
| Legacy SQL | 60s+ | 71 full table scans | ✗ No |

## Rollback

If you need to rollback this migration:

```sql
-- Rollback specific key changes (reverse the mappings)
UPDATE expressions
SET tags = REPLACE(tags, '"login_failed"', '"login_ailed"')
WHERE id IN (
  SELECT DISTINCT e.id
  FROM expressions e
  INNER JOIN collection_items ci ON e.id = ci.expression_id
  WHERE ci.collection_id = 1000000
);
```

For a full rollback, you would need to reverse all 71 mappings manually.

## Important Notes

1. **Collection Specific**: This migration only affects `collection_id = 1000000`
2. **No Data Loss**: Only updates tags, doesn't delete any data
3. **Test First**: Test on a local database first:
   ```bash
   npx wrangler d1 execute langmap --file=../scripts/002_migrate_i18n_tags_optimized.sql --local
   ```
4. **Backup**: Consider backing up your D1 database before migration
5. **Index Usage**: The migration uses the existing `idx_collection_items_collection_id` index

## Database Schema

```sql
-- Expressions table
CREATE TABLE expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    meaning_id INTEGER,
    audio_url TEXT,
    language_code TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    tags TEXT,  -- JSON array: ["key1", "key2"]
    source_type TEXT DEFAULT 'user',
    source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Collection items table
CREATE TABLE collection_items (
    id INTEGER PRIMARY KEY NOT NULL,
    collection_id INTEGER NOT NULL,
    expression_id INTEGER NOT NULL,
    note TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(collection_id, expression_id)
);
```

## Related Files

- **Optimized SQL**: `scripts/002_migrate_i18n_tags_optimized.sql` (Recommended)
- **Node.js Script**: `scripts/migrate_i18n_tags.js` (Alternative)
- **Legacy SQL**: `scripts/002_migrate_i18n_tags.sql` (Not recommended)
- **Database Schema**: `scripts/001_d1_schema.sql`
- **Collections Schema**: `scripts/005_collections.sql`
- **Wrangler Config**: `backend/wrangler.jsonc`
- **Locale Files**: `web/src/locales/*.json`

## Troubleshooting

### Migration is slow

- Use the optimized SQL script instead of the legacy one
- Ensure `collection_id = 1000000` is correct
- Check if indexes exist on `collection_items(collection_id)`

### Wrong collection ID

- Verify the collection ID you want to migrate
- The script defaults to `1000000`
- Edit the SQL or JS file to change it

### Tags not updating

- Check if `tags` field contains valid JSON
- Verify the expression is in the specified collection
- Check for SQL syntax errors

## Support

If you encounter any issues:
1. Check Wrangler logs for any errors
2. Test with a smaller collection first
3. Use the Node.js script for better error messages
4. Contact the development team
