def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] in {"healthy", "degraded"}


def test_login_with_seeded_user(client):
    import time
    username = f"samuel1_{int(time.time())}@gmail.com"
    client.post("/api/v1/users/auth/register", json={"username": username, "password": "Password123!", "role": "doctor"})
    response = client.post(
        "/api/v1/users/auth/login",
        json={"username": username, "password": "Password123!"},
    )
    assert response.status_code == 200
    payload = response.json()
    assert "access_token" in payload
    assert payload["token_type"] == "bearer"
