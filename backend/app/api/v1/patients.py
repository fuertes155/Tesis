from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ....infrastructure.database import get_db
from ....application.services import PatientService
from ....domain import entities
from ..deps import require_roles

router = APIRouter()

@router.get("/", response_model=List[entities.Patient])
def read_patients(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    _user = Depends(require_roles("doctor", "gestor"))
):
    return PatientService.get_patients(db, skip=skip, limit=limit)

@router.get("/{patient_id}", response_model=entities.Patient)
def read_patient(
    patient_id: int, 
    db: Session = Depends(get_db),
    _user = Depends(require_roles("doctor", "gestor"))
):
    patient = PatientService.get_patient(db, patient_id=patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient

@router.post("/", response_model=entities.Patient)
def create_patient(
    patient: entities.PatientCreate, 
    db: Session = Depends(get_db),
    _user = Depends(require_roles("doctor", "gestor"))
):
    return PatientService.create_patient(db=db, patient=patient)

@router.delete("/{patient_id}")
def delete_patient(
    patient_id: int, 
    db: Session = Depends(get_db),
    _user = Depends(require_roles("gestor"))
):
    success = PatientService.delete_patient(db, patient_id=patient_id)
    if not success:
        raise HTTPException(status_code=404, detail="Patient not found")
    return {"status": "deleted", "id": patient_id}

@router.put("/{patient_id}/assign-doctor", response_model=entities.Patient)
def assign_doctor(
    patient_id: int, 
    doctor_id: int, 
    db: Session = Depends(get_db),
    _user = Depends(require_roles("gestor"))
):
    patient = PatientService.assign_doctor(db, patient_id=patient_id, doctor_id=doctor_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient or Doctor not found")
    return patient
