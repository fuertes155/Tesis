import uuid

from app import models
from app.database import Base, SessionLocal, engine
from app.routers.users import _create_role_profile


def test_role_profile_creation():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        user = models.User(
            username=f"gestortest1+{uuid.uuid4().hex}@example.com",
            hashed_password="foo",
            full_name="Gestor Test",
            role="gestor",
            is_active=True,
            is_available=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        _create_role_profile(db, user)

        doctor_count = db.query(models.Doctor).filter(models.Doctor.user_id == user.id).count()
        gestor_count = db.query(models.Administrator).filter(models.Administrator.user_id == user.id).count()
        patient_count = db.query(models.Patient).filter(models.Patient.user_id == user.id).count()

        assert user.role == "gestor"
        assert doctor_count == 0
        assert gestor_count == 1
        assert patient_count == 0
    finally:
        db.close()
