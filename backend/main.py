from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import users, patients, sessions
from app.database import engine, Base
from app import models

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="NeuroApp Backend",
    description="Backend API for Neuropsychological Evaluation App",
    version="0.1.0"
)

# Configure CORS (permitir cualquier puerto local para Flutter Web)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1):\d+",
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
