from fastapi.testclient import TestClient
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app

client = TestClient(app)
import time
from datetime import datetime

BASE_URL = "/api/v1"

def test_patient_and_session_flow():
    print("Iniciando prueba de flujo de pacientes y sesiones...")
    try:
        # 1. Iniciar sesión como gestor (admin)
        print("\n1. Iniciando sesión como admin (samuel1@gmail.com)...")
        login_data = {
            "username": "samuel1@gmail.com",
            "password": "Password123!"
        }
        r = client.post(f"{BASE_URL}/users/auth/login", json=login_data)
        if r.status_code != 200:
            print(f"Error en login: {r.text}")
            return
        
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print("Login exitoso.")

        # 2. Crear un paciente
        unique_id = int(time.time())
        patient_data = {
            "name": f"Paciente de Prueba {unique_id}",
            "document_id": f"DOC-{unique_id}",
            "age": 30,
            "gender": "male",
            "education_level": "universitario"
        }
        print("\n2. Registrando un nuevo paciente...")
        r = client.post(f"{BASE_URL}/patients/", json=patient_data, headers=headers)
        if r.status_code not in [200, 201]:
            print(f"Error creando paciente: {r.text}")
            return
        
        patient = r.json()
        patient_id = patient["id"]
        print(f"Paciente creado exitosamente: ID {patient_id}, Nombre: {patient['name']}")

        # 3. Crear una sesión de juego para el paciente
        print("\n3. Creando una nueva sesión para el paciente...")
        session_data = {
            "patient_id": patient_id,
            "date": datetime.now().date().isoformat(),
            "status": "pending",
            "notes": "Sesión de prueba automatizada"
        }
        r = client.post(f"{BASE_URL}/sessions/", json=session_data, headers=headers)
        if r.status_code not in [200, 201]:
            print(f"Error creando sesión: {r.text}")
            return
        
        session = r.json()
        session_id = session["id"]
        print(f"Sesión creada exitosamente: ID {session_id}")

        # 4. Enviar resultados (results) a la sesión
        print("\n4. Enviando resultados de juego para la sesión...")
        result_data = {
            "patient_id": patient_id,
            "session_id": session_id,
            "game_type": "memoria",
            "game_name": "Juego de Memoria Visual",
            "score": 95,
            "duration": 120,
            "timestamp": datetime.now().isoformat(),
            "details": {"nivel": 3, "errores": 1}
        }
        r = client.post(f"{BASE_URL}/sessions/results", json=result_data, headers=headers)
        if r.status_code not in [200, 201]:
            print(f"Error enviando resultados: {r.text}")
            return
        
        result = r.json()
        print(f"Resultado guardado exitosamente: ID {result['id']}, Puntuación: {result['score']}")

        # 5. Obtener los últimos resultados
        print("\n5. Obteniendo historial de resultados del paciente...")
        r = client.get(f"{BASE_URL}/sessions/results/latest?patient_id={patient_id}", headers=headers)
        if r.status_code == 200:
            results = r.json()
            print(f"Resultados encontrados: {len(results)}")
            for res in results:
                print(f" - Juego: {res['game_name']} | Score: {res['score']}")
        else:
            print(f"Error obteniendo historial: {r.text}")
            return

        print("\n¡Todas las pruebas de Pacientes y Sesiones pasaron exitosamente!")

    except Exception as e:
        print(f"Error durante la ejecución: {e}")

if __name__ == "__main__":
    test_patient_and_session_flow()
