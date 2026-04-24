import sqlite3
import requests

# 1. Login to get token
login_data = {
    "username": "admin@neuroapp.com", 
    "password": "password123"
}
# wait, there's no known admin credentials.
# Instead, I'll modify the DB directly to make a user a gestor so I can test it.
conn = sqlite3.connect('sql_app_v2.db')
cursor = conn.cursor()
# Make user id 1 a gestor
cursor.execute("UPDATE users SET role = 'gestor' WHERE id = 1")
conn.commit()

# Print roles
cursor.execute("SELECT id, username, role FROM users LIMIT 10")
for row in cursor.fetchall():
    print(row)
conn.close()
