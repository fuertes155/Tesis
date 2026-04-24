from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Any, Optional

class ResultBase(BaseModel):
    game_name: str
    score: int
    details: Optional[dict[str, Any]] = None
    metrics: Optional[dict[str, Any]] = None
    patient_id: int
    session_id: Optional[int] = None

class ResultCreate(ResultBase):
    pass

class Result(ResultBase):
    id: int
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
