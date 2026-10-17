# 🚀 PROPUESTAS DE INNOVACIÓN Y FUNCIONES FUTURAS: SISMO-PREV APP
**Rally Latinoamericano de Innovación 2026**  
**Desafío 02:** *Sensores al servicio de la comunidad*  
**Equipo:** *FENIX CODE — Nicaragua 🇳🇮*  
**Fecha de Registro:** 17 de Octubre de 2026  

---

## 📱 Bloque A: Aprovechamiento Avanzado de Sensores del Teléfono (Hardware)

1. **Doble Detección Inercial (Giroscopio + Acelerómetro):**
   - *Mecanismo:* El acelerómetro detecta la aceleración lineal de la onda P; el giroscopio mide la torsión angular de la onda S y el pandeo estructural del edificio.
   - *Impacto:* Descarta caídas accidentales del teléfono (un celular que cae rota con alta velocidad angular, mientras que una mesa durante un sismo vibra en el plano horizontal).

2. **Detección Sísmica Temprana y Rescate Post-Impacto por Micrófono (Infrasonido y Golpes):**
   - *Mecanismo:* Monitoreo del espectro de audio de muy baja frecuencia (infrasonido de fractura tectónica) previo a la sacudida.
   - *Modo Rescate:* Si el sismo es severo y el teléfono detecta inmovilidad posterior, el micrófono entra en escucha de patrones de golpes rítmicos de auxilio (*"tap-tap-tap"* de sobrevivientes bajo escombros).

3. **Sensor Barométrico (Altímetro / Presión Atmosférica):**
   - *Mecanismo:* Medición de variaciones barométricas entre pisos.
   - *Impacto:* Detecta en qué piso de un edificio se encuentra el sensor, permitiendo modelar cómo se amplifica la aceleración sísmica según la altura de la estructura.

4. **Sensor de Luz Ambiental y Proximidad (Modo de Reposo Seguro):**
   - *Mecanismo:* Si el sensor detecta que el teléfono está en el bolsillo o en una cartera, ajusta el umbral de disparo para evitar falsos positivos de pasos. Si está sobre una mesa fija con luz estable, se activa el modo de *"Alta Sensibilidad Sismográfica"*.

5. **Magnetómetro (Brújula) para Detección de Anomalías Piezomagnéticas:**
   - *Mecanismo:* Al fracturarse rocas con alto contenido de cuarzo o magnetita en fallas geológicas someras, se generan fluctuaciones electromagnéticas locales que pueden triangularse segundos antes del arribo de la onda.

6. **Linterna Flash Estroboscópica de Evacuación Automática:**
   - *Mecanismo:* Al activarse la alerta sísmica en la noche, el flash LED del teléfono se enciende automáticamente con pulsos de alta visibilidad para alumbrar la ruta de evacuación aunque se corte la energía eléctrica pública.

7. **Termómetro de Batería y CPU (Detección de Incendio Post-Sismo):**
   - *Mecanismo:* Monitoreo térmico continuo para detectar incrementos rápidos e inusuales de calor post-terremoto, alertando a los bomberos de posibles incendios estructurales inmediatos en la zona del sensor.

---

## 🌐 Bloque B: Resiliencia y Red Comunitaria Sin Internet (Offline-First)

8. **Malla Mesh Bluetooth (BLE) y Wi-Fi Direct Vecinal:**
   - *Mecanismo:* Si colapsan las antenas celulares y el internet, los teléfonos se conectan de vecino a vecino retransmitiendo el paquete de alerta en cadena hasta el refugio comunal más cercano.

9. **Canal de Emergencia SMS Comprimido en Base64:**
   - *Mecanismo:* Si la red de datos 4G/LTE se satura, el teléfono envía un SMS de 20 bytes con coordenadas, nivel de sacudida y estado de la familia a un número receptor central o defensa civil.

10. **Sirena Acústica Ultrasónica y de Alta Frecuencia:**
    - *Mecanismo:* Emite una alarma con tonos modulados en frecuencias que alertan tanto a personas dormidas como a animales domésticos y perros rescatistas K-9.

11. **Check-in de Supervivencia *"Estoy a Salvo / Necesito Ayuda"*:*
    - *Mecanismo:* Dos botones gigantes en pantalla al cesar la sacudida; la respuesta se transmite al dashboard para que los cuerpos de socorro conozcan de inmediato la cantidad de personas atrapadas o heridas por sector.

---

## 🤖 Bloque C: Inteligencia Artificial en el Dispositivo (Edge AI)

12. **Modelo TinyML en el Teléfono (Filtrado Inteligente de Ruido):**
    - *Mecanismo:* Micro-red neuronal (TensorFlow Lite) integrada en la APK que clasifica en menos de 5 ms si la vibración es un sismo real, un camión pesado o una puerta azotándose.

13. **Cálculo de Intensidad Mercalli Modificada (MMI) en Tiempo Real:**
    - *Mecanismo:* Conversión automática del PGA (*Peak Ground Acceleration*) medido por el teléfono a la escala humana Mercalli (I a XII), reportando si el sismo fue *"Leve"*, *"Fuerte"* o *"Destructivo"*.

14. **Estimación de Daño Estructural Preliminar con la Cámara:**
    - *Mecanismo:* El usuario fotografía grietas en columnas o paredes tras el sismo, y el modelo clasifica si son fisuras superficiales de repello o daño estructural grave en vigas de carga.

---

## 🗺️ Bloque D: Gestión de Riesgos, Servidor y Protección Civil

15. **Integración con Alertas de Tsunami para la Costa del Pacífico:**
    - *Mecanismo:* Para sismos con epicentro en la zona de subducción marina (frente a San Juan del Sur, Masachapa, Corinto), el sistema calcula el tiempo estimado de arribo de la primera ola a la costa y genera rutas de evacuación a zonas altas.

16. **Cálculo de "Lead Time" Dinámico por Barrio:**
    - *Mecanismo:* Si el epicentro se detecta en la costa o en Chinandega, el servidor calcula cuántos segundos exactos faltan para que la onda destructiva S llegue a León y a Managua, mostrando una cuenta regresiva personalizada en cada teléfono.

17. **Cálculo de Huella de Carbono y Consumo Energético Ultra-Bajo:**
    - *Mecanismo:* El algoritmo ajusta dinámicamente la frecuencia de muestreo del acelerómetro (de 50Hz a 100Hz solo cuando se detecta micro-movimiento), reduciendo el consumo a menos del 1.5% de batería por día.

18. **Puntos de Encuentro y Rutas Seguras Georreferenciadas (Caché Offline):**
    - *Mecanismo:* Descarga en la memoria caché del teléfono los mapas de parques, canchas y zonas seguras de la ciudad, guiando a la persona incluso si Google Maps no tiene conexión.

19. **Simulacros Programados Centralizados (Modo Escolar / Colegios):**
    - *Mecanismo:* Disparo simultáneo de simulacros sincronizados desde el panel web hacia cientos de teléfonos en colegios a una hora programada, con cronómetro automático del tiempo de evacuación.

20. **Integración con Redes de Radioaficionados (LoRa / APRS):**
    - *Mecanismo:* Módulo de enlace serial para microcontroladores ESP32 o radio VHF que retransmite paquetes sísmicos a más de 30 km sin infraestructura telefónica ni cables.
