import os
import re

TESTS_DIR = "tests"

TEST_FILES = [
    "test_api.py",
    "test_automatic_flow.py",
    "test_edge_cases.py",
    "test_get_users.py",
    "test_patient_session_flow.py",
    "test_role.py"
]

for filename in TEST_FILES:
    filepath = os.path.join(TESTS_DIR, filename)
    if not os.path.exists(filepath):
        continue

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Replacements
    content = content.replace("import requests", "from fastapi.testclient import TestClient\nimport sys\nimport os\nsys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\nfrom main import app\n\nclient = TestClient(app)")
    
    content = content.replace("requests.post(", "client.post(")
    content = content.replace("requests.get(", "client.get(")
    content = content.replace("requests.delete(", "client.delete(")
    content = content.replace("requests.put(", "client.put(")
    
    content = content.replace('BASE_URL = "http://localhost:8000/api/v1"', 'BASE_URL = "/api/v1"')
    content = content.replace('BASE_URL = "http://127.0.0.1:8000/api/v1"', 'BASE_URL = "/api/v1"')
    
    content = content.replace('http://127.0.0.1:8000/api/v1', '/api/v1')
    content = content.replace('http://localhost:8000/api/v1', '/api/v1')
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

print("Tests refactored successfully.")
