-- LangMap Comprehensive Indexing & Optimization Script
-- Date: 2026-02-12
-- Description: Ensures all necessary indexes exist for performance, including composite indexes for sorting and filtering.
-- 執行：npx wrangler d1 execute langmap --remote --file=../scripts/013_optimization_indexes.sql --y

--------------------------------------------------------------------------------
-- 1. Languages Table
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_languages_code ON languages(code);
CREATE INDEX IF NOT EXISTS idx_languages_name ON languages(name);
CREATE INDEX IF NOT EXISTS idx_languages_is_active ON languages(is_active);
-- Optimization: Faster active language listing
CREATE INDEX IF NOT EXISTS idx_languages_active_name ON languages(is_active, name);

--------------------------------------------------------------------------------
-- 2. Expressions Table
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_expressions_text ON expressions(text);
CREATE INDEX IF NOT EXISTS idx_expressions_language_code ON expressions(language_code);
CREATE INDEX IF NOT EXISTS idx_expressions_meaning_id ON expressions(meaning_id);
CREATE INDEX IF NOT EXISTS idx_expressions_tags ON expressions(tags);
-- Optimization: High-performance list filtering and paging (Bottleneck SQL #1, #3)
CREATE INDEX IF NOT EXISTS idx_expressions_lang_meaning_created ON expressions(language_code, meaning_id, created_at DESC);
-- Optimization: Faster sync and ID migration checks
CREATE INDEX IF NOT EXISTS idx_expressions_lang_text ON expressions(language_code, text);

--------------------------------------------------------------------------------
-- 3. Collection Items Table
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_collection_items_collection_id ON collection_items(collection_id);
CREATE INDEX IF NOT EXISTS idx_collection_items_expression_id ON collection_items(expression_id);
-- Optimization: Performance for collection detail listing (Bottleneck SQL #4)
CREATE INDEX IF NOT EXISTS idx_collection_items_query ON collection_items(collection_id, created_at DESC);

--------------------------------------------------------------------------------
-- 4. Collections Table
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_collections_user_id ON collections(user_id);
CREATE INDEX IF NOT EXISTS idx_collections_name ON collections(name);
-- Optimization: Shared/Public collection listing (Bottleneck SQL #5)
CREATE INDEX IF NOT EXISTS idx_collections_is_public_created ON collections(is_public, created_at DESC);
-- Optimization: Personal collection listing
CREATE INDEX IF NOT EXISTS idx_collections_user_created ON collections(user_id, created_at DESC);

--------------------------------------------------------------------------------
-- 5. User & Auth Tables
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_expr_versions_id_created ON expression_versions(expression_id, created_at DESC);
