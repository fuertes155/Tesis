"""Lecturas autenticadas; los 429 cuentan como errores y no se ocultan."""
import os
from locust import HttpUser, between, task


class Profesional(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        self.client.headers["Authorization"] = f"Bearer {os.environ['QA_TOKEN']}"

    @task(3)
    def pacientes(self):
        self.client.get("/api/v1/patients/")

    @task(2)
    def sesiones(self):
        self.client.get("/api/v1/sessions/")

    @task
    def resultados(self):
        self.client.get("/api/v1/sessions/results/latest",
                        params={"patient_id": os.environ["QA_PATIENT_ID"]})
