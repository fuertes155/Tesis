import sqlite3
import os
import sys

# Add backend to path to import hashing
sys.path.append(os.getcwd() + '/backend')
from app.security import get_password_hash

db_path = 'backend/sql_app_v2.db'
if not os.path.exists(db_path):
    print(f"DB {db_path} not found")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    username = "santiagochar@gmail.com"
    new_password = "Password123!"
    hashed = get_password_hash(new_password)
    
    print(f"Resetting password for: {username}")
    cursor.execute("UPDATE users SET hashed_password = ? WHERE username = ?", (hashed, username))
    
    # Also reset for samuel1@gmail.com just in case
    cursor.execute("UPDATE users SET hashed_password = ? WHERE username = ?", (hashed, "samuel1@gmail.com"))
    
    conn.commit()
    print("Success! Password reset to: Password123!")
    
except Exception as e:
    print(f"Error: {e}")
    conn.rollback()
finally:
    conn.close()
