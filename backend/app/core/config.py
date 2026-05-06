import os
from pydantic_settings import BaseSettings, SettingsConfigDict

# Get the directory of the current file (config.py)
# backend/app/core/config.py -> backend/
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_FILE = os.path.join(ROOT_DIR, ".env")

class Settings(BaseSettings):
    PROJECT_NAME: str = "NeuroApp API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    SECRET_KEY: str = "dev-secret-change-me"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24
    
    DATABASE_URL: str = "sqlite:///./data/sql_app.db"
    
    model_config = SettingsConfigDict(env_file=ENV_FILE)

settings = Settings()
