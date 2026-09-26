import sqlite3
from app.core.security import get_password_hash

conn = sqlite3.connect('data/sql_app_v2.db')
cursor = conn.cursor()
hash_pwd = get_password_hash('Password123!')

users_to_update = ['samuel1@gmail.com', 'samuel@gmail.com', 'samuel@gmail']

for u in users_to_update:
    cursor.execute('UPDATE users SET hashed_password = ? WHERE username = ?', (hash_pwd, u))

conn.commit()
print('Passwords updated!')
