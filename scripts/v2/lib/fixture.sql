-- fixture.sql: simulate a small old dataset (old schema) for migrate integration testing
INSERT INTO languages (id, code, name, is_active) VALUES (1, 'cmn', '普通话', 1), (2, 'en', 'English', 1);
INSERT INTO expressions (id, text, language_code, source_type) VALUES
  (101, '吃了吗', 'cmn', 'user'),
  (102, 'Have you eaten?', 'en', 'user'),
  (103, '你好', 'cmn', 'user'),
  (104, 'Hello', 'en', 'user');
INSERT INTO meanings (id) VALUES (9);
INSERT INTO expression_meaning (id, expression_id, meaning_id) VALUES
  ('101-9', 101, 9), ('102-9', 102, 9);
INSERT INTO users (id, username, email, password_hash, role) VALUES (99, 'test_user', 'test@fixture', 'x', 'admin');
INSERT INTO handbooks (id, user_id, title, content, source_lang, is_public, has_pages) VALUES
  (1, 99, '問候手冊', '# 問候

{{text:你好|lang:cmn}} 和 {{text:Hello|lang:en}}', 'en', 1, 0);
