-- Preserve each source dictionary's own homograph numbering after word-form
-- merge. Within one dictionary different markers mean different senses;
-- across dictionaries markers never claim shared identity.
CREATE TABLE expression_sources (
  expression_id INTEGER NOT NULL,
  source_id INTEGER NOT NULL,
  source_marker TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (expression_id, source_id, source_marker),
  FOREIGN KEY (expression_id) REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL
) WITHOUT ROWID;

CREATE TABLE expression_edge_sources (
  edge_id INTEGER NOT NULL,
  source_id INTEGER NOT NULL,
  source_marker TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (edge_id, source_id, source_marker),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id) ON DELETE CASCADE,
  FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL
) WITHOUT ROWID;

CREATE INDEX idx_expression_sources_expression ON expression_sources(expression_id);
CREATE INDEX idx_expression_edge_sources_edge ON expression_edge_sources(edge_id);