# 🚧 SISMO-PREV — Tareas Pendientes (Para continuar el Lunes)

Este documento detalla el estado exacto del proyecto y los pasos a seguir estructurados por prioridad para retomar el desarrollo sin perder el contexto.

---

## 📊 Estado Actual: ¿Qué tenemos listo?
✅ **Arquitectura Base:** Clean Architecture, inyección de dependencias (`GetIt`), constantes globales, manejo de errores y tema M3 configurados.
✅ **Código Nativo (Android):** `ForegroundService` con WakeLock y muestreo del acelerómetro a 50Hz, y Canales de Comunicación (Method/Event Channels).
✅ **Reglas de Negocio (Dominio):** Algoritmo **STA/LTA** para detección de sismos, pipeline para el modelo **CNN**, y parseo del protocolo **CAP 1.2**.
✅ **Infraestructura de Comunicaciones:** Datasources para **BLE Mesh** (Bridgefy), **SMS Fallback**, **LoRa** (Meshtastic) y satelital.
✅ **UI Inicial:** El diseño del **Dashboard** principal está maquetado.

---

## 🚀 Plan de Acción para el Lunes

### 1️⃣ Preparación del Entorno (Lo Primero)
Antes de escribir más código, necesitamos que tu entorno esté listo para compilar y probar lo que ya hicimos:
- [ ] **Instalar Flutter SDK:** Te guiaré paso a paso para instalarlo en Windows.
- [ ] **Ejecutar el proyecto:** Correr `flutter pub get` y probar compilar la app base con `flutter run`.

### 2️⃣ Desarrollo de Código (Por Prioridad)

Para que la app funcione de extremo a extremo, necesitamos conectar la capa de datos (lo que ya hicimos) con la interfaz de usuario.

#### 🔴 Prioridad Alta (La Capa Intermedia)
- [ ] **Modelos de Datos:** Crear los modelos para serializar/deserializar (JSON) de las entidades existentes:
  - `seismic_event_model.dart`
  - `cap_alert_model.dart`
- [ ] **Repositorios:** Implementar las clases que manejan la lógica de obtener y guardar datos.
  - Interfaz e implementación de `SeismicRepository`
  - Interfaz e implementación de `AlertRepository`
  - Interfaz e implementación de `CommunicationRepository`
- [ ] **BLoCs (Manejo de Estado):** El cerebro de la UI.
  - `seismic_bloc.dart` (Escucha el sensor y avisa a la UI)
  - `alert_bloc.dart` (Procesa y distribuye alertas)
  - `communication_bloc.dart` (Maneja el estado de la red Mesh/SMS)

#### 🟠 Prioridad Media (Componentes de UI)
- [ ] **Widgets Especializados:**
  - `seismograph_widget.dart` (Gráfico de ondas en tiempo real)
  - `alert_card.dart` (Tarjetas de alertas CAP)
  - `drill_mode_banner.dart` (Banner de simulacro)
- [ ] **Datasource del Acelerómetro:** Terminar de conectar `accelerometer_datasource.dart` con los EventChannels nativos.

#### 🟡 Prioridad Baja (Features Adicionales)
- [ ] **Mapas Offline:** 
  - `mbtiles_datasource.dart`
  - Pantalla del mapa con `MapLibre GL`
- [ ] **Traducciones (i18n):** Configurar soporte para inglés y español.

---

## 📦 Assets (Recursos Necesarios a Conseguir)

Durante la semana o el lunes, debemos conseguir y colocar estos archivos en sus respectivas carpetas dentro de `assets/`:

- [ ] **Tipografías:** Descargar familia **Inter** de Google Fonts (`assets/fonts/`).
- [ ] **Audios:** Sonidos de sirenas y alarmas para distintos niveles de severidad (`assets/sounds/`).
- [ ] **Modelo ML:** Un modelo `.tflite` entrenado para diferenciar pasos de sismos reales (`assets/models/`).
- [ ] **Mapas:** Archivos `.mbtiles` de la región objetivo para navegación sin internet (`assets/maps/`).
- [ ] **Claves API:** Registrarse en Bridgefy para obtener el API Key de BLE Mesh.

---
*💡 Nota: Al empezar el lunes, puedes pedirme: "Ayúdame a instalar Flutter" o "Continuemos con la Prioridad Alta del archivo de tareas pendientes".*
