from fastapi.testclient import TestClient
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app

client = TestClient(app)
import time

BASE_URL = "/api/v1"

def test_flow():
    try:
        # 1. Login as Admin
        print("Logging in as admin...")
        login_data = {
            "username": "samuel1@gmail.com",
            "password": "Password123!"
        }
        r = client.post(f"{BASE_URL}/users/auth/login", json=login_data)
        if r.status_code != 200:
            print(f"Admin login failed: {r.text}")
            return
        
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print("Admin login success.")

        # 2. Create a new doctor
        doctor_username = f"test_doctor_{int(time.time())}@example.com"
        doctor_password = "Password123!"
        print(f"Creating new doctor: {doctor_username}...")
        create_data = {
            "username": doctor_username,
            "password": doctor_password,
            "role": "doctor",
            "full_name": "Test Doctor Automático"
        }
        r = client.post(f"{BASE_URL}/users/register", json=create_data, headers=headers)
        if r.status_code != 201:
            print(f"Doctor creation failed: {r.text}")
            return
        
        print("Doctor creation success.")

        # 3. Try to login with new doctor
        print("Logging in with new doctor...")
        doctor_login_data = {
            "username": doctor_username,
            "password": doctor_password
        }
        r = client.post(f"{BASE_URL}/users/auth/login", json=doctor_login_data)
        if r.status_code != 200:
            print(f"Doctor login failed: {r.text}")
            return
        
        print("Doctor login success! Verification complete.")

    except Exception as e:
        print(f"Error during test: {e}")

if __name__ == "__main__":
    test_flow()
