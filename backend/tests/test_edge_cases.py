from fastapi.testclient import TestClient
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app

client = TestClient(app)
import time
from datetime import datetime

BASE_URL = "/api/v1"

def test_edge_cases():
    print("Iniciando pruebas de casos límite (Edge Cases)...")
    try:
        # 1. Login as Admin
        r = client.post(f"{BASE_URL}/users/auth/login", json={"username": "samuel1@gmail.com", "password": "Password123!"})
        admin_token = r.json().get("access_token")
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        # 2. Login as Doctor
        # Primero creamos un doctor si no existe, o usamos uno de prueba
        doc_username = f"doctor_{int(time.time())}@example.com"
        client.post(f"{BASE_URL}/users/register", json={
            "username": doc_username,
            "password": "Password123!",
            "role": "doctor",
            "full_name": "Doctor de Prueba"
        }, headers=admin_headers)
        
        r = client.post(f"{BASE_URL}/users/auth/login", json={"username": doc_username, "password": "Password123!"})
        doc_token = r.json().get("access_token")
        doc_headers = {"Authorization": f"Bearer {doc_token}"}

        # --- CASO 1: Permisos de Borrado ---
        print("\n[CASO 1] Intentar borrar un paciente siendo Doctor (Debería ser denegado)")
        
        # Admin crea el paciente
        r = client.post(f"{BASE_URL}/patients/", json={
            "name": "Paciente Para Borrar",
            "document_id": f"DEL-{int(time.time())}",
            "age": 25, "gender": "male", "education_level": "básico"
        }, headers=admin_headers)
        patient_id = r.json()["id"]

        # Doctor intenta borrarlo
        r_del_doc = client.delete(f"{BASE_URL}/patients/{patient_id}", headers=doc_headers)
        if r_del_doc.status_code == 403:
            print(" Éxito: El doctor fue bloqueado (403 Forbidden) al intentar borrar.")
        else:
            print(f" Fallo de seguridad: El doctor recibió status {r_del_doc.status_code} en lugar de 403.")

        # --- CASO 2: Borrado en Cascada (Integridad de DB) ---
        print("\n[CASO 2] Borrar paciente como Admin y verificar cascada")
        
        # Admin crea sesión para este paciente
        r_ses = client.post(f"{BASE_URL}/sessions/", json={
            "patient_id": patient_id,
            "date": datetime.now().date().isoformat(),
            "status": "pending",
            "notes": "Sesión a borrar"
        }, headers=admin_headers)
        session_id = r_ses.json()["id"]
        
        # Admin crea resultado para este paciente
        r_res = client.post(f"{BASE_URL}/sessions/results", json={
            "patient_id": patient_id,
            "session_id": session_id,
            "game_type": "memoria",
            "game_name": "Memoria 360",
            "score": 100,
            "duration": 60,
            "timestamp": datetime.now().isoformat(),
            "details": {}
        }, headers=admin_headers)
        
        # Admin borra paciente
        r_del_admin = client.delete(f"{BASE_URL}/patients/{patient_id}", headers=admin_headers)
        if r_del_admin.status_code == 200:
            print(" Éxito: El admin borró el paciente correctamente.")
        else:
            print(f" Fallo DB: Error al borrar paciente. {r_del_admin.text}")
            return

        # Verificar si la sesión desapareció
        r_ses_check = client.get(f"{BASE_URL}/sessions/{session_id}", headers=admin_headers)
        if r_ses_check.status_code == 404:
            print(" Éxito: La sesión asociada fue borrada correctamente (Cascade).")
        else:
            print(f" Advertencia: La sesión sigue existiendo. Status: {r_ses_check.status_code}")

    except Exception as e:
        print(f"Error en pruebas: {e}")

if __name__ == "__main__":
    test_edge_cases()
