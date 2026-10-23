@echo off
chcp 65001 >nul
rem 改成你的遊戲路徑
set "GAME=C:\Program Files (x86)\Steam\steamapps\common\Assassins Creed"

echo 將移除所有 mod，還原成原版：
echo   %GAME%\dinput8.dll
echo   %GAME%\scripts\
pause
del /q "%GAME%\dinput8.dll"
del /q "%GAME%\steam_appid.txt" 2>nul
rmdir /s /q "%GAME%\scripts"
echo 完成。也可以在 Steam 驗證遊戲檔案完整性再確認一次。
pause
