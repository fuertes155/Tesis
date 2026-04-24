from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

SQLALCHEMY_DATABASE_URL = "sqlite:///./sql_app_v2.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def check_users():
    db = SessionLocal()
    try:
        users = db.execute(text("SELECT id, username, role FROM users")).fetchall()
        print(f"Total users: {len(users)}")
        for u in users:
            print(f"ID: {u[0]}, Username: {u[1]}, Role: {u[2]}")
        
        duplicates = db.execute(text("SELECT username, COUNT(*) FROM users GROUP BY username HAVING COUNT(*) > 1")).fetchall()
        if duplicates:
            print("\nDUPLICATES FOUND:")
            for d in duplicates:
                print(f"Username: {d[0]}, Count: {d[1]}")
        else:
            print("\nNo duplicates found.")
    finally:
        db.close()

if __name__ == "__main__":
    check_users()
