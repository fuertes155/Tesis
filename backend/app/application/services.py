from sqlalchemy.orm import Session
from app.infrastructure import models
from app.domain import entities
from app.core import security

class UserService:
    @staticmethod
    def get_user_by_username(db: Session, username: str):
        return db.query(models.User).filter(models.User.username == username).first()

    @staticmethod
    def create_user(db: Session, user: entities.UserCreate):
        hashed_password = security.get_password_hash(user.password)
        db_user = models.User(
            username=user.username,
            hashed_password=hashed_password,
            role=user.role,
            full_name=user.full_name
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user

class PatientService:
    @staticmethod
    def get_patients(db: Session, skip: int = 0, limit: int = 100):
        return db.query(models.Patient).offset(skip).limit(limit).all()

    @staticmethod
    def get_patient(db: Session, patient_id: int):
        return db.query(models.Patient).filter(models.Patient.id == patient_id).first()

    @staticmethod
    def create_patient(db: Session, patient: entities.PatientCreate):
        data = patient.model_dump()
        data.pop("has_consent", None)
        db_patient = models.Patient(**data)
        db.add(db_patient)
        db.commit()
        db.refresh(db_patient)
        return db_patient

    @staticmethod
    def delete_patient(db: Session, patient_id: int):
        db_patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
        if db_patient:
            db.query(models.Session).filter(models.Session.patient_id == patient_id).delete(synchronize_session=False)
            db.delete(db_patient)
            db.commit()
            return True
        return False

    @staticmethod
    def assign_doctor(db: Session, patient_id: int, doctor_id: int):
        db_patient = db.query(models.Patient).filter(models.Patient.id == patient_id).first()
        if not db_patient:
            return None
        
        db_doctor = db.query(models.User).filter(models.User.id == doctor_id, models.User.role == "doctor").first()
        if not db_doctor:
            return None
        
        db_patient.doctor_id = doctor_id
        db.commit()
        db.refresh(db_patient)
        return db_patient

class SessionService:
    @staticmethod
    def get_sessions(db: Session, skip: int = 0, limit: int = 100):
        return db.query(models.Session).offset(skip).limit(limit).all()

    @staticmethod
    def create_session(db: Session, session: entities.SessionCreate):
        db_session = models.Session(**session.model_dump())
        db.add(db_session)
        db.commit()
        db.refresh(db_session)
        return db_session
