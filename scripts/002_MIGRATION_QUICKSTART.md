# D1 Migration: i18n Tags Update - Quick Start

## 📋 Summary

Update i18n tags from old format to new flat underscore-separated format.

**Target**: Only expressions in `collection_id = 1000000`  
**Key Mappings**: 71

## 🚀 Quick Start (Recommended)

```bash
cd backend
npx wrangler d1 execute langmap --file=../scripts/002_migrate_i18n_tags_optimized.sql
```

**Time**: ~1-2 seconds  
**Method**: Single UPDATE with nested REPLACE

## 📁 Available Scripts

### 1. `002_migrate_i18n_tags_optimized.sql` (⭐ Recommended)
- Single UPDATE statement
- Uses JOIN to limit to collection_id
- Fastest execution
- **11KB**

### 2. `migrate_i18n_tags.js` (⚡ Alternative)
- Node.js batch processing
- Better error handling
- Preview changes before applying
- **7KB**

### 3. `002_migrate_i18n_tags.sql` (⚠️ Legacy)
- 71 separate UPDATE statements
- Slower execution
- Not recommended
- **9KB**

## 🎯 Key Changes

| Category | Count | Examples |
|-----------|--------|----------|
| Malformed Fixes | 13 | `login_ailed` → `login_failed` |
| Generic Renames | 5 | `error_message` → `verification_link_invalid_or_expired` |
| Duplicate Removal | 4 | `home_regions` → `regions` |
| Nested to Flat | 9 | `home.title` → `home_title` |
| Other Fixes | 40 | Various |

## ✅ Verification

```bash
# Check if migration worked
npx wrangler d1 execute langmap --remote --command="
  SELECT COUNT(*) as count
  FROM expressions e
  INNER JOIN collection_items ci ON e.id = ci.expression_id
  WHERE ci.collection_id = 1000000 
    AND e.tags LIKE '%\"login_failed\"%'
"
```

## 📖 Documentation

Full documentation: `002_migration_README.md`

## 🔧 Local Testing

```bash
cd backend
npx wrangler d1 execute langmap --file=../scripts/002_migrate_i18n_tags_optimized.sql --local
```

## ⚠️ Important

- Only updates `collection_id = 1000000`
- No data loss
- Test locally first
- Consider backup

## 📊 Performance

| Script | Time | Scans |
|---------|------|--------|
| Optimized SQL | 1-2s | Subset only |
| Node.js | 5-10s | One scan |
| Legacy SQL | 60s+ | 71 full scans |

## 🔄 Rollback

See full documentation for rollback instructions.
