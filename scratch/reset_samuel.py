import sqlite3
import os
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

db_path = "backend/data/sql_app_v2.db"
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    hashed = pwd_context.hash("samuel123")
    cursor.execute("UPDATE users SET hashed_password = ?, is_2fa_enabled = 1, totp_secret = 'JBSWY3DPEHPK3PXP' WHERE username = 'samuel@gmail.com'", (hashed,))
    if cursor.rowcount == 0:
        # Create it if it doesn't exist
        cursor.execute("INSERT INTO users (username, hashed_password, role, is_active, is_available, is_2fa_enabled, totp_secret, registration_date) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))", 
                       ('samuel@gmail.com', hashed, 'gestor', 1, 1, 1, 'JBSWY3DPEHPK3PXP'))
    conn.commit()
    conn.close()
    print("User samuel@gmail.com updated with password samuel123 and 2FA enabled (Secret: JBSWY3DPEHPK3PXP)")
else:
    print("DB not found")
