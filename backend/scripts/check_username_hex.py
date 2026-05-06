import sqlite3
import os

db_path = 'backend/sql_app_v2.db'
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT username FROM users WHERE id = 6")
        username = cursor.fetchone()[0]
        print(f"Username: '{username}'")
        print(f"Hex: {username.encode('utf-8').hex()}")
        
        # Check for user samuel@gmail.com too
        cursor.execute("SELECT username FROM users WHERE username LIKE 'samuel@gmail.com%'")
        u2 = cursor.fetchone()
        if u2:
            print(f"Samuel: '{u2[0]}'")
            print(f"Hex: {u2[0].encode('utf-8').hex()}")
            
    except Exception as e:
        print(f"Error reading DB: {e}")
    finally:
        conn.close()
else:
    print(f"DB {db_path} not found")
