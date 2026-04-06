import os
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from jose import JWTError, jwt
from passlib.context import CryptContext

_pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

_ALGORITHM = "HS256"
_DEFAULT_EXPIRE_MINUTES = 60 * 24


def _secret_key() -> str:
    return os.environ.get("NEUROAPP_SECRET_KEY") or "dev-secret-change-me"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return _pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return _pwd_context.hash(password)


def create_access_token(subject: str, role: str, expires_delta: timedelta | None = None) -> str:
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(minutes=_DEFAULT_EXPIRE_MINUTES))
    payload = {
        "sub": subject,
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(payload, _secret_key(), algorithm=_ALGORITHM)


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, _secret_key(), algorithms=[_ALGORITHM])
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
