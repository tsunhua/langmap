-- 添加 "image" 语言到 languages 表
INSERT INTO languages (code, name, direction, is_active, created_by, updated_by)
VALUES ('image', 'Image', 'ltr', 1, 'system', 'system');

-- 验证插入
SELECT * FROM languages WHERE code = 'image';
