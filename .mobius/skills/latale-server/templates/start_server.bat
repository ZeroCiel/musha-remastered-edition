@echo off
chcp 65001 >nul
title 彩虹岛S2 一键启动服务端

echo ====================================
echo   彩虹岛S2 一键启动
echo   请先手动双击启动"彩虹岛樱花网关.exe"
echo   网关启动后再运行此脚本
echo ====================================
echo.

:wait_gateway
netstat -ano 2>nul | findstr ":5217 " >nul
if %errorlevel% neq 0 (
    echo 等待网关启动...
    timeout /t 3 /nobreak >nul
    goto wait_gateway
)
echo 网关已就绪!
echo.

cd /d D:\Server\BIN2

echo [1/7] 启动 MgmtServer...
start /B LataleMgmtServer.exe
timeout /t 2 /nobreak >nul

echo [2/7] 启动 AS...
start /B LataleAS.exe
timeout /t 2 /nobreak >nul

echo [3/7] 启动 LoginServer...
start /B LataleLoginServer.exe
timeout /t 2 /nobreak >nul

echo [4/7] 启动 LobbyServer...
start /B LataleLobbyServer.exe
timeout /t 2 /nobreak >nul

echo [5/7] 启动 BayServer...
start /B LataleBayServer.exe
timeout /t 2 /nobreak >nul

echo [6/7] 启动 RoomServer...
start /B LataleRoomServer.exe
timeout /t 2 /nobreak >nul

echo [7/7] 启动 GameServer(频道1)...
start /B Latalegameserver_101.exe

echo.
echo ====================================
echo   所有服务已启动!
echo   双击客户端进游戏吧
echo ====================================
pause
