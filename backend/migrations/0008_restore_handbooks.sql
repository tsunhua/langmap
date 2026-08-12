CREATE TABLE handbooks (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  visibility TEXT NOT NULL DEFAULT 'public'
    CHECK (visibility IN ('public', 'private')),
  status TEXT NOT NULL DEFAULT 'published'
    CHECK (status IN ('draft', 'published')),
  score INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE handbook_sections (
  id TEXT PRIMARY KEY,
  handbook_id TEXT NOT NULL,
  title TEXT,
  position INTEGER NOT NULL,
  FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE,
  UNIQUE (handbook_id, position)
);

CREATE TABLE handbook_section_items (
  section_id TEXT NOT NULL,
  expression_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  PRIMARY KEY (section_id, expression_id),
  UNIQUE (section_id, position),
  FOREIGN KEY (section_id) REFERENCES handbook_sections(id) ON DELETE CASCADE,
  FOREIGN KEY (expression_id) REFERENCES expressions(id)
);

CREATE INDEX idx_handbooks_visibility_created ON handbooks(visibility, created_at DESC, id ASC);
CREATE INDEX idx_handbooks_score ON handbooks(score DESC, created_at DESC, id ASC);
CREATE INDEX idx_handbook_sections_handbook ON handbook_sections(handbook_id, position ASC, id ASC);
CREATE INDEX idx_handbook_section_items_section ON handbook_section_items(section_id, position ASC, expression_id ASC);
