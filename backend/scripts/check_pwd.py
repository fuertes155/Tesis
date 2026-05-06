import sqlite3

conn = sqlite3.connect('sql_app_v2.db')
cursor = conn.cursor()
cursor.execute("SELECT id, username, hashed_password FROM users WHERE username = 'santiagochar@gmail.com'")
row = cursor.fetchone()
print(f"Password in DB for {row[1]}: {row[2]}")
conn.close()
