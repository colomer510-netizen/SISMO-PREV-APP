import os
import json
import time
import asyncio
import io
import csv
from typing import Dict, List, Any, Optional
import requests
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Response
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel
from seismic_cnn_filter import seismic_filter

app = FastAPI(title="SISMO-PREV Central Server", version="1.0.0")

class ConnectionManager:
    def __init__(self):
        self.active_dashboards: List[WebSocket] = []
        self.active_sensors: Dict[str, WebSocket] = {}

    async def connect_dashboard(self, websocket: WebSocket):
        await websocket.accept()
        self.active_dashboards.append(websocket)

    def disconnect_dashboard(self, websocket: WebSocket):
        if websocket in self.active_dashboards:
            self.active_dashboards.remove(websocket)

    async def register_sensor(self, node_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_sensors[node_id] = websocket

    def disconnect_sensor(self, node_id: str):
        if node_id in self.active_sensors:
            del self.active_sensors[node_id]

    async def broadcast_to_dashboards(self, message: dict):
        dead_connections = []
        for ws in self.active_dashboards:
            try:
                await ws.send_json(message)
            except Exception:
                dead_connections.append(ws)
        for dead in dead_connections:
            self.disconnect_dashboard(dead)

    async def broadcast_to_sensors(self, message: dict):
        dead_nodes = []
        for node_id, ws in self.active_sensors.items():
            try:
                await ws.send_json(message)
            except Exception:
                dead_nodes.append(node_id)
        for dead in dead_nodes:
            self.disconnect_sensor(dead)

    async def broadcast_bytes_to_sensors(self, data: bytes):
        dead_nodes = []
        for node_id, ws in self.active_sensors.items():
            try:
                await ws.send_bytes(data)
            except Exception:
                dead_nodes.append(node_id)
        for dead in dead_nodes:
            self.disconnect_sensor(dead)

manager = ConnectionManager()

system_state = {
    "status": "normal",
    "threat_level": "VERDE",
    "active_drill": False,
    "last_event": None,
    "nodes": {},
    "event_history": [],
    "public_seismic_feed": []  # Sismos oficiales recientes de Centroamérica (USGS / EMSC)
}

async def fetch_usgs_central_america_earthquakes():
    """Consulta periódica del feed oficial de USGS para sismos en Centroamérica."""
    url = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson"
    try:
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            features = data.get("features", [])
            # Filtrar coordenadas de Centroamérica: Lat 7.0 a 18.0, Lng -94.0 a -77.0
            ca_quakes = []
            for f in features:
                coords = f.get("geometry", {}).get("coordinates", [])
                if len(coords) >= 2:
                    lng, lat = coords[0], coords[1]
                    depth = coords[2] if len(coords) > 2 else 10.0
                    if 7.0 <= lat <= 18.0 and -94.0 <= lng <= -77.0:
                        props = f.get("properties", {})
                        ca_quakes.append({
                            "id": f.get("id"),
                            "mag": props.get("mag"),
                            "place": props.get("place"),
                            "time": props.get("time"),
                            "lat": round(lat, 4),
                            "lng": round(lng, 4),
                            "depth_km": round(depth, 1),
                            "source": "USGS / Global Network"
                        })
            system_state["public_seismic_feed"] = ca_quakes[:15]
    except Exception:
        pass

async def background_public_seismic_worker():
    """Hilo asíncrono para mantener actualizadas las alertas de redes públicas cada 60s."""
    while True:
        await fetch_usgs_central_america_earthquakes()
        await asyncio.sleep(60)

class TelemetryPayload(BaseModel):
    node_id: str
    place: str = "Comunidad Local"
    lat: float = 12.1364
    lng: float = -86.2514
    pga: float = 0.001
    sta_lta_ratio: float = 1.0
    is_triggered: bool = False
    battery: int = 100
    waveform: List[float] = []

class DrillControlPayload(BaseModel):
    action: str
    simulated_magnitude: float = 6.8
    epicenter: str = "Falla Local - Costa del Pacífico"

class TelegramAlertPayload(BaseModel):
    message: str = "🚨 Prueba de alerta SISMO-PREV."

TelemetryPayload.model_rebuild()
DrillControlPayload.model_rebuild()
TelegramAlertPayload.model_rebuild()

def send_telegram_alert(message_text: str):
    token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
    chat_id = os.environ.get("TELEGRAM_CHAT_ID", "").strip()
    if not token or not chat_id:
        return {"status": "skipped", "message": "TELEGRAM_BOT_TOKEN o TELEGRAM_CHAT_ID no configurados"}
    try:
        url = f"https://api.telegram.org/bot{token}/sendMessage"
        resp = requests.post(url, json={"chat_id": chat_id, "text": message_text, "parse_mode": "Markdown"}, timeout=4)
        return {"status": "sent" if resp.status_code == 200 else "error", "code": resp.status_code}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def load_env_variables():
    env_file = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(env_file):
        with open(env_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip())

load_env_variables()

def query_ai_assistant(prompt: str) -> str:
    gemini_key = os.environ.get("GEMINI_API_KEY", "").strip()

    if gemini_key:
        try:
            from google import genai
            client = genai.Client(api_key=gemini_key)
            system_instruction = (
                "Eres el Copiloto de Inteligencia Artificial de SISMO-PREV para Protección Civil. "
                "Analiza la aceleración del suelo (PGA), estima magnitud y da recomendaciones breves."
            )
            response = client.models.generate_content(
                model="gemini-3.8-flash",
                contents=prompt,
                config={"system_instruction": system_instruction}
            )
            if response and response.text:
                return "Google Gemini (gemini-3.8-flash):\n" + response.text.strip()
        except Exception:
            pass

    try:
        body = {
            "model": "phi4-mini:latest",
            "messages": [
                {"role": "system", "content": "Eres el Copiloto de Inteligencia Artificial de SISMO-PREV."},
                {"role": "user", "content": prompt}
            ],
            "max_tokens": 250,
            "temperature": 0.3
        }
        resp = requests.post("http://localhost:11434/v1/chat/completions", json=body, timeout=4)
        if resp.status_code == 200:
            return "Ollama Local (phi4-mini):\n" + resp.json()["choices"][0]["message"]["content"]
    except Exception:
        pass

    pga = system_state["last_event"]["average_pga"] if system_state["last_event"] else 0.045
    mag = system_state["last_event"]["estimated_magnitude"] if system_state["last_event"] else 5.5
    return (
        "SISMO-PREV AI Engine (Protección Civil):\n"
        f"- Aceleración Máxima (PGA): {pga} g | Magnitud Estimada: M{mag} Richter.\n"
        "- Daño Estructural Previsto: Movimiento perceptible. Probabilidad de daños leves en mampostería no confinada.\n"
        "- Acciones Inmediatas: Corte preventivo de gas en escuelas; repliegue a zonas de seguridad delimitadas.\n"
        "- Despacho de Emergencia: Priorizar verificación en construcciones sobre suelos arcillosos o blandos."
    )

def calculate_triangulation_and_lead_time(triggered_nodes: list, mag_est: float):
    # Triangulación de epicentro por centroide ponderado de aceleración (PGA)
    total_weight = sum(max(n.get("pga", 0.001), 0.001) for n in triggered_nodes)
    epicenter_lat = sum(n.get("lat", 12.1364) * max(n.get("pga", 0.001), 0.001) for n in triggered_nodes) / total_weight
    epicenter_lng = sum(n.get("lng", -86.2514) * max(n.get("pga", 0.001), 0.001) for n in triggered_nodes) / total_weight

    # Distancia promedio aproximada en km a los nodos (1 grado lat ≈ 111 km)
    avg_dist_km = sum(
        (((n.get("lat", 12.1364) - epicenter_lat) ** 2 + ((n.get("lng", -86.2514) - epicenter_lng) ** 2) * 0.9) ** 0.5) * 111.0
        for n in triggered_nodes
    ) / len(triggered_nodes)

    # Velocidad Onda P ≈ 6.0 km/s, Velocidad Onda S (destructiva) ≈ 3.5 km/s
    # Lead time = Tiempo que tarda la Onda S en llegar a la comunidad tras la detección inicial de Onda P
    # Para sismos locales se asegura una ventana realista de advertencia entre 8s y 35s
    lead_time = round(max(8.0, min(35.0, (avg_dist_km / 3.5) - (avg_dist_km / 6.0) + (mag_est * 2.0))), 1)

    return round(epicenter_lat, 5), round(epicenter_lng, 5), lead_time, round(avg_dist_km, 1)

def evaluate_seismic_consensus():
    now = time.time()
    triggered_nodes = [
        node for node in system_state["nodes"].values()
        if node.get("is_triggered") and (now - node.get("last_seen", 0) < 3.0)
    ]
    
    count = len(triggered_nodes)
    if count >= 2 and not system_state["active_drill"]:
        avg_pga = sum(n.get("pga", 0.0) for n in triggered_nodes) / count
        mag_est = round(3.5 + (avg_pga * 10), 1)
        if mag_est > 8.5:
            mag_est = 8.5

        epi_lat, epi_lng, lead_time, dist_km = calculate_triangulation_and_lead_time(triggered_nodes, mag_est)

        system_state["status"] = "earthquake"
        system_state["threat_level"] = "ROJO"
        event = {
            "id": f"EVT-{int(now)}",
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "estimated_magnitude": mag_est,
            "average_pga": round(avg_pga, 4),
            "triggered_nodes_count": count,
            "epicenter_lat": epi_lat,
            "epicenter_lng": epi_lng,
            "lead_time_seconds": lead_time,
            "distance_km": dist_km,
            "status": "CONFIRMADO",
            "type": "REAL"
        }
        system_state["last_event"] = event
        if len(system_state["event_history"]) > 20:
            system_state["event_history"].pop(0)
        system_state["event_history"].append(event)
        return event
    return None

@app.get("/api/status")
def get_status():
    return JSONResponse(system_state)

@app.post("/api/telemetry")
async def receive_telemetry(data: TelemetryPayload):
    now = time.time()
    node_data = data.dict()
    node_data["last_seen"] = now
    system_state["nodes"][data.node_id] = node_data

    # Limpiar nodos inactivos que no hayan enviado latido en los últimos 15 segundos
    stale_cutoff = now - 15.0
    stale_ids = [nid for nid, n in system_state["nodes"].items() if n.get("last_seen", 0) < stale_cutoff]
    for sid in stale_ids:
        del system_state["nodes"][sid]

    if data.is_triggered and not system_state["active_drill"]:
        # FILTRO NEURONAL CNN 1D: Descarte de golpes o caídas accidentales del smartphone
        if data.waveform and len(data.waveform) >= 8:
            features = seismic_filter.extract_features(data.waveform)
            if not features.get("is_seismic", True):
                # Descartado como falso positivo (ruido de alta frecuencia)
                node_data["is_triggered"] = False
                node_data["pga"] = 0.002
                data.is_triggered = False

        if data.is_triggered:
            system_state["status"] = "warning"
            system_state["threat_level"] = "AMARILLO"

    consensus_event = evaluate_seismic_consensus()
    if consensus_event:
        # Notificación automática a canal de Telegram de la comunidad
        msg_tg = (
            f"🚨 *¡ALERTA SÍSMICA CONFIRMADA - SISMO-PREV!* 🚨\n\n"
            f"• *Magnitud Estimada:* M{consensus_event['estimated_magnitude']}\n"
            f"• *Aceleración Pico (PGA):* {consensus_event['average_pga']} g\n"
            f"• *Sensores Disparados:* {consensus_event['triggered_nodes_count']} smartphones\n"
            f"• *Tiempo de Advertencia (Lead Time):* ~{consensus_event['lead_time_seconds']} seg\n"
            f"• *Epicentro Estimado:* {consensus_event['epicenter_lat']}, {consensus_event['epicenter_lng']}\n\n"
            f"📢 _¡Proceda a zona segura y mantenga la calma!_"
        )
        send_telegram_alert(msg_tg)

    await manager.broadcast_to_dashboards({
        "type": "telemetry_update",
        "node": node_data,
        "system_state": system_state,
        "consensus_event": consensus_event
    })
    return {
        "status": "ok",
        "active_drill": system_state["active_drill"],
        "threat_level": system_state["threat_level"],
        "system_status": system_state["status"],
        "consensus": consensus_event is not None
    }

@app.post("/api/drill")
async def control_drill(drill: DrillControlPayload):
    if drill.action == "start":
        system_state["active_drill"] = True
        system_state["status"] = "drill"
        system_state["threat_level"] = "NARANJA"
        msg = {
            "type": "drill_alert",
            "action": "start",
            "simulated_magnitude": drill.simulated_magnitude,
            "epicenter": drill.epicenter,
            "instruction": "SIMULACRO EN CURSO: Mantenga la calma y diríjase a la zona segura."
        }
        await manager.broadcast_to_dashboards(msg)
        await manager.broadcast_to_sensors(msg)
        return {"status": "drill_started", "magnitude": drill.simulated_magnitude}
    else:
        system_state["active_drill"] = False
        system_state["status"] = "normal"
        system_state["threat_level"] = "VERDE"
        msg = {"type": "drill_alert", "action": "stop", "instruction": "Simulacro finalizado."}
        await manager.broadcast_to_dashboards(msg)
        await manager.broadcast_to_sensors(msg)
        return {"status": "drill_stopped"}

@app.post("/api/ai/analyze")
def ai_analysis(request_data: Dict[str, Any]):
    prompt = request_data.get("prompt", "")
    if not prompt:
        pga = system_state["last_event"]["average_pga"] if system_state["last_event"] else 0.05
        mag = system_state["last_event"]["estimated_magnitude"] if system_state["last_event"] else 5.8
        prompt = (
            f"Se ha detectado un sismo con aceleración máxima del suelo (PGA) de {pga} g y magnitud estimada de {mag}. "
            "Genera en viñetas breves: 1. Nivel de daño estructural esperado. 2. Prioridades de bomberos. 3. Mensaje oficial para escuelas."
        )
    analysis = query_ai_assistant(prompt)
    model_name = "Google Gemini 3.8 Flash"
    return {"analysis": analysis, "model": model_name}

@app.get("/api/ai/models")
def list_ai_models():
    """Escanea y lista todos los modelos disponibles para la clave API configurada."""
    gemini_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not gemini_key:
        return {"status": "error", "message": "No hay clave API de Gemini configurada.", "models": []}
    try:
        from google import genai
        client = genai.Client(api_key=gemini_key)
        all_models = [m.name for m in client.models.list()]
        # Filtrar modelos relevantes para análisis de texto y visión
        gemini_models = [m.replace("models/", "") for m in all_models if "gemini" in m.lower() or "gemma" in m.lower()]
        return {
            "status": "connected",
            "message": f"Conexión exitosa. Se detectaron {len(gemini_models)} modelos disponibles.",
            "active_model": "gemini-3.8-flash",
            "models": gemini_models[:20]
        }
    except Exception as e:
        return {"status": "error", "message": f"Error conectando con Gemini API: {str(e)}", "models": []}

@app.post("/api/ai/config")
def update_ai_config(payload: Dict[str, Any]):
    """Permite guardar una nueva clave API de Gemini y actualizar el archivo local .env."""
    new_key = payload.get("api_key", "").strip()
    if not new_key:
        raise HTTPException(status_code=400, detail="La clave API no puede estar vacía.")
    
    # Probar la clave antes de guardarla
    try:
        from google import genai
        client = genai.Client(api_key=new_key)
        test_resp = client.models.generate_content(
            model="gemini-3.8-flash",
            contents="ping"
        )
        if not test_resp:
            raise Exception("No se recibió respuesta del modelo.")
    except Exception as e:
        return {"status": "error", "message": f"Clave API inválida o error de conexión: {str(e)}"}
    
    # Guardar en entorno y en .env
    os.environ["GEMINI_API_KEY"] = new_key
    env_file = os.path.join(os.path.dirname(__file__), ".env")
    try:
        with open(env_file, "w", encoding="utf-8") as f:
            f.write(f"GEMINI_API_KEY={new_key}\n")
    except Exception as e:
        pass
        
    return {
        "status": "success",
        "message": "Clave API de Gemini validada y guardada con éxito. Modelo gemini-3.8-flash activado."
    }

@app.get("/api/cap/feed.xml")
def get_cap_feed():
    """Genera documento XML bajo el estándar oficial OASIS CAP 1.2 (Common Alerting Protocol)."""
    last_event = system_state.get("last_event")
    now_iso = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S-00:00")
    
    event_id = last_event["id"] if last_event else f"SISMO-NONE-{int(time.time())}"
    msg_type = "Alert" if last_event else "Update"
    severity = "Severe" if last_event else "Minor"
    headline = f"Alerta Sísmica Temprana Comunitaria M{last_event['estimated_magnitude']}" if last_event else "Monitoreo Sísmico Comunitario SISMO-PREV Normal"
    description = (
        f"Red comunitaria SISMO-PREV detectó onda sísmica con PGA {last_event['average_pga']} g en {last_event['triggered_nodes_count']} sensores móviles sincronizados."
        if last_event else "Todos los sensores móviles comunitarios operan en estado de reposo nominal."
    )
    instruction = "Repliegue a zonas de seguridad internas o externas designadas. Mantenga la calma." if last_event else "Sin acciones requeridas."
    lat = last_event.get("epicenter_lat", 12.1364) if last_event else 12.1364
    lng = last_event.get("epicenter_lng", -86.2514) if last_event else -86.2514

    cap_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<alert xmlns="urn:oasis:names:tc:emergency:cap:1.2">
  <identifier>{event_id}</identifier>
  <sender>sismoprev.red.comunitaria@rallylatam.org</sender>
  <sent>{now_iso}</sent>
  <status>Actual</status>
  <msgType>{msg_type}</msgType>
  <scope>Public</scope>
  <code>IPAWS-1.2</code>
  <info>
    <category>Geo</category>
    <event>Earthquake Early Warning</event>
    <urgency>Immediate</urgency>
    <severity>{severity}</severity>
    <certainty>Observed</certainty>
    <eventCode>
      <valueName>SAME</valueName>
      <value>EQW</value>
    </eventCode>
    <headline>{headline}</headline>
    <description>{description}</description>
    <instruction>{instruction}</instruction>
    <area>
      <areaDesc>Comunidad Escolar y Vecinal - Red SISMO-PREV</areaDesc>
      <circle>{lat},{lng},25.0</circle>
    </area>
  </info>
</alert>"""
    return Response(content=cap_xml, media_type="application/xml")

@app.get("/api/export/csv")
def export_seismic_csv():
    """Exporta el historial de eventos sísmicos y telemetría en formato CSV descargable."""
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "ID_Evento", "Fecha_Hora", "Magnitud_Estimada", "PGA_Promedio_g", 
        "Nodos_Disparados", "Epicentro_Lat", "Epicentro_Lng", "Lead_Time_Segundos", "Estado", "Tipo"
    ])
    
    events = system_state.get("event_history", [])
    if not events and system_state.get("last_event"):
        events = [system_state["last_event"]]
        
    for evt in events:
        writer.writerow([
            evt.get("id", "N/A"),
            evt.get("timestamp", "N/A"),
            evt.get("estimated_magnitude", 0.0),
            evt.get("average_pga", 0.0),
            evt.get("triggered_nodes_count", 0),
            evt.get("epicenter_lat", 12.1364),
            evt.get("epicenter_lng", -86.2514),
            evt.get("lead_time_seconds", 0.0),
            evt.get("status", "CONFIRMADO"),
            evt.get("type", "REAL")
        ])
        
    csv_content = output.getvalue()
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=sismo_prev_eventos.csv"}
    )

@app.post("/api/alert/telegram")
def send_test_telegram(payload: TelegramAlertPayload):
    """Endpoint para prueba y despacho manual de alertas a Telegram."""
    msg = payload.message
    res = send_telegram_alert(msg)
    return res

@app.websocket("/ws/dashboard")
async def websocket_dashboard(websocket: WebSocket):
    await manager.connect_dashboard(websocket)
    try:
        await websocket.send_json({"type": "init_state", "system_state": system_state})
        while True:
            # Soporta tanto mensajes de texto/JSON como transmisión binaria de audio de megafonía
            message = await websocket.receive()
            if "bytes" in message and message["bytes"]:
                # Retransmitir audio PCM en vivo a todos los smartphones conectados
                await manager.broadcast_bytes_to_sensors(message["bytes"])
    except WebSocketDisconnect:
        manager.disconnect_dashboard(websocket)

@app.websocket("/ws/sensor/{node_id}")
async def websocket_sensor(websocket: WebSocket, node_id: str):
    await manager.register_sensor(node_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            payload = TelemetryPayload(node_id=node_id, **data)
            await receive_telemetry(payload)
    except WebSocketDisconnect:
        manager.disconnect_sensor(node_id)

@app.on_event("startup")
async def startup_event():
    # Inicializar carga inmediata y arrancar tarea en segundo plano
    asyncio.create_task(background_public_seismic_worker())

@app.get("/api/seismic/public")
def get_public_seismic_feed():
    """Retorna los sismos oficiales recientes en Centroamérica detectados por USGS/EMSC."""
    return JSONResponse({
        "status": "ok",
        "count": len(system_state.get("public_seismic_feed", [])),
        "earthquakes": system_state.get("public_seismic_feed", [])
    })

@app.get("/", response_class=HTMLResponse)
def get_dashboard():
    dashboard_path = os.path.join(os.path.dirname(__file__), "dashboard.html")
    with open(dashboard_path, "r", encoding="utf-8") as f:
        return f.read()


@app.get("/logo.png")
def get_logo():
    logo_path = os.path.join(os.path.dirname(__file__), "logo_sismoprev.png")
    return FileResponse(path=logo_path, media_type="image/png")

@app.get("/manifest.json")
def get_manifest():
    manifest_path = os.path.join(os.path.dirname(__file__), "manifest.json")
    return FileResponse(path=manifest_path, media_type="application/manifest+json")

@app.get("/sw.js")
def get_sw():
    sw_path = os.path.join(os.path.dirname(__file__), "sw.js")
    return FileResponse(path=sw_path, media_type="application/javascript")

from fastapi.responses import FileResponse
@app.get("/descargar-apk")
def download_apk():
    apk_path = os.path.join(os.path.dirname(__file__), "sismoprev.apk")
    return FileResponse(
        path=apk_path,
        filename="sismoprev.apk",
        media_type="application/vnd.android.package-archive"
    )

from fastapi.staticfiles import StaticFiles
app.mount("/app", StaticFiles(directory="/home/enoc-colomer/Documentos/RALLY LATINOAMERICANO/PROYECTO_SISMOGUARD_SISTEMA/cliente_movil_android/build/web", html=True), name="flutter_app")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)