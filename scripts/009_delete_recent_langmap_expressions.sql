-- 删除 langmap 收藏集中最近一天新增的表达式关联
-- Delete collection_items added in the last day

DELETE FROM collection_items
WHERE collection_id = (SELECT id FROM collections WHERE name = 'langmap')
  AND datetime(created_at) > datetime('now', '-1 day');
