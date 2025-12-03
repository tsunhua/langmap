-- Populate initial language data for LangMap application
-- Compatible with Cloudflare D1

INSERT INTO languages (code, name, region_code, region_name, region_latitude, region_longitude, created_at, updated_at) VALUES
('en-GB', 'English(London)', 'GB', 'London, United Kingdom', 51.5074, -0.1278, datetime('now'), datetime('now')),
('zh-CN', '中文（北京）', 'CN', '北京，中国', 39.9042, 116.4074, datetime('now'), datetime('now')),
('zh-TW', '中文（台北）', 'TW', '台北，台灣', 25.0330, 121.5654, datetime('now'), datetime('now')),
('es', 'Español', 'ES', 'Madrid, España', 40.4168, -3.7038, datetime('now'), datetime('now')),
('fr', 'Français', 'FR', 'Paris, France', 48.8566, 2.3522, datetime('now'), datetime('now')),
('ja', '日本語', 'JP', '東京、日本', 35.6762, 139.6503, datetime('now'), datetime('now')),
('ko', '한국어', 'KR', '서울, 대한민국', 37.5665, 126.9780, datetime('now'), datetime('now')),
('ar', 'العربية', 'EG', 'القاهرة، مصر', 30.0444, 31.2357, datetime('now'), datetime('now')),
('pt', 'Português', 'PT', 'Lisboa, Portugal', 38.7223, -9.1393, datetime('now'), datetime('now')),
('ru', 'Русский', 'RU', 'Москва, Россия', 55.7558, 37.6176, datetime('now'), datetime('now')),
('de', 'Deutsch', 'DE', 'Berlin, Deutschland', 52.5200, 13.4050, datetime('now'), datetime('now')),
('hi', 'हिन्दी', 'IN', 'नई दिल्ली, भारत', 28.6139, 77.2090, datetime('now'), datetime('now')),
('it', 'Italiano', 'IT', 'Roma, Italia', 41.9028, 12.4964, datetime('now'), datetime('now'))
ON CONFLICT(code) DO NOTHING;