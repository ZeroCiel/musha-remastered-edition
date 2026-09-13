@echo off
chcp 65001 >nul
echo 切换到【联机数据库】
echo 请手动输入远程数据库IP和端口
echo.
set /p DB_IP=请输入数据库IP（如 192.168.1.100）: 
set /p DB_PORT=请输入端口（默认59157）: 
if "%DB_PORT%"=="" set DB_PORT=59157
echo.
echo 连接: %DB_IP%:%DB_PORT%
echo 按任意键确认切换...
pause >nul
(
echo ;Latale_ODBC.ini
echo.
echo [AccountDB]
echo IP = %DB_IP%,%DB_PORT%
echo ID = sa
echo PW = 123456
echo.
echo [GameDB]
echo IP = %DB_IP%,%DB_PORT%
echo ID = sa
echo PW = 123456
echo [GameDB_1]
echo ID= sa
echo PW= 123456
) > D:\LaTale\S4\bin2\Latale_ODBC.ini
echo.
echo 已切换为联机数据库！
echo 目标: %DB_IP%:%DB_PORT%
pause
