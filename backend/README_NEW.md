# NeuroApp Backend - Clean Architecture

Este backend ha sido refactorizado siguiendo los principios de **Clean Architecture** para garantizar escalabilidad, testabilidad y desacoplamiento.

## Estructura del Proyecto

```text
app/
├── api/            # Capa de Controladores (FastAPI Routers)
│   └── v1/         # Versión 1 de la API
├── application/    # Capa de Casos de Uso (Servicios de Negocio)
├── core/           # Configuraciones Globales y Seguridad
├── domain/         # Capa de Entidades (Modelos Pydantic / Lógica Pura)
└── infrastructure/ # Capa de Implementación (Base de Datos / SQLAlchemy)
```

## Requisitos

- Python 3.10+
- FastAPI
- SQLAlchemy
- Pydantic Settings

## Instalación

1. Crear un entorno virtual:
   ```bash
   python -m venv venv
   source venv/bin/activate  # En Windows: venv\Scripts\activate
   ```

2. Instalar dependencias:
   ```bash
   pip install -r requirements.txt
   ```

3. Configurar el archivo `.env` basado en `.env.example`.

## Ejecución

Para ejecutar el servidor con la nueva arquitectura:

```bash
uvicorn main_v2:app --reload
```

La documentación interactiva estará disponible en:
- Swagger UI: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`
