"""
Datos de partida para la prueba E2E, sobre el backend de PRUEBAS (BD temporal).

Uso:  python e2e_semilla.py <url_backend> <ruta_bd_sqlite>
Crea un paciente asignado al doctor semilla, dos evaluaciones en fechas distintas
(para la gráfica de evolución) y un informe.
"""
import json
import sqlite3
import sys
import urllib.request

URL, RUTA_BD = sys.argv[1].rstrip("/"), sys.argv[2]
API = f"{URL}/api/v1"


def http(metodo, url, cuerpo=None, token=None):
    req = urllib.request.Request(url, method=metodo,
                                 data=json.dumps(cuerpo).encode() if cuerpo is not None else None)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read().decode())


if "pruebas" not in RUTA_BD and "e2e" not in RUTA_BD:
    sys.exit(f"Por seguridad, la semilla solo se aplica a una BD de pruebas: {RUTA_BD}")

login = http("POST", f"{API}/users/auth/login", {"username": "samuel@gmail.com", "password": "Password123!"})
token, doctor_id = login["access_token"], login["user"]["id"]

paciente = http("POST", f"{API}/patients/", {
    "name": "Elena Ruiz Prueba E2E", "age": 72, "birth_date": "1954-03-10", "document_id": "E2E-0001",
    "phone": "3000000000", "diagnosis": "Deterioro cognitivo leve (amnésico)", "institution": "Consulta externa",
    "medical_history": "Paciente ficticio para pruebas automatizadas.", "doctor_id": doctor_id, "has_consent": True,
}, token)
pid = paciente["id"]

ids_previa = []
for numero, puntajes in enumerate([(55, 76, 70, 74), (48, 72, 66, 70)]):
    for juego, puntaje in zip(["visual_memory", "reaction", "stroop", "fluency"], puntajes):
        r = http("POST", f"{API}/sessions/results",
                 {"patient_id": pid, "game_name": juego, "score": puntaje, "details": {}, "metrics": {}}, token)
        if numero == 0:
            ids_previa.append(r["id"])

# La primera evaluación pasa a junio para que la gráfica tenga dos fechas.
with sqlite3.connect(RUTA_BD) as c:
    c.executemany("UPDATE results SET timestamp = '2026-06-01 15:00:00' WHERE id = ?", [(i,) for i in ids_previa])

http("POST", f"{URL}/evaluacion/generar-reporte", {
    "paciente_id": "E2E-0001", "nombre_paciente": "Elena Ruiz Prueba E2E", "edad_paciente": 72,
    "fecha_evaluacion": "2026-06-01", "profesional": "Samuel Vanegas",
    "diagnostico_paciente": "Deterioro cognitivo leve (amnésico)",
    "pruebas": [{"nombre_prueba": n, "porcentaje_obtenido": p, "tiempo_segundos": 60}
                for n, p in zip(["Memoria Visual", "Atención Sostenida", "Funciones Ejecutivas (Stroop)",
                                 "Fluidez Verbal"], (55, 76, 70, 74))],
})
print(f"Semilla lista: paciente #{pid}")
