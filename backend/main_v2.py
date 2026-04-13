from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .app.core.config import settings
from .app.api.v1 import users, patients, sessions
from .app.infrastructure.database import engine, Base

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(patients.router, prefix=f"{settings.API_V1_STR}/patients", tags=["patients"])
app.include_router(sessions.router, prefix=f"{settings.API_V1_STR}/sessions", tags=["sessions"])

@app.get("/")
def read_root():
    return {"message": "Welcome to NeuroApp API V2 (Clean Architecture)"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
