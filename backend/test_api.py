import requests

# 1. Login to get token
login_url = "http://127.0.0.1:8000/api/v1/users/auth/login"
login_payload = {
    "username": "admin@neuroapp.com", # Oh wait, what is the admin username? I'll use the one I made: gestortest1@example.com? No, I created that directly in DB without hashed password.
    "password": "password123"
}
# Instead of doing that, I'll modify the DB to make gestortest1 have a known hashed password, or I'll just change the dependency in routers/users.py for a moment to test it.
