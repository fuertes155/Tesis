from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import users, patients, sessions
from app.database import engine, Base, SessionLocal
from app import models
from app.security import get_password_hash
from sqlalchemy import text

# Create database tables
Base.metadata.create_all(bind=engine)

def _ensure_db_schema() -> None:
    if not str(engine.url).startswith("sqlite"):
        return
    with engine.begin() as conn:
        cols = {r[1] for r in conn.execute(text("PRAGMA table_info(sessions)")).fetchall()}
        if "external_id" not in cols:
            conn.execute(text("ALTER TABLE sessions ADD COLUMN external_id TEXT"))
        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_sessions_external_id ON sessions(external_id)"))

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
    title="NeuroApp Backend",
    description="Backend API for Neuropsychological Evaluation App",
    version="0.1.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(users.router)
app.include_router(patients.router)
app.include_router(sessions.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to NeuroApp API"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
