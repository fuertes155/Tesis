import sys
import os

backend_path = r'd:\Tesis\NeuroApp360\backend'
sys.path.append(backend_path)

try:
    from app.main import app
    print("Backend import successful")
except Exception as e:
    print(f"Backend import failed: {e}")
    sys.exit(1)
