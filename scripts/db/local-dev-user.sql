-- Local D1 only. Not applied to production.
-- Login: dev@example.com / dev
INSERT OR IGNORE INTO users (username, email, password_hash, role, email_verified)
VALUES (
  'dev',
  'dev@example.com',
  'devlocal000000000000000000000000:251e12b26c6b38cb481ae601b7cc91003c89b311de06fdf275d086cd6d787d3f',
  'user',
  1
);
