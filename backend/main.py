from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import users, patients, sessions
from app.infrastructure.database import engine, Base, SessionLocal
from app.infrastructure import models
from app.core.security import get_password_hash
from app.core.config import settings
from sqlalchemy import text
import time
import logging

# Create database tables
print(f"DEBUG: Using database URL: {settings.DATABASE_URL}")
Base.metadata.create_all(bind=engine)

def _ensure_db_schema() -> None:
    if not settings.DATABASE_URL.startswith("sqlite"):
        return
    with engine.begin() as conn:
        # sessions table
        cols_s = {r[1] for r in conn.execute(text("PRAGMA table_info(sessions)")).fetchall()}
        if "external_id" not in cols_s:
            conn.execute(text("ALTER TABLE sessions ADD COLUMN external_id TEXT"))
        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_sessions_external_id ON sessions(external_id)"))

        # users table
        cols_u = {r[1] for r in conn.execute(text("PRAGMA table_info(users)")).fetchall()}
        if "full_name" not in cols_u:
            conn.execute(text("ALTER TABLE users ADD COLUMN full_name TEXT"))

        # patients table
        cols_p = {r[1] for r in conn.execute(text("PRAGMA table_info(patients)")).fetchall()}
        if "user_id" not in cols_p:
            conn.execute(text("ALTER TABLE patients ADD COLUMN user_id INTEGER"))

_ensure_db_schema()

def _ensure_seed_users() -> None:
    db = SessionLocal()
    try:
        seeds = [
            {"username": "samuel@gmail.com", "role": "doctor", "is_available": True},
            {"username": "samuel1@gmail.com", "role": "gestor", "is_available": True},
        ]
        default_password = "Password123!"
        for s in seeds:
            uname = s["username"].strip().lower()
            u = db.query(models.User).filter(models.User.username == uname).first()
            if not u:
                u = models.User(
                    username=uname,
                    hashed_password=get_password_hash(default_password),
                    role=s["role"],
                    is_active=True,
                    is_available=s["is_available"],
                )
                db.add(u)
            else:
                if u.role != s["role"]:
                    u.role = s["role"]
                if u.is_active is False:
                    u.is_active = True
                if s["role"] == "doctor":
                    u.is_available = bool(s["is_available"])
        db.commit()
    finally:
        db.close()

_ensure_seed_users()

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend API for Neuropsychological Evaluation App (Clean Architecture)",
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

_logger = logging.getLogger("neuroapp")

@app.middleware("http")
async def request_log_middleware(request, call_next):
    start = time.perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        elapsed_ms = (time.perf_counter() - start) * 1000.0
        _logger.exception(
            "HTTP %s %s -> EXCEPTION (%.1fms)",
            request.method,
            request.url.path,
            elapsed_ms,
        )
        raise
    elapsed_ms = (time.perf_counter() - start) * 1000.0
    _logger.info(
        "HTTP %s %s -> %s (%.1fms)",
        request.method,
        request.url.path,
        response.status_code,
        elapsed_ms,
    )
    return response

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers with explicit tags
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(patients.router, prefix=f"{settings.API_V1_STR}/patients", tags=["patients"])
app.include_router(sessions.router, prefix=f"{settings.API_V1_STR}/sessions", tags=["sessions"])

@app.get("/")
def read_root():
    return {"message": f"Welcome to {settings.PROJECT_NAME}"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
