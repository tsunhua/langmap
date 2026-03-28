-- Migration 040: 爲 expressions 表新增 desc 字段
-- 用於存儲 Markdown 格式的描述/例句，最大 1000 字符

ALTER TABLE expressions ADD COLUMN desc TEXT DEFAULT NULL;

ALTER TABLE expression_versions ADD COLUMN desc TEXT DEFAULT NULL;
