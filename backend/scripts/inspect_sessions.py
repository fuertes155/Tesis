import argparse
import os
import sqlite3


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=os.path.join("backend", "sql_app_v2.db"))
    parser.add_argument("--patient-id", type=int, default=1)
    parser.add_argument("--limit", type=int, default=20)
    args = parser.parse_args()

    db_path = args.db
    if not os.path.isabs(db_path):
        db_path = os.path.join(os.getcwd(), db_path)

    if not os.path.exists(db_path):
        print(f"No existe la BD: {db_path}")
        return 1

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        rows = conn.execute(
            """
            SELECT id, patient_id, date, status, substr(notes, 1, 180) AS notes_preview
            FROM sessions
            WHERE patient_id = ?
            ORDER BY id DESC
            LIMIT ?
            """,
            (args.patient_id, args.limit),
        ).fetchall()
    finally:
        conn.close()

    print(f"DB: {db_path}")
    print(f"Sesiones (patient_id={args.patient_id}) -> {len(rows)} filas")
    for r in rows:
        print(
            f"- id={r['id']} date={r['date']} status={r['status']} notes={r['notes_preview']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

