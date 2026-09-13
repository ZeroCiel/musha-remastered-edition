@echo off
chcp 65001 >nul
echo 切换到【本地数据库】
echo 当前数据库: 127.0.0.1:59157
echo.
echo 按任意键开始...
pause >nul
(
echo ;Latale_ODBC.ini
echo.
echo [AccountDB]
echo IP = 127.0.0.1,59157
echo ID = sa
echo PW = 123456
echo.
echo [GameDB]
echo IP = 127.0.0.1,59157
echo ID = sa
echo PW = 123456
echo [GameDB_1]
echo ID= sa
echo PW= 123456
) > D:\LaTale\S4\bin2\Latale_ODBC.ini
echo.
echo 已切换为本地数据库！
pause
