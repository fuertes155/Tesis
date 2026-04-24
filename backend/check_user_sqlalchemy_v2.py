from sqlalchemy import create_engine, func
from sqlalchemy.orm import sessionmaker
import os
import sys

# Add the current directory to sys.path so it can find 'app'
sys.path.append(os.getcwd() + '/backend')

from app import models

# Use the same DB URL as the app
db_path = 'backend/sql_app_v2.db'
if not os.path.exists(db_path):
    print(f"DB {db_path} not found")
    exit(1)

# Note: the app uses sqlite:///./sql_app_v2.db relative to backend dir
# So here we use the absolute path for safety
abs_db_path = os.path.abspath(db_path)
engine = create_engine(f"sqlite:///{abs_db_path}")
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

try:
    username_to_check = "santiagochar@gmail.com"
    normalized = username_to_check.strip().lower()
    
    print(f"Checking for: '{normalized}'")
    user = db.query(models.User).filter(func.lower(models.User.username) == normalized).first()
    if user:
        print(f"User found: ID={user.id}, Username='{user.username}', Role='{user.role}'")
    else:
        print(f"User NOT found with normalized username: '{normalized}'")
        
        # List all users to see what's actually there
        print("\nAll users in DB:")
        all_users = db.query(models.User).all()
        for u in all_users:
            print(f"- '{u.username}' (ID: {u.id})")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
