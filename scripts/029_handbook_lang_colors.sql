-- Migration 029: Add lang_colors column to handbooks table
-- Stores custom language colors as JSON: {"zh-CN": "#ff0000", "ja": "#00ff00"}
ALTER TABLE handbooks ADD COLUMN lang_colors TEXT DEFAULT '{}';
