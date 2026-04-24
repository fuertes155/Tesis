import os
from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# Calculate absolute path for SQLite
db_url = settings.DATABASE_URL
if db_url.startswith("sqlite:///./"):
    # backend/app/database.py -> backend/
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    db_name = db_url.replace("sqlite:///./", "")
    db_path = os.path.join(base_dir, db_name)
    db_url = f"sqlite:///{db_path}"

SQLALCHEMY_DATABASE_URL = db_url

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

# Enable SQLite foreign key constraints
if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    @event.listens_for(engine, "connect")
    def enable_sqlite_foreign_keys(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
