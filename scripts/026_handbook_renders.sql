-- Migration 026: Add renders column to handbooks table
ALTER TABLE handbooks ADD COLUMN renders TEXT DEFAULT '{}';
