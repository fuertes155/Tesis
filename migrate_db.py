import sqlite3
import os

db_paths = [
    "backend/data/sql_app_v2.db",
    "backend/data/sql_app.db",
    "sql_app.db",
    "backend/data/neuroapp.db"
]

for db_path in db_paths:
    if os.path.exists(db_path):
        print(f"Migrando base de datos en {db_path}...")
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Columnas a agregar
        cols = [
            ("users", "is_2fa_enabled", "BOOLEAN DEFAULT 0"),
            ("users", "totp_secret", "TEXT"),
            ("users", "full_name", "TEXT"),
            ("patients", "created_at", "DATETIME DEFAULT CURRENT_TIMESTAMP"),
            ("sessions", "duration_ms", "INTEGER DEFAULT 0")
        ]
        
        for table, col, col_type in cols:
            try:
                cursor.execute(f"ALTER TABLE {table} ADD COLUMN {col} {col_type}")
                print(f"Agregada columna {col} a {table}")
            except sqlite3.OperationalError:
                print(f"Columna {col} en {table} ya existe")
            
        conn.commit()
        conn.close()
        print(f"Migración de {db_path} completada.")
    else:
        print(f"Base de datos no encontrada en {db_path}")
