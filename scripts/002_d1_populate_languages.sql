-- Populate initial language data for LangMap application
-- Compatible with Cloudflare D1

INSERT INTO languages (code, name, direction, is_active, region_code, region_name, region_latitude, region_longitude, created_by, updated_by, created_at, updated_at) VALUES
('en-US', 'English (New York)', 'ltr', 1, 'US', 'New York, United States', 40.7128, -74.0060, 'langmap', 'langmap', datetime('now'), datetime('now')),
('en-GB', 'English (London)', 'ltr', 0, 'GB', 'London, United Kingdom', 51.5074, -0.1278, 'langmap', 'langmap', datetime('now'), datetime('now')),
('zh-CN', '中文 (北京)', 'ltr', 1, 'CN', '北京，中国', 39.9042, 116.4074, 'langmap', 'langmap', datetime('now'), datetime('now')),
('zh-TW', '中文 (台北)', 'ltr', 1, 'TW', '台北，台灣', 25.0330, 121.5654, 'langmap', 'langmap', datetime('now'), datetime('now')),
('es', 'Español', 'ltr', 1, 'ES', 'Madrid, España', 40.4168, -3.7038, 'langmap', 'langmap', datetime('now'), datetime('now')),
('fr', 'Français', 'ltr', 1, 'FR', 'Paris, France', 48.8566, 2.3522, 'langmap', 'langmap', datetime('now'), datetime('now')),
('ja', '日本語', 'ltr', 1, 'JP', '東京、日本', 35.6762, 139.6503, 'langmap', 'langmap', datetime('now'), datetime('now')),
('ko', '한국어', 'ltr', 0, 'KR', '서울, 대한민국', 37.5665, 126.9780, 'langmap', 'langmap', datetime('now'), datetime('now')),
('ar', 'العربية', 'rtl', 0, 'EG', 'القاهرة، مصر', 30.0444, 31.2357, 'langmap', 'langmap', datetime('now'), datetime('now')),
('pt', 'Português', 'ltr', 0, 'PT', 'Lisboa, Portugal', 38.7223, -9.1393, 'langmap', 'langmap', datetime('now'), datetime('now')),
('ru', 'Русский', 'ltr', 0, 'RU', 'Москва, Россия', 55.7558, 37.6176, 'langmap', 'langmap', datetime('now'), datetime('now')),
('de', 'Deutsch', 'ltr', 0, 'DE', 'Berlin, Deutschland', 52.5200, 13.4050, 'langmap', 'langmap', datetime('now'), datetime('now')),
('hi', 'हिन्दी', 'ltr', 0, 'IN', 'नई दिल्ली, भारत', 28.6139, 77.2090, 'langmap', 'langmap', datetime('now'), datetime('now')),
('it', 'Italiano', 'ltr', 0, 'IT', 'Roma, Italia', 41.9028, 12.4964, 'langmap', 'langmap', datetime('now'), datetime('now'))
ON CONFLICT(code) DO NOTHING;