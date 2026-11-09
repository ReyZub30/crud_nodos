# CRUD Nodos — Actividad 2: CRUD local en Flutter

App que administra nodos de sensado (temperatura, humedad, luz, presión) con:

- **JSON:** escribir, leer y verificar `nodos.json` en el directorio asignado.
- **CSV con integridad:** `CsvNodeManager` exporta e importa `nodos.csv` con la cabecera `# CHECKSUM:<sha256>` y rechaza archivos alterados.
- **CRUD + transacciones ACID:** crear, leer, actualizar y borrar con `sqflite`; inserción masiva con `db.transaction` + `batch.insert`.
- **Migración de esquema:** `onUpgrade` de v1 a v2 agrega `ubicacion_nodo` sin perder registros.

## Instalación

1. En una terminal, dentro de `C:\Proyectos`:
   ```
   flutter create crud_nodos
   ```
2. Reemplaza `pubspec.yaml`, la carpeta `lib/` y la carpeta `test/` por las de este paquete.
3. Dentro de `C:\Proyectos\crud_nodos`:
   ```
   flutter pub get
   flutter run
   ```
   Con el teléfono conectado (sqflite no funciona en Chrome ni en Windows).

## Estructura

```
lib/
├── main.dart
├── models/nodo.dart               Modelo y conversión a mapa (SQLite/JSON/CSV)
├── data/
│   ├── database_helper.dart       sqflite: versión, onCreate, onUpgrade, CRUD, batch
│   ├── json_manager.dart          Escritura, lectura y verificación de JSON
│   └── csv_node_manager.dart      CSV con checksum SHA-256 (Práctica guiada 1)
├── screens/
│   ├── home_screen.dart           Navegación por pestañas
│   ├── nodos_page.dart            Lista, alta, edición y borrado
│   ├── nodo_form_screen.dart      Formulario
│   ├── archivos_page.dart         Módulo JSON y CSV
│   ├── base_datos_page.dart       Versión, columnas, migración e inserción masiva
│   └── widgets.dart               Componentes compartidos
└── utils/
    ├── storage.dart               Directorio asignado y formatos
    └── sample_data.dart           Generador de nodos para pruebas masivas
```

## Guion para la demostración en laboratorio

**1. CRUD**
- Pestaña *Nodos* → **Nuevo**: crea un nodo (Create).
- La lista lo muestra (Read).
- Tócalo, cambia el valor y guarda (Update).
- Deslízalo a la izquierda y confirma (Delete).

**2. Inserción masiva (transacción + batch)**
- Pestaña *Base de datos* → elige 1,000 o 5,000 → **Insertar en lote**.
- Se muestra el tiempo en milisegundos; la interfaz no se congela.

**3. JSON**
- Pestaña *Archivos* → **Escribir JSON** y luego **Leer y verificar**.
- La tarjeta *Directorio asignado* muestra la ruta exacta del archivo.

**4. CSV con SHA-256**
- **Exportar CSV**: se muestra el hash y las primeras líneas con `# CHECKSUM:`.
- **Importar y verificar**: el checksum coincide y se importa con batch.
- **Alterar archivo (prueba)** y de nuevo **Importar y verificar**: el archivo se **rechaza** porque el hash ya no coincide.

**5. Migración v1 → v2**
- Con `kDbVersion = 1` (en `lib/data/database_helper.dart`) genera datos. La pestaña *Base de datos* muestra v1 y 5 columnas.
- Cambia a `const int kDbVersion = 2;`, guarda y presiona **R** en la terminal.
- Ahora aparece v2, la columna `ubicacion_nodo` y el mismo número de registros. Los nodos antiguos tienen "Sin asignar" y en el formulario aparece el campo *Ubicación*.

> Para repetir la demostración desde v1, desinstala la app del teléfono (o borra sus datos) y vuelve a ejecutar con `kDbVersion = 1`.

## Ubicar los archivos fuera de la app

En Android los archivos están en:
```
/storage/emulated/0/Android/data/com.example.crud_nodos/files/
```
Para verlos desde la PC con el teléfono conectado:
```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell ls /storage/emulated/0/Android/data/com.example.crud_nodos/files
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell cat /storage/emulated/0/Android/data/com.example.crud_nodos/files/nodos.csv
```
También se pueden abrir en el Explorador de Windows: *Este equipo → Galaxy S24 → Almacenamiento interno → Android → data → com.example.crud_nodos → files*.

## Subir a GitHub

1. Crea un repositorio vacío en github.com (sin README).
2. En la terminal del proyecto:
   ```
   git init
   git add .
   git commit -m "Actividad 2: CRUD local con JSON, CSV SHA-256, batch y migración"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/crud_nodos.git
   git push -u origin main
   ```
   `flutter create` ya genera un `.gitignore` que excluye `build/` y archivos temporales.
