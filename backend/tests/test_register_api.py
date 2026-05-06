import sys
sys.path.append('d:/Tesis/NeuroApp360/backend')

from main import app
from fastapi.testclient import TestClient
from app.models.user import User

client = TestClient(app)

# Login to get token
response = client.post("/api/v1/users/auth/login", data={"username": "samuel@gmail", "password": "123"})
token = response.json().get("access_token")

# Call register with role gestor
headers = {"Authorization": f"Bearer {token}"}
payload = {
    "username": "gestortest2@example.com",
    "password": "Password123!",
    "role": "gestor",
    "full_name": "Gestor Test 2"
}
response = client.post("/api/v1/users/register", json=payload, headers=headers)
print("Register Response Status:", response.status_code)
print("Register Response JSON:", response.json())
