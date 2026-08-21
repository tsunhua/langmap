-- Preserve Markdown heading nesting in migrated and newly edited handbooks.
ALTER TABLE handbook_sections ADD COLUMN parent_section_id TEXT REFERENCES handbook_sections(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_handbook_sections_parent
  ON handbook_sections(handbook_id, parent_section_id, position ASC, id ASC);
