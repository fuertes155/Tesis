import sqlite3
import os

db_path = 'backend/sql_app_v2.db'
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT username, hashed_password FROM users WHERE id = 6")
        row = cursor.fetchone()
        print(f"User: {row[0]}")
        print(f"Hash: '{row[1]}'")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        conn.close()
else:
    print(f"DB {db_path} not found")
