
import sqlite3
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def reset_password(username, new_password):
    hashed_password = pwd_context.hash(new_password)
    conn = sqlite3.connect('sql_app.db')
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET hashed_password = ? WHERE username = ?", (hashed_password, username))
    conn.commit()
    print(f"Password for {username} reset to {new_password}")
    conn.close()

if __name__ == "__main__":
    reset_password("samuel@gmail.com", "123456")
