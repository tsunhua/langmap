-- Auto-generated SQL script for languages table
-- Uses stable hash IDs for language_id based on language code
-- Uses UPSERT (INSERT ... ON CONFLICT ... DO UPDATE) to update existing rows or insert new ones

INSERT INTO languages (id, code, name, direction, is_active, region_code, region_name, region_latitude, region_longitude, created_by, updated_by, created_at, updated_at) VALUES
(576095611, 'en-US', 'English (New York)', 'ltr', 1, 'US', 'New York', 40.7128, -74.006, 'langmap', 'langmap', datetime('now'), datetime('now')),
(422831374, 'en-GB', 'English (London)', 'ltr', 0, 'GB', 'London', 51.5074, -0.1278, 'langmap', 'langmap', datetime('now'), datetime('now')),
(637978676, 'zh-CN', '中文 (北京)', 'ltr', 1, 'CN', '北京', 39.9042, 116.4074, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1826033733, 'zh-TW', '中文 (台北)', 'ltr', 1, 'TW', '台北', 25.033, 121.5654, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1176137066, 'es', 'Español', 'ltr', 1, 'ES', 'Madrid', 40.4168, -3.7038, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1461901042, 'fr', 'Français', 'ltr', 1, 'FR', 'Paris', 48.8566, 2.3522, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1816099349, 'ja', '日本語', 'ltr', 1, 'JP', '東京', 35.6762, 139.6503, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1111292256, 'ko', '한국어', 'ltr', 0, 'KR', '서울', 37.5665, 126.978, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1562713851, 'ar', 'العربية', 'rtl', 0, 'EG', 'القاهرة', 30.0444, 31.2357, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1565420802, 'pt', 'Português', 'ltr', 0, 'PT', 'Lisboa', 38.7223, -9.1393, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1213488161, 'ru', 'Русский', 'ltr', 0, 'RU', 'Москва', 55.7558, 37.6176, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1545391779, 'de', 'Deutsch', 'ltr', 0, 'DE', 'Berlin', 52.52, 13.405, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1748694683, 'hi', 'हिन्दी', 'ltr', 0, 'IN', 'नई दिल्ली', 28.6139, 77.209, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1194886161, 'it', 'Italiano', 'ltr', 0, 'IT', 'Roma', 41.9028, 12.4964, 'langmap', 'langmap', datetime('now'), datetime('now')),
(1588898158, 'nan-TW', '閩南語 (台北)', 'ltr', 1, 'TW', '台北', 25.033, 121.5654, 'langmap', 'langmap', datetime('now'), datetime('now')),
(2021758317, 'yue-HK', '粵語 (香港)', 'ltr', 1, 'HK', '香港', 22.3964, 114.1095, 'langmap', 'langmap', datetime('now'), datetime('now'))
ON CONFLICT(code) DO UPDATE SET
    name=excluded.name,
    direction=excluded.direction,
    is_active=excluded.is_active,
    region_code=excluded.region_code,
    region_name=excluded.region_name,
    region_latitude=excluded.region_latitude,
    region_longitude=excluded.region_longitude,
    updated_by=excluded.updated_by,
    updated_at=excluded.updated_at;
