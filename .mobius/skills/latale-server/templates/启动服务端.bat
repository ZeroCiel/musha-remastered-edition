@echo off
chcp 936 >nul
cd /d "D:\彩虹岛\彩虹岛物语服务端\Server\BIN2"

echo ========================================
echo   彩虹岛服务端启动
echo ========================================
echo.

echo [1] 启动 MgmtServer...
start "" LataleMgmtServer.exe
timeout /t 6 /nobreak >nul

echo [2] 启动 AS...
start "" LataleAS.exe
timeout /t 6 /nobreak >nul

echo [3] 启动 LoginServer...
start "" LataleLoginServer.exe
timeout /t 4 /nobreak >nul

echo [4] 启动 LobbyServer...
start "" LataleLobbyServer.exe
timeout /t 3 /nobreak >nul

echo [5] Bay + Room + GS...
start "" LataleBayServer.exe
timeout /t 2 /nobreak >nul
start "" LataleRoomServer.exe
timeout /t 2 /nobreak >nul

start "" Latalegameserver_101.exe
timeout /t 1 /nobreak >nul
start "" Latalegameserver_102.exe
timeout /t 1 /nobreak >nul
start "" Latalegameserver_103.exe
timeout /t 1 /nobreak >nul
start "" Latalegameserver_104.exe
timeout /t 1 /nobreak >nul
start "" Latalegameserver_105.exe
timeout /t 1 /nobreak >nul
start "" Latalegameserver_151.exe
timeout /t 1 /nobreak >nul
start "" Latalegameserver_181.exe

echo.
echo ========================================
echo   全部启动！等30秒后进游戏
echo   账号: test   密码: test
echo ========================================
pause
