from app import schemas


def test_user_create_schema_accepts_payload():
    payload = {
        "username": "test@example.com",
        "password": "password",
        "role": "gestor",
        "full_name": "Test Gestor",
    }

    user_create = schemas.UserCreate(**payload)

    assert user_create.username == "test@example.com"
    assert user_create.role == "gestor"
    assert user_create.full_name == "Test Gestor"
