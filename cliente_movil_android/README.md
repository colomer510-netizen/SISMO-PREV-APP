# 🛡 SISMO-PREV — Alerta Temprana de Desastres Naturales

> [!WARNING]
> **ESTE PROYECTO ESTÁ ACTUALMENTE EN FASE DE DESARROLLO (WIP).**
> No debe usarse aún en escenarios de emergencia reales.

> Aplicación móvil de misión crítica para detección sísmica colectiva
> con paradigma **Offline-First** y comunicaciones hiper-redundantes.

## 🏗 Arquitectura

```
Clean Architecture + Feature-First + BLoC Pattern
```

| Capa | Responsabilidad |
|------|----------------|
| **Presentation** | UI, BLoC, Widgets |
| **Domain** | Entidades, Casos de Uso, Repositorios (interfaz) |
| **Data** | Datasources, Modelos, Repositorios (implementación) |

## 🔧 Tecnologías

- **Framework**: Flutter (Dart)
- **Mapas Offline**: MapLibre GL Native + MBTiles (SQLite)
- **Sensores**: Acelerómetro MEMS a 50Hz via Foreground Service nativo
- **ML Local**: TensorFlow Lite (CNN para clasificación sísmica)
- **BLE Mesh**: Bridgefy SDK (P2P descentralizado)
- **LoRa**: Meshtastic (radio larga distancia)
- **Alertas**: Protocolo CAP 1.2 (OASIS XML)
- **SMS Fallback**: Telemetría comprimida sin internet

## 🚀 Instalación

### Prerrequisitos
1. [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.4.0
2. Android Studio con SDK ≥ 26 (Android 8.0)
3. Xcode (para iOS, solo en macOS)

### Pasos
```bash
# Clonar el proyecto
cd sismoguard

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Compilar APK de release
flutter build apk --release
```

## 📡 Canales de Comunicación

| Prioridad | Canal | Alcance | Estado |
|-----------|-------|---------|--------|
| 1 | TCP/IP | Global | ✅ Base |
| 2 | BLE Mesh (Bridgefy) | ~100m × saltos | 🔧 Interfaz lista |
| 3 | LoRa (Meshtastic) | 10+ km | 🔧 Stub preparado |
| 4 | SMS Fallback | Celular | 🔧 Interfaz lista |
| 5 | NTN Satelital (3GPP R17) | Global | 📋 Diseño futuro |

## ⚠️ Licencia

Proyecto de misión crítica. Uso responsable requerido.
