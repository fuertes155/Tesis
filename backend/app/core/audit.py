import json
from sqlalchemy.orm import Session
from app.models import AuditLog
from typing import Any, Optional

def log_action(
    db: Session,
    user_id: Optional[int],
    action: str,
    entity_type: str,
    entity_id: Optional[int] = None,
    old_value: Any = None,
    new_value: Any = None,
):
    """
    Records an audit log entry in the database.
    """
    db_log = AuditLog(
        user_id=user_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        old_value=json.dumps(old_value) if old_value else None,
        new_value=json.dumps(new_value) if new_value else None,
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log
