import sqlite3
import os

db_path = 'backend/sql_app_v2.db'
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        print(f"Checking Profiles for Patients in DB: {db_path}")
        cursor.execute("SELECT u.id, u.username, u.role, p.id FROM users u LEFT JOIN patients p ON u.id = p.user_id WHERE u.role = 'user'")
        patients = cursor.fetchall()
        for p in patients:
            print(f"- UserID: {p[0]}, Username: {p[1]}, Role: {p[2]}, PatientID: {p[3]}")
            
        print("\nChecking Profiles for Doctors:")
        cursor.execute("SELECT u.id, u.username, u.role, d.id FROM users u LEFT JOIN doctors d ON u.id = d.user_id WHERE u.role = 'doctor'")
        doctors = cursor.fetchall()
        for d in doctors:
            print(f"- UserID: {d[0]}, Username: {d[1]}, Role: {d[2]}, DoctorID: {d[3]}")
            
    except Exception as e:
        print(f"Error reading DB: {e}")
    finally:
        conn.close()
else:
    print(f"DB {db_path} not found")
