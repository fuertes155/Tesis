from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.infrastructure.database import get_db
from app.infrastructure import models
from app.application.services import PatientService
from app.domain import entities
from app.api.deps import get_current_user, require_roles
from app.core.audit import log_action

router = APIRouter()


@router.get("/", response_model=List[entities.Patient])
def read_patients(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    _user=Depends(require_roles("doctor", "gestor")),
):
    return PatientService.get_patients(db, skip=skip, limit=limit)


@router.get("/{patient_id}", response_model=entities.Patient)
def read_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    _user=Depends(require_roles("doctor", "gestor")),
):
    patient = PatientService.get_patient(db, patient_id=patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient


@router.post("/", response_model=entities.Patient)
def create_patient(
    patient: entities.PatientCreate,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    result = PatientService.create_patient(db=db, patient=patient)

    log_action(
        db=db,
        user_id=_user.id,
        action="CREATE",
        entity_type="Patient",
        entity_id=result.id,
        new_value=patient.model_dump(),
    )

    return result


@router.delete("/{patient_id}")
def delete_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("gestor")),
):
    # Capture old data before deletion
    db_patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if not db_patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    old_data = {
        "id": db_patient.id,
        "name": db_patient.name,
        "document_id": db_patient.document_id,
    }

    success = PatientService.delete_patient(db, patient_id=patient_id)
    if not success:
        raise HTTPException(status_code=404, detail="Patient not found")

    log_action(
        db=db,
        user_id=_user.id,
        action="DELETE",
        entity_type="Patient",
        entity_id=patient_id,
        old_value=old_data,
    )

    return {"status": "deleted", "id": patient_id}


@router.put("/{patient_id}/assign-doctor", response_model=entities.Patient)
def assign_doctor(
    patient_id: int,
    doctor_id: int,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("gestor")),
):
    patient = PatientService.assign_doctor(db, patient_id=patient_id, doctor_id=doctor_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient or Doctor not found")

    log_action(
        db=db,
        user_id=_user.id,
        action="UPDATE",
        entity_type="Patient",
        entity_id=patient_id,
        new_value={"doctor_id": doctor_id},
    )

    return patient


@router.put("/{patient_id}", response_model=entities.Patient)
def update_patient(
    patient_id: int,
    payload: entities.PatientUpdate,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")

    old_data = {k: getattr(patient, k) for k in payload.model_dump(exclude_unset=True).keys()}

    data = payload.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(patient, k, v)

    db.commit()
    db.refresh(patient)

    log_action(
        db=db,
        user_id=_user.id,
        action="UPDATE",
        entity_type="Patient",
        entity_id=patient_id,
        old_value=old_data,
        new_value=data,
    )

    return patient
