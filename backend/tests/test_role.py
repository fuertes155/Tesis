from fastapi.testclient import TestClient
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app

client = TestClient(app)

url = "/api/v1/users/register"
payload = {
    "username": "test_gestor@example.com",
    "password": "password123",
    "role": "gestor",
    "full_name": "Test Gestor"
}

# Need to authenticate as admin to use this endpoint
login_url = "/api/v1/users/auth/login"
login_payload = {
    "username": "admin@neuroapp.com", # assuming there's an admin
    "password": "admin" # ?
}
# Actually, I can just use sqlite3 to inspect the database directly.
