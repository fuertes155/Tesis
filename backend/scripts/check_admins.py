import sqlite3
import os

db_path = 'backend/sql_app_v2.db'
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        print(f"Checking Administrators in DB: {db_path}")
        cursor.execute("SELECT u.id, u.username, u.role, a.id FROM users u LEFT JOIN administrators a ON u.id = a.user_id WHERE u.role = 'gestor'")
        admins = cursor.fetchall()
        for a in admins:
            print(f"- UserID: {a[0]}, Username: {a[1]}, Role: {a[2]}, AdminID: {a[3]}")
            
    except Exception as e:
        print(f"Error reading DB: {e}")
    finally:
        conn.close()
else:
    print(f"DB {db_path} not found")
