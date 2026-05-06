import sys
import json
sys.path.append('d:/Tesis/NeuroApp360/backend')

from app.database import SessionLocal
from app.models.user import User
from app import schemas

db = SessionLocal()
users = db.query(User).limit(5).all()

for u in users:
    print(f"DB Role: {u.role}")
    schema_user = schemas.User.model_validate(u)
    print(f"Schema Role: {schema_user.role}")

db.close()
