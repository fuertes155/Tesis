import sqlite3
import os

db_path = 'neuroapp.db'
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT username, role FROM users")
        users = cursor.fetchall()
        print("Users in DB:")
        for u in users:
            print(f"- {u[0]} ({u[1]})")
    except Exception as e:
        print(f"Error reading DB: {e}")
    finally:
        conn.close()
else:
    print(f"DB {db_path} not found")
