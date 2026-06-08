import asyncio
import json
import os
import sys

import httpx

sys.path.insert(0, os.getcwd())

from app.ollama_service import construir_prompt

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

payload = {
    "model": "llama3",
    "prompt": construir_prompt(sample),
    "stream": False,
    "options": {
        "temperature": 0.35,
        "top_p": 0.85,
        "num_predict": 40,
    },
}


async def main():
    print("inicio")
    async with httpx.AsyncClient(timeout=httpx.Timeout(30.0)) as client:
        respuesta = await client.get("http://localhost:11434/api/tags")
        print(respuesta.text[:500])
        respuesta = await client.post("http://localhost:11434/api/generate", json=payload)
        print(respuesta.text[:2000])


asyncio.run(main())
