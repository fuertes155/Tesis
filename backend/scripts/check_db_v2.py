import sqlite3
import os

db_path = 'sql_app_v2.db'
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        print(f"Checking DB: {db_path}")
        cursor.execute("SELECT id, username, role, is_active FROM users")
        users = cursor.fetchall()
        print("Users in DB:")
        for u in users:
            print(f"- ID: {u[0]}, Username: {u[1]}, Role: {u[2]}, Active: {u[3]}")
            
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        print("\nTables in DB:")
        for t in tables:
            print(f"- {t[0]}")
            
    except Exception as e:
        print(f"Error reading DB: {e}")
    finally:
        conn.close()
else:
    print(f"DB {db_path} not found")
