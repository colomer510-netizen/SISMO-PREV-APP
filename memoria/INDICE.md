---
name: Indice Central de SISMO-PREV
description: Neurona maestra de la memoria del proyecto SISMO-PREV para el Rally Latinoamericano de Innovación 2026.
preguntas:
  - ¿De qué trata el proyecto SISMO-PREV?
  - ¿Cómo se conectan los componentes de hardware y software?
  - ¿Cuáles son las notas principales del proyecto?
---

# 🛡️ SISMO-PREV — Red Comunitaria de Alerta Sísmica con Smartphones Reciclados

Bienvenido a la memoria activa de **SISMO-PREV**, proyecto desarrollado por el equipo **FENIX CODE** (Nicaragua 🇳🇮) para el **Rally Latinoamericano de Innovación 2026 (Desafío 02: Sensores al servicio de la comunidad)**.

## 🧠 Mapa de Conexiones de Memoria (Sinapsis)
- [[bitacora-avances]]: Registro cronológico y avances en tiempo real de la competencia.
- [[decisiones-arquitectura]]: Justificaciones técnicas, algoritmo STA/LTA y modelo Offline-First.
- [[pendientes-y-proximos-pasos]]: Tablero de tareas pendientes (`TODO:`, `[ ]`).
- [[reglas-y-convenciones]]: Estándares de desarrollo, guías de IA y pautas del Rally.
- [[modulo-servidor-monitoreo]]: Detalles técnicos del servidor FastAPI, WebSockets y Dashboard.
- [[modulo-cliente-flutter]]: Estructura de la aplicación móvil Android y toma de sensores inerciales.

## 📌 Resumen Ejecutivo del Sistema
SISMO-PREV rescata smartphones en desuso instalándolos en muros de carga de escuelas y comunidades para medir aceleración inercial continua (50Hz) y detectar la **Onda P** antes de que arribe la destructiva **Onda S**. 

- **Servidor:** `servidor_monitoreo/server.py:1` en puerto 8080 con WebSockets y análisis por IA.
- **Cliente Flutter:** `cliente_movil_android/lib/features/seismic_detection/domain/usecases/sta_lta_trigger.dart:63`.
- **Dashboard en vivo:** `http://localhost:8080`.
