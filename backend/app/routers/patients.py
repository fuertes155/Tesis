from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app import schemas, models
from app.database import get_db
from app.deps import require_roles
from app.core.audit import log_action

router = APIRouter(
    prefix="/patients",
    tags=["patients"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[schemas.Patient])
def read_patients(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    patients = db.query(models.Patient).offset(skip).limit(limit).all()
    return patients

@router.post("/", response_model=schemas.Patient)
def create_patient(
    patient: schemas.PatientCreate,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    db_patient = models.Patient(**patient.model_dump())
    db.add(db_patient)
    db.commit()
    db.refresh(db_patient)
    
    log_action(
        db=db,
        user_id=_user.id,
        action="CREATE",
        entity_type="Patient",
        entity_id=db_patient.id,
        new_value=patient.model_dump()
    )
    
    return db_patient

@router.get("/{patient_id}", response_model=schemas.Patient)
def read_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient

@router.delete("/{patient_id}")
def delete_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("gestor")),
):
    patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    old_data = {
        "id": patient.id,
        "name": patient.name,
        "document_id": patient.document_id
    }
    
    db.query(models.Session).filter(models.Session.patient_id == patient_id).delete(synchronize_session=False)
    db.delete(patient)
    db.commit()
    
    log_action(
        db=db,
        user_id=_user.id,
        action="DELETE",
        entity_type="Patient",
        entity_id=patient_id,
        old_value=old_data
    )
    
    return {"status": "deleted", "id": patient_id}

@router.put("/{patient_id}/assign-doctor", response_model=schemas.Patient)
def assign_doctor(
    patient_id: int,
    doctor_id: int,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("gestor")),
):
    db_patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
    if not db_patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    db_doctor = db.query(models.User).filter(models.User.id == doctor_id, models.User.role == "doctor").first()
    if not db_doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    db_patient.doctor_id = doctor_id
    db.commit()
    db.refresh(db_patient)
    
    log_action(
        db=db,
        user_id=_user.id,
        action="UPDATE",
        entity_type="Patient",
        entity_id=patient_id,
        new_value={"doctor_id": doctor_id}
    )
    
    return db_patient

@router.put("/{patient_id}", response_model=schemas.Patient)
def update_patient(
    patient_id: int,
    payload: schemas.PatientUpdate,
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
        new_value=data
    )
    
    return patient
