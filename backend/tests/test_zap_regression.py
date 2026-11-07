"""Reproduce los payloads de ZAP 40018 y verifica almacenamiento literal y conteos."""
import pytest


@pytest.mark.parametrize("payload", ["scheduled' AND '1'='1' -- ", "scheduled' OR '1'='1' -- "])
def test_zap_session_payload_is_literal_data(client, doctor_headers, crear_paciente, payload):
    patient = crear_paciente()
    route = "/api/v1/sessions/"
    before = client.get("/api/v1/sessions/count", params={"patient_id": patient['id']}, headers=doctor_headers).json()["count"]
    result = client.post(route, headers=doctor_headers, json={"patient_id": patient['id'],
        "date": "2026-11-06T10:00:00", "status": payload})
    assert result.status_code == 200
    stored = client.get(f"{route}{result.json()['id']}", headers=doctor_headers).json()
    assert stored["status"] == payload
    after = client.get("/api/v1/sessions/count", params={"patient_id": patient['id']}, headers=doctor_headers).json()["count"]
    assert after == before + 1


@pytest.mark.parametrize("payload", ["John Doe' AND '1'='1' -- ", "John Doe' OR '1'='1' -- "])
def test_zap_result_payload_does_not_select_other_records(client, doctor_headers, crear_paciente, payload):
    patient = crear_paciente()
    response = client.post('/api/v1/sessions/results', headers=doctor_headers, json={
        'patient_id': patient['id'], 'game_name': 'QA', 'score': 50,
        'details': {payload: payload}, 'metrics': {payload: 1}})
    assert response.status_code == 201
    results = client.get('/api/v1/sessions/results/latest',
        params={'patient_id': patient['id']}, headers=doctor_headers).json()
    assert len(results) == 1
    assert results[0]['details'] == {payload: payload}
    assert results[0]['metrics'] == {payload: 1}
