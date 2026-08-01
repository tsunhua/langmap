-- 0011: Representative city points for language varieties.
-- This table intentionally models exploration points, not complete language areas.
CREATE TABLE IF NOT EXISTS language_locations (
    variety_key TEXT NOT NULL,
    city_name TEXT NOT NULL,
    city_name_en TEXT,
    territory_code TEXT NOT NULL,
    script_code TEXT NOT NULL DEFAULT '',
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    reference TEXT NOT NULL,
    PRIMARY KEY (variety_key, city_name, territory_code, script_code)
);

CREATE INDEX IF NOT EXISTS idx_language_locations_variety
  ON language_locations(variety_key);

CREATE INDEX IF NOT EXISTS idx_language_locations_city
  ON language_locations(city_name, territory_code);
