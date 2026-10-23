@echo off
chcp 65001 >nul
rem 改成你的遊戲路徑
set "GAME=C:\Program Files (x86)\Steam\steamapps\common\Assassins Creed"
set "S=%GAME%\scripts"

if exist "%S%\LG_AC.asi" (
  ren "%S%\LG_AC.asi" LG_AC.asi.off
  echo 已關閉中文介面（LG_AC）。介面變回英文，雙語對話字幕不受影響。
) else if exist "%S%\LG_AC.asi.off" (
  ren "%S%\LG_AC.asi.off" LG_AC.asi
  echo 已開啟中文介面（LG_AC）。注意：從古代記憶切回現代時可能崩潰。
) else (
  echo 找不到 LG_AC.asi，請確認 GAME 路徑。
)
pause
