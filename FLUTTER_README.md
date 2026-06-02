# 📱 ASL RECOGNITION - Aplicación Flutter

Aplicación **Flutter** para reconocimiento de lenguaje de señas (ASL) con interfaz **minimalista en blanco y negro**.

---

## 🎯 Arquitectura

```
FRONTEND (Flutter)
    ↓
    └─→ Captura cámara
    └─→ Envía imagen a servidor
    
BACKEND (Python Flask)
    ↓
    └─→ Recibe imagen
    └─→ Detecta mano (MediaPipe)
    └─→ Reconoce letra (SigLIP2)
    └─→ Retorna resultado (JSON)
    
FRONTEND (Flutter)
    ↓
    └─→ Muestra letra + confianza
```

---

## 📋 Requisitos

### Hardware
- Android 7.0+ (API 24+) O iOS 11.0+
- Cámara
- Conexión a red local

### Software
- Flutter 3.0+
- Dart 3.0+
- Python 3.10+ (para servidor backend)

### Servidor Backend
- En la misma red local
- O en `localhost` si se prueba desde computadora

---

## 🚀 Instalación

### 1️⃣ Instalar Dependencias de Flutter

```bash
# Descargar dependencias
flutter pub get
```

### 2️⃣ Preparar Backend Python

En la carpeta `sign_language_recognition_v2/`:

```bash
# Instalar dependencias del servidor
pip install -r requirements.txt
pip install -r requirements_server.txt

# Ejecutar servidor
python flask_server.py
```

El servidor estará en: `http://localhost:5000`

### 3️⃣ Ejecutar App Flutter

#### En Android

```bash
flutter run -d android
```

#### En iOS

```bash
flutter run -d ios
```

#### En Web

```bash
flutter run -d web
```

#### En computadora (debug)

```bash
flutter run -d windows
# o
flutter run -d macos
# o
flutter run -d linux
```

---

## 🎮 Cómo Usar

### En el dispositivo

1. **La app se abre** y muestra la cámara
2. **Haz una seña** frente a la cámara (letra A-Z)
3. **Presiona CAPTURAR**
4. La app **envía la foto al servidor**
5. El servidor **reconoce la letra**
6. **Se muestra el resultado**:
   - Letra detectada (grande)
   - Confianza (en %)
   - Barra de progreso

### Controles

| Botón | Acción |
|-------|--------|
| **CAPTURAR** | Tomar foto y enviar a servidor |
| **LIMPIAR** | Borrar resultado anterior |

---

## ⚙️ Configuración

### Cambiar IP del Servidor

Edita `lib/main.dart` línea donde dice:

```dart
Uri.parse('http://localhost:5000/recognize'),
```

Cambia `localhost` a la IP del servidor, por ejemplo:

```dart
Uri.parse('http://192.168.1.100:5000/recognize'),
```

### Permisos

La app solicita automáticamente:
- ✅ **Acceso a cámara** (necesario)
- ✅ **Acceso a archivos** (para capturar)

---

## 🏗️ Estructura

```
proyecto/
├── lib/
│   └── main.dart                    ← APP FLUTTER
├── pubspec.yaml                     ← Dependencias Flutter
├── android/
│   └── app/src/main/AndroidManifest.xml
├── ios/
│   └── Runner/Info.plist
└── sign_language_recognition_v2/
    ├── flask_server.py              ← SERVIDOR BACKEND
    ├── requirements.txt             ← Dependencias Python
    └── requirements_server.txt      ← Dependencias Flask
```

---

## 🔌 API del Servidor

### POST /recognize

Envía una imagen para reconocimiento.

**Request:**
```
Content-Type: multipart/form-data
Body: image (archivo)
```

**Response:**
```json
{
  "letter": "A",
  "confidence": 0.87,
  "hand_detected": true,
  "success": true
}
```

### GET /health

Verifica estado del servidor.

**Response:**
```json
{
  "status": "ok",
  "models_loaded": true,
  "device": "cpu"
}
```

### GET /info

Información del servidor.

**Response:**
```json
{
  "name": "ASL Recognition Server",
  "version": "2.0.0",
  "supported_letters": ["A", "B", "C", ...],
  "device": "cpu"
}
```

---

## 🎨 Interfaz

### Layout Horizontal

```
┌────────────────────────────────┬─────────────────┐
│                                │                 │
│   PREVIEW CÁMARA               │  PANEL DERECHO  │
│   1280x720                      │  - Título       │
│                                │  - Letra grande │
│  [Esquinas minimalista]        │  - Confianza    │
│                                │  - Botones      │
│                                │                 │
└────────────────────────────────┴─────────────────┘
```

### Colores

- **Fondo**: Blanco puro
- **Texto primario**: Negro
- **Texto secundario**: Gris (#808080)
- **Bordes**: Negro fino
- **Botones**: Negro/Blanco

---

## 🐛 Solución de Problemas

### "Connection refused"

**Problema**: La app no puede conectarse al servidor

**Soluciones**:
1. Asegúrate que Flask está corriendo: `python flask_server.py`
2. Verifica IP correcta en `main.dart`
3. Ambos en la misma red local
4. Firewall: permite puerto 5000

### "Camera not available"

**Problema**: La cámara no está disponible

**Soluciones**:
1. Reinicia la app
2. Cierra otras apps que usen cámara
3. Verifica permisos (Settings → Apps → ASL Recognition)

### "Image processing failed"

**Problema**: Error procesando la imagen

**Soluciones**:
1. Asegúrate que el servidor está corriendo
2. Revisa logs del servidor Flask
3. Intenta nuevamente

### App muy lenta

**Problema**: Predicción lenta

**Soluciones**:
1. Reduce resolución de cámara
2. Instala CUDA en servidor (si tienes GPU NVIDIA)
3. Reduce calidad de la imagen antes de enviar

---

## 📱 Compilación para Producción

### Android APK

```bash
flutter build apk --release
# Archivo: build/app/outputs/flutter-app.apk
```

### Android App Bundle

```bash
flutter build appbundle --release
# Archivo: build/app/outputs/bundle/release/app-release.aab
```

### iOS App

```bash
flutter build ios --release
# Abre en Xcode y completa el proceso
```

---

## 🔒 Permisos Requeridos

### Android
- `android.permission.CAMERA` - Acceso a cámara
- `android.permission.INTERNET` - Conexión de red
- `android.permission.ACCESS_NETWORK_STATE` - Estado de red

### iOS
- `NSCameraUsageDescription` - Acceso a cámara
- `NSLocalNetworkUsageDescription` - Red local

---

## 📊 Performance

### Tiempos

| Operación | Tiempo |
|-----------|--------|
| Captura | <100ms |
| Envío de imagen | 100-500ms (depende red) |
| Procesamiento servidor | 50-200ms (CPU) / 10-50ms (GPU) |
| **Total** | 200-800ms |

### Requisitos de Red

- **Ancho de banda**: ~1-2 MB por predicción
- **Latencia**: <100ms (recomendado)

---

## 🎓 Ejemplo de Uso Personalizado

### Cambiar servidor

```dart
// En _CameraScreenState._captureAndRecognize()
const String serverUrl = 'http://tu-ip:5000/recognize';

final request = http.MultipartRequest('POST', Uri.parse(serverUrl));
```

### Agregar validaciones

```dart
// Validar confianza antes de mostrar
if (confidence < 0.6) {
  // Mostrar advertencia
}
```

### Guardar predicciones

```dart
// Agregar lista para guardar historial
List<String> history = [];

// En _captureAndRecognize()
history.add('$_recognizedLetter at ${DateTime.now()}');
```

---

## 🚀 Mejoras Futuras

- [ ] Construcción de palabras automática
- [ ] Historial de predicciones
- [ ] Estadísticas de precisión
- [ ] Soporte offline (modelo local)
- [ ] Exportar resultados
- [ ] Modo de entrenamiento
- [ ] Reconocimiento de gestos

---

## 📚 Recursos

- [Flutter Docs](https://flutter.dev/docs)
- [Camera Package](https://pub.dev/packages/camera)
- [HTTP Package](https://pub.dev/packages/http)
- [Flask Docs](https://flask.palletsprojects.com/)
- [MediaPipe](https://mediapipe.dev/)

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas:

1. Fork el repositorio
2. Crea rama con tu feature
3. Haz commit de los cambios
4. Envía Pull Request

---

## 📝 Licencia

Todas las librerías usadas tienen licencias open-source:
- Flutter: BSD
- Camera: BSD
- HTTP: BSD
- Flask: BSD
- PyTorch: BSD
- MediaPipe: Apache 2.0

---

## 📞 Soporte

- Revisa `TROUBLESHOOTING.md` en carpeta Python
- Ejecuta `python verificar.py` para diagnóstico
- Revisa logs del servidor Flask

---

**Versión**: 2.0  
**Última actualización**: Mayo 2026  
**Estado**: ✅ Producción
