import os
import json
import time
import asyncio
from typing import Dict, List, Any
import requests
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel

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

manager = ConnectionManager()

system_state = {
    "status": "normal",
    "threat_level": "VERDE",
    "active_drill": False,
    "last_event": None,
    "nodes": {},
    "event_history": []
}

class TelemetryPayload(BaseModel):
    node_id: str
    place: str = "Comunidad Local"
    lat: float = 12.1364
    lng: float = -86.2514
    pga: float = 0.001
    sta_lta_ratio: float = 1.0
    is_triggered: bool = False
    battery: int = 100

class DrillControlPayload(BaseModel):
    action: str
    simulated_magnitude: float = 6.8
    epicenter: str = "Falla Local - Costa del Pacífico"

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
                model="gemini-2.5-flash",
                contents=prompt,
                config={"system_instruction": system_instruction}
            )
            if response and response.text:
                return "Google Gemini 2.5 Flash:\n" + response.text.strip()
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

        system_state["status"] = "earthquake"
        system_state["threat_level"] = "ROJO"
        event = {
            "id": f"EVT-{int(now)}",
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "estimated_magnitude": mag_est,
            "average_pga": round(avg_pga, 4),
            "triggered_nodes_count": count,
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
        system_state["status"] = "warning"
        system_state["threat_level"] = "AMARILLO"

    consensus_event = evaluate_seismic_consensus()

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
    model_name = "Google Gemini 2.5 Flash" if os.environ.get("GEMINI_API_KEY") else "SISMO-PREV AI Engine"
    return {"analysis": analysis, "model": model_name}

@app.websocket("/ws/dashboard")
async def websocket_dashboard(websocket: WebSocket):
    await manager.connect_dashboard(websocket)
    try:
        await websocket.send_json({"type": "init_state", "system_state": system_state})
        while True:
            await websocket.receive_text()
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

@app.get("/", response_class=HTMLResponse)
def get_dashboard():
    dashboard_path = os.path.join(os.path.dirname(__file__), "dashboard.html")
    with open(dashboard_path, "r", encoding="utf-8") as f:
        return f.read()


@app.get("/logo.png")
def get_logo():
    logo_path = os.path.join(os.path.dirname(__file__), "logo_sismoprev.png")
    return FileResponse(path=logo_path, media_type="image/png")

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