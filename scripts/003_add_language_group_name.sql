-- Migration: Add group_name column to languages table
-- This adds the group_name field to indicate which language group a language belongs to

ALTER TABLE languages ADD COLUMN group_name TEXT;
