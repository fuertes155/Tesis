import asyncio
import os
import sys

sys.path.insert(0, os.getcwd())

from app.ollama_service import generar_reporte_cognitivo

sample = {
    "paciente_id": "P001",
    "nombre_paciente": "Ana",
    "edad_paciente": 45,
    "fecha_evaluacion": "2026-05-28",
    "profesional": "Dr. Test",
    "pruebas": [
        {"nombre_prueba": f"Prueba {i}", "porcentaje_obtenido": float(50 + i), "tiempo_segundos": 60 + i}
        for i in range(8)
    ],
}


async def main():
    try:
        reporte = await generar_reporte_cognitivo(sample)
        print("RESPONSE_LENGTH", len(reporte))
        print(reporte[:500])
    except Exception as exc:
        print(type(exc).__name__)
        print(exc)


asyncio.run(main())
