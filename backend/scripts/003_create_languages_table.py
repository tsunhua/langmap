import sqlite3
import os

# Connect to the SQLite database
db_path = "./backend_dev.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create the languages table
create_table_sql = """
CREATE TABLE IF NOT EXISTS languages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    native_name VARCHAR(100),
    direction VARCHAR(3) DEFAULT 'ltr',
    is_active BOOLEAN DEFAULT 1,
    created_by INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
"""

try:
    cursor.execute(create_table_sql)
    conn.commit()
    print("Languages table created successfully!")
except Exception as e:
    print(f"Error creating languages table: {e}")
finally:
    conn.close()