"""Contrato de autenticación tras sustituir python-jose por PyJWT."""
from datetime import timedelta
import time

import jwt
import pytest

from app.core.config import settings
from app.core.security import create_access_token, decode_access_token


def claims():
    return {"sub": "qa@example.com", "role": "doctor", "iat": int(time.time()),
            "exp": int(time.time()) + 300}


@pytest.mark.parametrize("missing", ["exp", "iat", "sub", "role"])
def test_missing_required_claim_is_rejected(missing):
    payload = claims()
    del payload[missing]
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    with pytest.raises(jwt.InvalidTokenError):
        decode_access_token(token)


@pytest.mark.parametrize("algorithm", ["none", "HS384"])
def test_disallowed_algorithm_is_rejected(algorithm):
    token = jwt.encode(claims(), "" if algorithm == "none" else settings.SECRET_KEY,
                       algorithm=algorithm)
    with pytest.raises(jwt.InvalidTokenError):
        decode_access_token(token)


def test_zero_duration_is_expired():
    with pytest.raises(jwt.ExpiredSignatureError):
        decode_access_token(create_access_token("qa@example.com", "doctor", timedelta(0)))


def test_wrong_key_is_rejected():
    token = jwt.encode(claims(), "another-test-key-with-at-least-32-characters", algorithm="HS256")
    with pytest.raises(jwt.InvalidTokenError):
        decode_access_token(token)


def test_invalid_token_returns_401_not_500(client):
    response = client.get("/api/v1/users/me", headers={"Authorization": "Bearer malformed"})
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"
