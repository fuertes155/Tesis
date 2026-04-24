import sqlite3
import os
import sys

# Add the backend directory to sys.path to import models if needed
# But for a simple SQL fix, we can just use sqlite3 directly
db_path = 'backend/sql_app_v2.db'
if not os.path.exists(db_path):
    print(f"Error: DB {db_path} not found")
    sys.exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    print(f"--- Synchronizing Profiles for {db_path} ---")
    
    # 1. Get all users
    cursor.execute("SELECT id, username, role, full_name FROM users")
    users = cursor.fetchall()
    
    counts = {"doctor": 0, "gestor": 0, "user": 0}
    created = {"doctor": 0, "gestor": 0, "user": 0}
    
    for user_id, username, role, full_name in users:
        role = role.lower()
        if role == 'doctor':
            counts['doctor'] += 1
            cursor.execute("SELECT id FROM doctors WHERE user_id = ?", (user_id,))
            if not cursor.fetchone():
                cursor.execute("INSERT INTO doctors (user_id) VALUES (?)", (user_id,))
                created['doctor'] += 1
        elif role == 'gestor':
            counts['gestor'] += 1
            cursor.execute("SELECT id FROM administrators WHERE user_id = ?", (user_id,))
            if not cursor.fetchone():
                cursor.execute("INSERT INTO administrators (user_id) VALUES (?)", (user_id,))
                created['gestor'] += 1
        elif role == 'user':
            counts['user'] += 1
            cursor.execute("SELECT id FROM patients WHERE user_id = ?", (user_id,))
            if not cursor.fetchone():
                name = full_name if full_name else username
                cursor.execute("INSERT INTO patients (user_id, name, age) VALUES (?, ?, ?)", (user_id, name, 0))
                created['user'] += 1
    
    conn.commit()
    print("\nSynchronization complete:")
    print(f"- Doctors: {counts['doctor']} total, {created['doctor']} profiles created")
    print(f"- Gestors: {counts['gestor']} total, {created['gestor']} profiles created")
    print(f"- Patients (Users): {counts['user']} total, {created['user']} profiles created")
    
except Exception as e:
    print(f"Error during synchronization: {e}")
    conn.rollback()
finally:
    conn.close()
