@echo off
chcp 936 >nul
cd /d "%~dp0..\..\BIN2" 2>nul || cd /d "D:\彩虹岛\彩虹岛~1\Server\BIN2"

echo ========================================
echo   彩虹岛服务端启动
echo ========================================
echo.

echo [1] 启动 MgmtServer...
start "Mgmt" LataleMgmtServer.exe
timeout /t 6 /nobreak >nul

echo [2] 启动 AS...
start "AS" LataleAS.exe
timeout /t 6 /nobreak >nul

echo [3] 启动 LoginServer...
start "Login" LataleLoginServer.exe
timeout /t 4 /nobreak >nul

echo [4] 启动 LobbyServer...
start "Lobby" LataleLobbyServer.exe
timeout /t 3 /nobreak >nul

echo [5] Bay + Room + GS...
start "Bay" LataleBayServer.exe
timeout /t 2 /nobreak >nul
start "Room" LataleRoomServer.exe
timeout /t 2 /nobreak >nul

start "GS101" LataleGameServer101.exe
timeout /t 1 /nobreak >nul
start "GS102" LataleGameServer102.exe
timeout /t 1 /nobreak >nul
start "GS103" LataleGameServer103.exe
timeout /t 1 /nobreak >nul
start "GS104" LataleGameServer104.exe
timeout /t 1 /nobreak >nul
start "GS105" LataleGameServer105.exe
timeout /t 1 /nobreak >nul
start "GS151" LataleGameServer151.exe
timeout /t 1 /nobreak >nul
start "GS181" LataleGameServer181.exe

echo.
echo ========================================
echo   全部启动！等30秒后进游戏
echo ========================================
pause
