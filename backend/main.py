from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import users, patients, sessions
from app.routers import reportes
from app.infrastructure.database import engine, Base, SessionLocal
from app.infrastructure import models
from app.core.security import get_password_hash
from app.core.config import settings
from sqlalchemy import text
import time
import logging
from collections import defaultdict
from datetime import datetime, timezone

# Create database tables
logging.getLogger("neuroapp").info("Starting database initialization…")
Base.metadata.create_all(bind=engine)

def _ensure_db_schema() -> None:
    if not settings.DATABASE_URL.startswith("sqlite"):
        return
    with engine.begin() as conn:
        # sessions table
        cols_s = {r[1] for r in conn.execute(text("PRAGMA table_info(sessions)")).fetchall()}
        if "external_id" not in cols_s:
            conn.execute(text("ALTER TABLE sessions ADD COLUMN external_id TEXT"))
        if "created_at" not in cols_s:
            conn.execute(text("ALTER TABLE sessions ADD COLUMN created_at DATETIME"))
            conn.execute(text("UPDATE sessions SET created_at = datetime('now') WHERE created_at IS NULL"))
        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_sessions_external_id ON sessions(external_id)"))

        # users table
        cols_u = {r[1] for r in conn.execute(text("PRAGMA table_info(users)")).fetchall()}
        if "full_name" not in cols_u:
            conn.execute(text("ALTER TABLE users ADD COLUMN full_name TEXT"))
        if "is_2fa_enabled" not in cols_u:
            conn.execute(text("ALTER TABLE users ADD COLUMN is_2fa_enabled BOOLEAN DEFAULT 0"))
        if "totp_secret" not in cols_u:
            conn.execute(text("ALTER TABLE users ADD COLUMN totp_secret TEXT"))

        # patients table
        cols_p = {r[1] for r in conn.execute(text("PRAGMA table_info(patients)")).fetchall()}
        if "user_id" not in cols_p:
            conn.execute(text("ALTER TABLE patients ADD COLUMN user_id INTEGER"))
        if "email" not in cols_p:
            conn.execute(text("ALTER TABLE patients ADD COLUMN email TEXT"))
        if "external_id" not in cols_p:
            conn.execute(text("ALTER TABLE patients ADD COLUMN external_id TEXT"))
            conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_patients_external_id ON patients(external_id)"))
        if "created_at" not in cols_p:
            conn.execute(text("ALTER TABLE patients ADD COLUMN created_at DATETIME"))
            if "registration_date" in cols_p:
                conn.execute(text("UPDATE patients SET created_at = registration_date WHERE created_at IS NULL"))
            conn.execute(text("UPDATE patients SET created_at = datetime('now') WHERE created_at IS NULL"))

_ensure_db_schema()

def _ensure_seed_users() -> None:
    db = SessionLocal()
    try:
        seeds = [
            {"username": "samuel@gmail.com", "role": "doctor", "is_available": True},
            {"username": "samuel1@gmail.com", "role": "gestor", "is_available": True},
        ]
        default_password = settings.DEFAULT_ADMIN_PASSWORD
        for s in seeds:
            uname = str(s["username"]).strip().lower()
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
                    u.role = str(s["role"])
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
_start_time = time.time()


def _cors_origins() -> list[str]:
    return [
        origin.strip()
        for origin in settings.CORS_ORIGINS.split(",")
        if origin.strip()
    ]

# ── Rate Limiter (in-memory, per-IP and route) ───────────────────────────────
_rate_limit_store: dict[str, list[float]] = defaultdict(list)
RATE_LIMIT_WINDOW = 60   # seconds
RATE_LIMIT_MAX = 200     # max requests per window


@app.middleware("http")
async def security_headers_middleware(request: Request, call_next):
    """Add security headers, timing headers, and basic rate limiting."""
    # ── Rate Limiting ─────────────────────────────────────────────────────────
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        client_ip = forwarded.split(",")[0].strip()
    else:
        client_ip = request.headers.get("X-Real-IP", request.client.host if request.client else "unknown")
    
    rate_limit_key = f"{client_ip}:{request.method}:{request.url.path}"
    now = time.time()
    # Clean old entries
    _rate_limit_store[rate_limit_key] = [
        t for t in _rate_limit_store[rate_limit_key] if now - t < RATE_LIMIT_WINDOW
    ]
    if len(_rate_limit_store[rate_limit_key]) >= RATE_LIMIT_MAX:
        return Response(
            content='{"detail":"Too many requests. Try again later."}',
            status_code=429,
            media_type="application/json",
            headers={
                "Retry-After": str(RATE_LIMIT_WINDOW),
                "X-RateLimit-Limit": str(RATE_LIMIT_MAX),
                "X-RateLimit-Remaining": "0",
            },
        )
    _rate_limit_store[rate_limit_key].append(now)

    # ── Execute Request & Measure Latency ─────────────────────────────────────
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

    # ── Latency / Timing Headers ──────────────────────────────────────────────
    response.headers["X-Response-Time"] = f"{elapsed_ms:.1f}ms"
    response.headers["X-Request-Id"] = f"{int(now * 1000)}"

    # ── Rate Limit Info Headers ───────────────────────────────────────────────
    remaining = RATE_LIMIT_MAX - len(_rate_limit_store[rate_limit_key])
    response.headers["X-RateLimit-Limit"] = str(RATE_LIMIT_MAX)
    response.headers["X-RateLimit-Remaining"] = str(max(remaining, 0))

    # ── Security Headers (OWASP) ──────────────────────────────────────────────
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(self), geolocation=()"
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
    response.headers["Pragma"] = "no-cache"

    # ── Logging ───────────────────────────────────────────────────────────────
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
    allow_origins=_cors_origins(),
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Response-Time", "X-Request-Id", "X-RateLimit-Limit", "X-RateLimit-Remaining"],
)


# Include Routers with explicit tags
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(patients.router, prefix=f"{settings.API_V1_STR}/patients", tags=["patients"])
app.include_router(sessions.router, prefix=f"{settings.API_V1_STR}/sessions", tags=["sessions"])
app.include_router(reportes.router, tags=["reportes"])

@app.get("/")
def read_root():
    return {"message": f"Welcome to {settings.PROJECT_NAME}"}

@app.get("/health")
def health_check():
    """Comprehensive health check for availability testing."""
    uptime_seconds = time.time() - _start_time
    db = SessionLocal()
    db_ok = False
    try:
        db.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        pass
    finally:
        db.close()
    return {
        "status": "healthy" if db_ok else "degraded",
        "uptime_seconds": round(uptime_seconds, 1),
        "database": "connected" if db_ok else "error",
        "version": settings.VERSION,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

@app.get("/readiness")
def readiness_check():
    """Kubernetes-style readiness probe for load balancers."""
    db = SessionLocal()
    try:
        db.execute(text("SELECT 1"))
        return {"ready": True}
    except Exception:
        return Response(
            content='{"ready":false}',
            status_code=503,
            media_type="application/json",
        )
    finally:
        db.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
