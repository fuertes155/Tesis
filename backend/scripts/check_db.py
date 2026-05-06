import sqlite3

conn = sqlite3.connect('sql_app_v2.db')
cursor = conn.cursor()
cursor.execute("SELECT id, username, role FROM users LIMIT 10")
for row in cursor.fetchall():
    print(row)
conn.close()
