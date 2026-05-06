import sys
sys.path.append('d:/Tesis/NeuroApp360/backend')

from app import models
from app.database import Base, SessionLocal, engine

Base.metadata.create_all(bind=engine)
db = SessionLocal()

user = models.User(
    username="gestortest1@example.com",
    hashed_password="foo",
    full_name="Gestor Test",
    role="gestor",
    is_active=True,
    is_available=True
)
db.add(user)
db.commit()
db.refresh(user)

print("Created user:", user.username, "Role:", user.role)

from app.routers.users import _create_role_profile
_create_role_profile(db, user)

doctor_count = db.query(models.Doctor).filter(models.Doctor.user_id == user.id).count()
gestor_count = db.query(models.Administrator).filter(models.Administrator.user_id == user.id).count()
patient_count = db.query(models.Patient).filter(models.Patient.user_id == user.id).count()

print(f"Doctor: {doctor_count}, Gestor: {gestor_count}, Patient: {patient_count}")

db.close()
