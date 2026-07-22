from fastapi.testclient import TestClient
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app

client = TestClient(app)

# 1. Login to get token
login_url = "/api/v1/users/auth/login"
login_payload = {
    "username": "admin@neuroapp.com", # Oh wait, what is the admin username? I'll use the one I made: gestortest1@example.com? No, I created that directly in DB without hashed password.
    "password": "password123"
}
# Instead of doing that, I'll modify the DB to make gestortest1 have a known hashed password, or I'll just change the dependency in routers/users.py for a moment to test it.
