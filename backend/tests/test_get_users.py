from fastapi.testclient import TestClient
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app

client = TestClient(app)

try:
    print("Fetching users...")
    users = client.get("/api/v1/users/", timeout=2).json()
    print("Users:")
    for u in users:
        print(f"ID: {u.get('id')}, Role: {u.get('role')}")
except Exception as e:
    print(f"Error: {e}")
