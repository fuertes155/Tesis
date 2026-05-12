
import sqlite3

def list_users():
    conn = sqlite3.connect('sql_app.db')
    cursor = conn.cursor()
    cursor.execute("SELECT id, username, role, full_name FROM users")
    users = cursor.fetchall()
    print("Users in database:")
    for user in users:
        print(f"ID: {user[0]}, Username: {user[1]}, Role: {user[2]}, Full Name: {user[3]}")
    conn.close()

if __name__ == "__main__":
    list_users()
