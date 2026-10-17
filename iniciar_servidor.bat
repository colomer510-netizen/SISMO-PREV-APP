@echo off
chcp 65001 > nul
title Servidor Central SISMO-PREV - Rally 2026
color 0A

echo ============================================================
echo       🚨 INICIANDO SERVIDOR CENTRAL SISMO-PREV 🚨
echo ============================================================

:: Verificar si python está en el PATH
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python no está instalado o no se encuentra en el PATH.
    echo Por favor descargue e instale Python desde https://www.python.org/
    pause
    exit /b 1
)

set "DIR=%~dp0"
cd /d "%DIR%"

:: Crear entorno virtual si no existe
if not exist "%DIR%venv_sismoprev" (
    echo [INFO] Creando entorno virtual 'venv_sismoprev'...
    python -m venv "%DIR%venv_sismoprev"
    echo [INFO] Instalando dependencias necesarias...
    "%DIR%venv_sismoprev\Scripts\python.exe" -m pip install --upgrade pip
    "%DIR%venv_sismoprev\Scripts\pip.exe" install -r "%DIR%servidor_monitoreo\requirements.txt"
)

echo.
echo [OK] Entorno virtual preparado correctamente.
echo [INFO] Iniciando servidor de monitoreo en el puerto 8080...
echo.
echo  - Dashboard de Control: http://localhost:8080
echo  - App Móvil (Web/PWA):  http://localhost:8080/app/
echo  - Descarga APK Android: http://localhost:8080/descargar-apk
echo.
echo Presione Ctrl + C para detener el servidor.
echo ------------------------------------------------------------

"%DIR%venv_sismoprev\Scripts\python.exe" "%DIR%servidor_monitoreo\server.py"

pause
