from app.database import engine
from sqlalchemy import text

def migrate():
    try:
        with engine.connect() as conn:
            conn.execute(text('ALTER TABLE patients ADD COLUMN email VARCHAR'))
            conn.commit()
            print("Successfully added email column to patients table.")
    except Exception as e:
        print(f"Error during migration: {e}")

if __name__ == "__main__":
    migrate()
