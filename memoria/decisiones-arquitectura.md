---
name: Decisiones de Arquitectura SISMO-PREV
description: Registro de decisiones técnicas clave, algoritmos y justificaciones frente al jurado.
preguntas:
  - ¿Por qué se usa el acelerómetro y no la cámara?
  - ¿Cómo funciona el algoritmo STA/LTA?
  - ¿Cómo se evitan falsos positivos?
---

# Decisiones de Arquitectura e Ingeniería

## 1. Algoritmo Sismológico STA/LTA
- **Referencia científica:** Allen, R.V. (1978). *Automatic earthquake recognition and timing from single traces*.
- **Implementación:** `cliente_movil_android/lib/features/seismic_detection/domain/usecases/sta_lta_trigger.dart:63`
- **Funcionamiento:** Se calcula la relación entre el promedio de energía de ventana corta (STA: 1 segundo) y el promedio de ruido de fondo (LTA: 10 segundos). Cuando `STA / LTA >= 4.0`, se dispara el trigger de Onda P.

## 2. Filtrado Digital Butterworth
- Se implementó un filtro pasa-bandas IIR de 2do orden entre **1 Hz y 20 Hz** para eliminar vibraciones de baja frecuencia (viento, personas caminando) y ruidos eléctricos de alta frecuencia.

## 3. Consenso Espacial Multi-Nodo
- **Archivo:** `servidor_monitoreo/server.py:116`
- Para evitar falsos positivos provocados por portazos o caídas domésticas, el servidor central requiere que al menos **2 o más nodos** reporten aceleración sincrónica en una ventana de 2 segundos antes de confirmar un sismo y activar la alerta roja.

## 4. Modo Offline-First y Respaldo Energético
- El teléfono actúa como UPS natural (12-24 horas de autonomía con su batería interna).
- Canales de contingencia: Internet WebSocket -> BLE Mesh (Bluetooth) -> SMS comprimido.
