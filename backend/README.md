# Backend (FastAPI)

## Ejecutar

```powershell
cd d:\Tesis\flutter_application_1\backend
python -B -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Endpoints:

- http://127.0.0.1:8000/health
- http://127.0.0.1:8000/docs

## Conectar con el Frontend

El frontend usa la variable `API_BASE_URL` (dart-define). Para web local:

```powershell
cd d:\Tesis\flutter_application_1
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 55912 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Para ejecutar ambos desde VS Code: `Terminal → Run Task… → dev: fullstack`.

## Pruebas rápidas (sin extensiones)

Con el backend corriendo:

```powershell
cd d:\Tesis\flutter_application_1
python backend\scripts\smoke_auth.py
```

## Registro y login

- Login (token): `POST /users/auth/login`
- Registro (token): `POST /users/auth/register`

Ambos esperan JSON:

```json
{
  "username": "correo@dominio.com",
  "password": "Password123!"
}
```
