@echo off
chcp 65001 >nul
title 彩虹岛S2客户端

set SERVER_IP=127.0.0.1
if not "%1"=="" set SERVER_IP=%1

echo 连接服务器: %SERVER_IP%:19999
echo.
start LaTaleClient.exe /Windowed /LoginServer:%SERVER_IP%:19999 /Run:VHIGH /LOCALE:TAIWAN /PUBLISHER:GAMEFLIER
