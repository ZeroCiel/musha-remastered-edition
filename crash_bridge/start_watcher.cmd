@echo off
rem 启动崩溃桥 agent 侧 watcher（隐藏窗口，1s 轮询；双击即可，可随开机自启）
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0watcher.ps1"
