# Importa la librería sqlite3 que permite interactuar con bases de datos SQLite
import sqlite3

# Define la función principal que listará los usuarios
def list_users():
    # Establece la conexión con el archivo de la base de datos 'sql_app.db'
    conn = sqlite3.connect('sql_app.db')
    # Crea un cursor, que es un objeto utilizado para ejecutar comandos SQL
    cursor = conn.cursor()
    # Ejecuta una consulta SQL para seleccionar los campos id, username, role y full_name de la tabla users
    cursor.execute("SELECT id, username, role, full_name FROM users")
    # Obtiene todos los resultados de la consulta y los guarda en la lista 'users'
    users = cursor.fetchall()
    # Imprime un encabezado indicando que se mostrarán los usuarios
    print("Users in database:")
    # Inicia un bucle para recorrer cada usuario en la lista de resultados
    for user in users:
        # Imprime los datos del usuario formateando el texto con los índices de la tupla (0=id, 1=username, etc.)
        print(f"ID: {user[0]}, Username: {user[1]}, Role: {user[2]}, Full Name: {user[3]}")
    # Cierra la conexión a la base de datos para liberar recursos y evitar bloqueos
    conn.close()

# Comprueba si el script se está ejecutando directamente (no importado como módulo en otro script)
if __name__ == "__main__":
    # Llama a la función list_users() para iniciar la ejecución del script
    list_users()
