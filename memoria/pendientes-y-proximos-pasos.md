---
name: Tablero de Pendientes SISMO-PREV
description: Lista de tareas, validaciones técnicas y entregables del Rally Latinoamericano.
preguntas:
  - ¿Qué tareas faltan por hacer?
  - ¿Qué elementos están probados y qué falta probar?
---

# Tablero de Pendientes y Próximos Pasos

## Tareas del Rally (Entregables Oficiales)
- [x] Seleccionar el Desafío 02: Sensores al servicio de la comunidad.
- [x] Llenar el Reporte Pautado oficial con límites estrictos de caracteres.
- [x] Acordar el guion de interacción internacional (TikTok) con EVOLVING MINDS (El Salvador 🇸🇻).
- [ ] Grabar los 3 segundos de saludo a cámara y tomar 3 fotos del equipo trabajando.
- [ ] Compartir enlace final del TikTok y registrar la misma URL en la plataforma SIRLI.
- [ ] Grabar el video de pitch técnico de 3 minutos mostrando el prototipo en pantalla.

## Tareas de Software (Cliente & Servidor)
- [x] Crear el Servidor Central FastAPI en puerto 8080 (`servidor_monitoreo/server.py:246`).
- [x] Crear el Dashboard web interactivo con semáforo y sismógrafo (`servidor_monitoreo/dashboard.html:1`).
- [x] Integrar el endpoint de análisis de Inteligencia Artificial (`/api/ai/analyze`).
- [x] Crear el servicio de telemetría en la app de Flutter (`telemetry_service.dart`).
- [x] Probar el envío de telemetría simulada (5 paquetes confirmados en el servidor).
- [ ] FALTA PROBAR: Ejecutar la app Flutter en un teléfono físico Android real apuntando a la IP `172.16.27.14:8080`.
- [ ] PENDIENTE: Subir el informe técnico en PDF a la plataforma del Rally.
