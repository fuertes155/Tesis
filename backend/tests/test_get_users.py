import requests

try:
    print("Fetching users...")
    users = requests.get("http://127.0.0.1:8000/api/v1/users/", timeout=2).json()
    print("Users:")
    for u in users:
        print(f"ID: {u.get('id')}, Role: {u.get('role')}")
except Exception as e:
    print(f"Error: {e}")
