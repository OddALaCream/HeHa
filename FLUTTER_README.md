# 📱 ASL Recognition — Flutter (GetX + Clean Architecture)

Aplicación **Flutter** para reconocimiento del alfabeto de lenguaje de señas
americano (ASL, A-Z). La app captura la cámara y envía las imágenes a un
**servidor REST** (`flask_server.py`) que detecta la mano con **MediaPipe**,
la recorta y la clasifica con el modelo **SigLIP2**
(`prithivMLmods/Alphabet-Sign-Language-Detection`).

Construida con **GetX** (estado + inyección de dependencias) sobre una
**arquitectura limpia** por capas.

---

## 🏗️ Arquitectura

```
lib/
├── main.dart                         # StatelessWidget + GetMaterialApp
└── app/
    ├── core/                         # Tema y constantes
    │   ├── constants/app_constants.dart      (URL del servidor, timeouts)
    │   └── theme/app_theme.dart
    ├── domain/                       # Reglas de negocio (Dart puro)
    │   ├── entities/recognition_result.dart
    │   └── repositories/recognition_repository.dart      (abstracción)
    ├── data/                         # Implementación + acceso a datos
    │   ├── datasources/asl_rest_datasource.dart          (HTTP)
    │   └── repositories/recognition_repository_impl.dart
    └── presentation/                 # UI (todo StatelessWidget)
        ├── bindings/recognition_binding.dart             (DI)
        ├── controllers/recognition_controller.dart       (GetxController)
        ├── pages/recognition_page.dart
        └── widgets/                  (camera_pane, control_panel, ...)
```

**Regla de dependencia:** `presentation → domain ← data`. La presentación
depende de la abstracción `RecognitionRepository`; la implementación concreta
vive en `data` y usa el datasource REST. Inversión total de dependencias.

### GetX

- `GetMaterialApp` como raíz.
- `RecognitionController` (`GetxController`) con estado reactivo `.obs`.
- `RecognitionBinding` inyecta datasource → repositorio → controlador con
  `Get.lazyPut`.
- Las vistas son `StatelessWidget` (`GetView`) y se reconstruyen solo con `Obx`.

---

## 🤖 Pipeline de IA (servidor)

```
App Flutter  ──(JPEG)──▶  flask_server.py
                              │
                              ├─ MediaPipe Hands  → detecta y recorta la mano
                              ├─ SigLIP2          → clasifica la letra (A-Z)
                              └─ JSON {letter, confidence, hand_detected}
App Flutter  ◀──(JSON)─────────┘
```

> El recorte de mano con MediaPipe es clave: SigLIP2 fue afinado con recortes
> cerrados de la mano, por eso el servidor recorta antes de clasificar.

### Levantar el servidor

**Opción A — Docker (recomendada):**

```bash
cd ../sign_language_recognition_v2
docker compose up --build        # queda en http://0.0.0.0:5000
```

Los modelos se descargan en el primer arranque y se persisten en el volumen
`asl-models`, así que los siguientes arranques son inmediatos.

**Opción B — Python local:**

```bash
cd ../sign_language_recognition_v2
pip install -r requirements_server.txt
python flask_server.py           # queda en http://0.0.0.0:5000
```

En el primer arranque descarga el modelo SigLIP2 (~372 MB) y
`hand_landmarker.task` de MediaPipe.

### Conectar la app al servidor

Edita la IP en `lib/app/core/constants/app_constants.dart`:

```dart
static const String serverUrl = 'http://TU_IP_LOCAL:5000';
```

`TU_IP_LOCAL` es la IP de la máquina que corre el servidor, en la misma red
Wi-Fi que el dispositivo (p. ej. `http://192.168.1.208:5000`).

---

## 🚀 Ejecución

```bash
flutter pub get
flutter run -d android        # o el dispositivo conectado
```

Endpoints del servidor:

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET  | `/health`    | Estado y si los modelos están cargados |
| POST | `/recognize` | `multipart` campo `image` → `{letter, confidence, hand_detected}` |
| GET  | `/info`      | Metadatos y letras soportadas |

---

## 🎮 Uso

1. La app abre la cámara y comprueba el servidor (botón **VERIFICAR** para
   reintentar la conexión).
2. Haz una seña (A-Z) dentro del recuadro de enfoque.
3. La letra y su confianza aparecen en el panel (con animaciones).
4. **EN VIVO/REANUDAR**: detección continua · **✕**: limpiar resultado.

---

## 🔒 Permisos

- **Android:** `CAMERA`, `INTERNET` (más `usesCleartextTraffic` para HTTP en
  red local).
- **iOS:** `NSCameraUsageDescription`, `NSLocalNetworkUsageDescription`.
