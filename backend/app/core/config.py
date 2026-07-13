from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# Get the directory of the current file (config.py)
# backend/app/core/config.py -> backend/
ROOT_DIR = Path(__file__).resolve().parents[2]
ENV_FILE = ROOT_DIR / ".env"


def _resolve_sqlite_url(url: str) -> str:
    if not url.startswith("sqlite:///"):
        return url

    db_path = url.removeprefix("sqlite:///")
    if db_path == ":memory:":
        return url

    path = Path(db_path)
    if path.is_absolute():
        return url

    return f"sqlite:///{(ROOT_DIR / path).resolve().as_posix()}"

class Settings(BaseSettings):
    PROJECT_NAME: str = "NeuroApp API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    SECRET_KEY: str = "dev-secret-change-me"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24
    DEFAULT_ADMIN_PASSWORD: str = "ChangeMeNow123!"
    
    DATABASE_URL: str = "sqlite:///./data/sql_app.db"
    CORS_ORIGINS: str = "http://localhost:55912,http://127.0.0.1:55912"
    
    model_config = SettingsConfigDict(env_file=ENV_FILE)

settings = Settings()
settings.DATABASE_URL = _resolve_sqlite_url(settings.DATABASE_URL)
