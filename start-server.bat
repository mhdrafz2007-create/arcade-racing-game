@echo off
title Velocity Rush - Server & Mobile Tunnel
echo ========================================================
echo   Starting Velocity Rush Server & Tunnel for Phone
echo ========================================================
start /b powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"
"%~dp0cloudflared.exe" tunnel --url http://localhost:8080
pause
