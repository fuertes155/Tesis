"""Pruebas unitarias de seguridad: contraseñas, tokens JWT y política de claves."""
from datetime import timedelta

import pytest
from jwt import InvalidTokenError as JWTError

from app.api.v1.users import _is_strong_password
from app.core.security import (
    create_access_token,
    decode_access_token,
    get_password_hash,
    verify_password,
)


# ── Hash de contraseñas ───────────────────────────────────────────────────────

def test_hash_no_guarda_la_contrasena_en_texto_plano():
    hash_ = get_password_hash("Password123!")
    assert "Password123!" not in hash_
    assert hash_.startswith("$pbkdf2-sha256$")


def test_hash_es_distinto_cada_vez_por_la_sal():
    assert get_password_hash("Password123!") != get_password_hash("Password123!")


def test_verificar_contrasena_correcta():
    assert verify_password("Password123!", get_password_hash("Password123!")) is True


def test_verificar_contrasena_incorrecta():
    assert verify_password("otraClave1", get_password_hash("Password123!")) is False


def test_verificar_con_hash_invalido_devuelve_false_sin_lanzar_error():
    assert verify_password("Password123!", "esto-no-es-un-hash") is False


# ── Tokens JWT ────────────────────────────────────────────────────────────────

def test_token_contiene_usuario_rol_y_expiracion():
    payload = decode_access_token(create_access_token("ana@example.com", "doctor"))
    assert payload["sub"] == "ana@example.com"
    assert payload["role"] == "doctor"
    assert payload["exp"] > payload["iat"]


def test_token_respeta_la_duracion_indicada():
    payload = decode_access_token(create_access_token("ana@example.com", "doctor", timedelta(minutes=5)))
    assert payload["exp"] - payload["iat"] == 300


def test_token_expirado_es_rechazado():
    token = create_access_token("ana@example.com", "doctor", timedelta(seconds=-1))
    with pytest.raises(JWTError):
        decode_access_token(token)


def test_token_alterado_es_rechazado():
    token = create_access_token("ana@example.com", "doctor")
    cabecera, cuerpo, firma = token.split(".")
    firma_alterada = ("A" if firma[0] != "A" else "B") + firma[1:]
    with pytest.raises(JWTError):
        decode_access_token(f"{cabecera}.{cuerpo}.{firma_alterada}")


# ── Política de contraseñas ───────────────────────────────────────────────────

@pytest.mark.parametrize(
    ("clave", "esperado"),
    [
        ("Password123!", True),
        ("Abcdefg1", True),        # exactamente 8 caracteres
        ("Abcdef1", False),        # 7 caracteres
        ("password123", False),    # sin mayúscula
        ("PASSWORD123", False),    # sin minúscula
        ("Passwordxyz", False),    # sin dígito
        ("", False),
    ],
)
def test_politica_de_contrasena_segura(clave, esperado):
    assert _is_strong_password(clave) is esperado
