#!/usr/bin/env bash
# ==============================================================================
# SISMO-PREV - Script de Inicio para Linux / macOS
# Desafío 02: Rally Latinoamericano de Innovación 2026
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "============================================================"
echo "      🚨 INICIANDO SERVIDOR CENTRAL SISMO-PREV 🚨"
echo "============================================================"

# Comprobar python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 no está instalado o no se encuentra en el PATH."
    exit 1
fi

# Detectar o crear entorno virtual
VENV_DIR="$DIR/venv_sismoprev"
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creando entorno virtual en $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    echo "📥 Instalando dependencias necesarias..."
    "$VENV_DIR/bin/pip" install --upgrade pip
    "$VENV_DIR/bin/pip" install -r "$DIR/servidor_monitoreo/requirements.txt"
fi

# Detectar IP Local para mostrar al usuario
LOCAL_IP=$(python3 -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); (s.connect(('8.8.8.8', 80)), print(s.getsockname()[0]), s.close())" 2>/dev/null || echo "127.0.0.1")

echo ""
echo "✅ Entorno listo."
echo "🌐 Dirección local del Dashboard:  http://$LOCAL_IP:8080"
echo "📱 App Móvil Web / PWA:           http://$LOCAL_IP:8080/app/"
echo "📦 Descarga directa APK:          http://$LOCAL_IP:8080/descargar-apk"
echo ""
echo "Presione [CTRL + C] para detener el servidor en cualquier momento."
echo "------------------------------------------------------------"

exec "$VENV_DIR/bin/python" "$DIR/servidor_monitoreo/server.py"
