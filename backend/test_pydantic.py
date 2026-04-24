import sys
sys.path.append('d:/Tesis/NeuroApp360/backend')

from app import schemas

payload = {
    "username": "test@example.com",
    "password": "password",
    "role": "gestor",
    "full_name": "Test Gestor"
}

user_create = schemas.UserCreate(**payload)
print(user_create.model_dump())
