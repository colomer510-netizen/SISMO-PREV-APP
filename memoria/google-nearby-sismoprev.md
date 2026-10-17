---
name: Integracion Google Nearby en SISMOPREV
description: Análisis técnico y justificación de Google Nearby Connections API para la alerta sísmica comunitaria sin internet.
preguntas:
  - ¿Cómo funciona Google Nearby en SISMOPREV?
  - ¿Por qué permite alertar a la comunidad sin internet ni datos móviles?
  - ¿Qué ventajas tiene frente a otras tecnologías de radio?
---

# Google Nearby Connections en SISMO-PREV APP

## 1. ¿Qué es Google Nearby Connections?
**Google Nearby Connections API** es una tecnología peer-to-peer (P2P) de Google Play Services que permite a teléfonos Android cercanos descubrirse, conectarse e intercambiar datos de forma **100% offline**, utilizando una combinación transparente de:
- **Bluetooth Low Energy (BLE):** Para publicidad y descubrimiento rápido con consumo mínimo de batería.
- **Wi-Fi Direct / Local Hotspot:** Para transmisión de paquetes de alta velocidad y baja latencia (milisegundos) sin necesidad de un router Wi-Fi externo ni acceso a internet.

## 2. Aplicación Directa en la Red Sísmica SISMOPREV
Cuando un teléfono viejo anclado al muro detecta la **Onda P** (arribo sísmico):
1. **Disparo Inmediato P2P:** El teléfono sensor emite una carga útil de alerta mediante `Nearby.getConnectionsClient(context).sendPayload()`.
2. **Topología en Malla / Estrella:** Los teléfonos de las familias, vecinos y aulas escolares en un radio de hasta 100 metros reciben la alerta sísmica en milisegundos directamente de teléfono a teléfono.
3. **Efecto Cascada:** Cada teléfono que recibe la alerta puede retransmitirla a los dispositivos vecinos que estén fuera del alcance del primer sensor, propagando la alarma por toda la comunidad aunque se hayan caído las torres celulares y la red eléctrica pública.

## 3. Ventajas para la Evaluación del Rally 2026:
- **Cero Dependencia de Infraestructura:** Funciona en apagones totales y zonas rurales sin señal celular.
- **Sin Costo de Suscripción:** Viene integrado de forma nativa en prácticamente todos los teléfonos Android de los últimos 10 años.
- **Protección de la Integridad Física:** Otorga los 10 a 30 segundos vitales de aviso en el entorno inmediato de la vivienda o escuela.
