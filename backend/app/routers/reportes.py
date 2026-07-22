from __future__ import annotations

from datetime import date
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from app.core.audit import log_action
from app.infrastructure import models
from app.infrastructure.database import get_db
from app.ollama_service import OllamaNoDisponibleError, generar_reporte_cognitivo


router = APIRouter()


class PruebaCognitivaSchema(BaseModel):
    nombre_prueba: Annotated[str, Field(min_length=2, max_length=120)]
    porcentaje_obtenido: Annotated[float, Field(ge=0, le=100)]
    tiempo_segundos: Annotated[int, Field(ge=0)]
    detalles: dict[str, Any] | None = None
    metricas: dict[str, Any] | None = None

    @field_validator("nombre_prueba")
    @classmethod
    def validar_nombre_prueba(cls, valor: str) -> str:
        valor = valor.strip()
        if not valor:
            raise ValueError("El nombre de la prueba es obligatorio.")
        return valor


class EvaluacionCognitivaSchema(BaseModel):
    paciente_id: Annotated[str, Field(min_length=1, max_length=60)]
    nombre_paciente: Annotated[str, Field(min_length=2, max_length=160)]
    edad_paciente: Annotated[int, Field(ge=0, le=120)]
    fecha_evaluacion: date
    profesional: Annotated[str, Field(min_length=2, max_length=160)]
    pruebas: Annotated[list[PruebaCognitivaSchema], Field(min_length=1)]
    documento_paciente: Annotated[str | None, Field(max_length=60)] = None
    telefono_paciente: Annotated[str | None, Field(max_length=60)] = None
    diagnostico_paciente: Annotated[str | None, Field(max_length=240)] = None
    institucion: Annotated[str | None, Field(max_length=160)] = None

    @field_validator("paciente_id", "nombre_paciente", "profesional")
    @classmethod
    def validar_texto_obligatorio(cls, valor: str) -> str:
        valor = valor.strip()
        if not valor:
            raise ValueError("Este campo no puede estar vacío.")
        return valor

    @field_validator(
        "documento_paciente",
        "telefono_paciente",
        "diagnostico_paciente",
        "institucion",
    )
    @classmethod
    def validar_texto_opcional(cls, valor: str | None) -> str | None:
        if valor is None:
            return None
        valor = valor.strip()
        return valor or None


class ReporteCognitivoRespuestaSchema(BaseModel):
    id: int
    paciente_id: str
    nombre_paciente: str
    fecha_evaluacion: date
    reporte: str
    created_at: str


@router.post(
    "/evaluacion/generar-reporte",
    response_model=ReporteCognitivoRespuestaSchema,
)
async def generar_reporte(
    evaluacion: EvaluacionCognitivaSchema,
    db: Session = Depends(get_db),
):
    # Utilizamos directamente la función local para que la generación sea instantánea y mantenga el formato profesional.
    from app.ollama_service import generar_reporte_local
    reporte = generar_reporte_local(evaluacion.model_dump(mode="json"))

    paciente_db = _buscar_paciente(db, evaluacion)
    reporte_db = models.CognitiveReport(
        patient_db_id=paciente_db.id if paciente_db else None,
        paciente_id=evaluacion.paciente_id,
        nombre_paciente=evaluacion.nombre_paciente,
        edad_paciente=evaluacion.edad_paciente,
        fecha_evaluacion=evaluacion.fecha_evaluacion.isoformat(),
        profesional=evaluacion.profesional,
        pruebas=[prueba.model_dump(mode="json") for prueba in evaluacion.pruebas],
        reporte=reporte,
    )
    db.add(reporte_db)
    db.commit()
    db.refresh(reporte_db)

    log_action(
        db=db,
        user_id=None,
        action="CREATE",
        entity_type="CognitiveReport",
        entity_id=reporte_db.id,
        new_value={
            "paciente_id": evaluacion.paciente_id,
            "nombre_paciente": evaluacion.nombre_paciente,
            "fecha_evaluacion": evaluacion.fecha_evaluacion.isoformat(),
            "pruebas": [prueba.model_dump(mode="json") for prueba in evaluacion.pruebas],
        },
    )

    return ReporteCognitivoRespuestaSchema(
        id=reporte_db.id,
        paciente_id=evaluacion.paciente_id,
        nombre_paciente=evaluacion.nombre_paciente,
        fecha_evaluacion=evaluacion.fecha_evaluacion,
        reporte=reporte,
        created_at=reporte_db.created_at.isoformat(),
    )


@router.get(
    "/evaluacion/reportes/{paciente_id}",
    response_model=list[ReporteCognitivoRespuestaSchema],
)
def listar_reportes_paciente(paciente_id: str, db: Session = Depends(get_db)):
    reportes = (
        db.query(models.CognitiveReport)
        .filter(models.CognitiveReport.paciente_id == paciente_id)
        .order_by(models.CognitiveReport.created_at.desc())
        .all()
    )

    return [
        ReporteCognitivoRespuestaSchema(
            id=reporte.id,
            paciente_id=reporte.paciente_id,
            nombre_paciente=reporte.nombre_paciente,
            fecha_evaluacion=date.fromisoformat(reporte.fecha_evaluacion),
            reporte=reporte.reporte,
            created_at=reporte.created_at.isoformat(),
        )
        for reporte in reportes
    ]


def _buscar_paciente(
    db: Session,
    evaluacion: EvaluacionCognitivaSchema,
) -> models.Patient | None:
    paciente_por_documento = (
        db.query(models.Patient)
        .filter(models.Patient.document_id == evaluacion.paciente_id)
        .first()
    )
    if paciente_por_documento:
        return paciente_por_documento

    id_numerico = (
        int(evaluacion.paciente_id)
        if evaluacion.paciente_id.isdigit()
        else None
    )
    if id_numerico is not None:
        paciente_por_id = (
            db.query(models.Patient)
            .filter(models.Patient.id == id_numerico)
            .first()
        )
        if paciente_por_id:
            return paciente_por_id

    return (
        db.query(models.Patient)
        .filter(models.Patient.name == evaluacion.nombre_paciente)
        .first()
    )
