<#
刺客教條 1（Steam 導演剪輯版）英中雙語字幕一鍵安裝。

流程：找遊戲資料夾 → 備份 → 下載三個 mod → 安裝 → 套用設定 → 換中文字型
      → 放入雙語字幕 → （可選）中文介面 → 複製 Steam 啟動選項到剪貼簿。

參數都可省略，省略時會互動詢問：
  -GameDir         遊戲資料夾
  -SubtitlesJson   你的雙語 subtitles.json
  -ChinesePackDir  其樂中文化包解壓後的資料夾（要裝中文介面才需要）
  -SkipChineseUI   不裝中文介面
  -Yes             所有確認都自動回答「是」
#>
param(
    [string]$GameDir,
    [string]$SubtitlesJson,
    [string]$ChinesePackDir,
    [switch]$SkipChineseUI,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Mods = @(
    @{ Name = 'Ultimate ASI Loader v10.0.0'; Url = 'https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/v10.0.0/Ultimate-ASI-Loader-NoPDB.zip' }
    @{ Name = 'EaglePatchAC1 v1.1';          Url = 'https://github.com/Sergeanur/EaglePatch/releases/download/v1.1/EaglePatchAC1.zip' }
    @{ Name = 'SubtitleSynchAC1 v2.0.0';     Url = 'https://github.com/bloxtbc/SubtitleSynchAC1/releases/download/v2.0.0/SubtitleSynchAC1.zip' }
)
$KeylolUrl = 'https://keylol.com/t1044005-1-1'
# 中文介面外掛「兜底」1024 快取版；2048 版會在主選單就崩潰
$LgAc1024Md5 = '4AB363F8B204'
$OriginalFontSize = 38304044

function Step($n, $text) { Write-Host "`n[$n] $text" -ForegroundColor Cyan }
function Ok($text) { Write-Host "    $text" -ForegroundColor Green }
function Warn($text) { Write-Host "    $text" -ForegroundColor Yellow }

function Confirm($question) {
    if ($Yes) { return $true }
    return (Read-Host "    $question (Y/n)") -notmatch '^[nN]'
}

function Ask-Path($question, [scriptblock]$valid) {
    while ($true) {
        $p = (Read-Host "    $question").Trim('"', ' ')
        if ($p -and (& $valid $p)) { return $p }
        Warn '找不到或不正確，請再輸入一次。'
    }
}

function Find-GameDir {
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { return $null }
    $libs = @($steam)
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        $libs += [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value -replace '\\\\', '\' }
    }
    foreach ($lib in $libs | Select-Object -Unique) {
        $dir = Join-Path $lib 'steamapps\common\Assassins Creed'
        if (Test-Path (Join-Path $dir 'AssassinsCreed_Dx9.exe')) { return $dir }
    }
    return $null
}

function Get-Zip($url, $dest) {
    $file = Join-Path $dest ([IO.Path]::GetFileName($url))
    if (-not (Test-Path $file)) { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
    $out = Join-Path $dest ([IO.Path]::GetFileNameWithoutExtension($url))
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    Expand-Archive -LiteralPath $file -DestinationPath $out
    return $out
}

function Set-IniValue($path, $key, $value) {
    $lines = Get-Content $path
    $lines = $lines -replace "^$key=.*", "$key=$value"
    Set-Content -Path $path -Value $lines -Encoding ASCII
}

Write-Host '刺客教條 1 英中雙語字幕安裝程式' -ForegroundColor White

# 1. 遊戲資料夾
Step 1 '尋找遊戲資料夾'
if (-not $GameDir) { $GameDir = Find-GameDir }
if ($GameDir -and (Test-Path (Join-Path $GameDir 'AssassinsCreed_Dx9.exe'))) {
    Ok "找到：$GameDir"
} else {
    Warn '自動偵測失敗。'
    $GameDir = Ask-Path '請貼上遊戲資料夾（含 AssassinsCreed_Dx9.exe）' { param($p) Test-Path (Join-Path $p 'AssassinsCreed_Dx9.exe') }
}
$Scripts = Join-Path $GameDir 'scripts'
$Work = Join-Path $env:TEMP 'ac1-zh-tw-install'
New-Item -ItemType Directory -Force $Work | Out-Null

# 2. 備份
Step 2 '備份會被覆蓋的檔案'
$Backup = Join-Path $GameDir ('_backup_' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $Backup | Out-Null
foreach ($f in 'dinput8.dll', 'scripts') {
    $src = Join-Path $GameDir $f
    if (Test-Path $src) { Copy-Item $src $Backup -Recurse -Force }
}
Ok "備份在 $Backup"

# 3. 下載 mod
Step 3 '從 GitHub 下載 mod'
$dirs = foreach ($m in $Mods) {
    Write-Host "    下載 $($m.Name)..."
    Get-Zip $m.Url $Work
}
Ok '下載完成'

# 4. 安裝 mod
Step 4 '安裝 mod'
New-Item -ItemType Directory -Force $Scripts | Out-Null
Copy-Item (Join-Path $dirs[0] 'dinput8.dll') $GameDir -Force
Copy-Item (Join-Path $dirs[1] 'EaglePatchAC1.asi'), (Join-Path $dirs[1] 'EaglePatchAC1.ini') $Scripts -Force
Copy-Item (Join-Path $dirs[2] 'SubtitleSynchAC1\*') $Scripts -Force
Ok '已安裝 ASI Loader、EaglePatch、SubtitleSynch'

# 5. 設定
Step 5 '套用設定'
Set-IniValue (Join-Path $Scripts 'SubtitleSynchAC1.ini') 'PaddingX' '32'
Set-IniValue (Join-Path $Scripts 'SubtitleSynchAC1.ini') 'PaddingY' '16'
Set-IniValue (Join-Path $Scripts 'EaglePatchAC1.ini') 'SkipIntroVideos' '1'
Ok '字幕框高度修正（PaddingY=16）、跳過開場影片'

# 6. 中文字型
Step 6 '換成中文字型'
$font = 'C:\Windows\Fonts\msjhbd.ttc'
if (-not (Test-Path $font)) { $font = 'C:\Windows\Fonts\msjh.ttc' }
if (Test-Path $font) {
    Copy-Item $font (Join-Path $Scripts 'subtitles.ttf') -Force
    Ok "使用 $([IO.Path]::GetFileName($font))（微軟正黑體）"
} else {
    Warn '找不到微軟正黑體，中文會顯示成問號；請手動把任一中文字型複製成 scripts\subtitles.ttf'
}

# 7. 雙語字幕
Step 7 '放入雙語字幕'
if (-not $SubtitlesJson) {
    Write-Host '    本安裝程式不附字幕內容。請準備好你的雙語 subtitles.json（做法見 README）。'
    if (Confirm '現在要指定 subtitles.json 嗎？選 n 會先保留英文字幕') {
        $SubtitlesJson = Ask-Path '請貼上 subtitles.json 的完整路徑' { param($p) (Test-Path $p) -and $p -match '\.json$' }
    }
}
if ($SubtitlesJson) {
    Copy-Item $SubtitlesJson (Join-Path $Scripts 'subtitles.json') -Force
    Ok '已放入雙語字幕'
} else {
    Warn '目前是英文字幕；之後把雙語 subtitles.json 覆蓋到 scripts\ 即可'
}

# 8. 中文介面（可選）
Step 8 '中文介面（可選）'
Write-Host '    中文介面外掛會在「從古代記憶切回現代」時可能崩潰，那一段可用 toggle-chinese-ui.bat 暫時關閉。'
$wantUi = -not $SkipChineseUI -and ($ChinesePackDir -or (Confirm '要安裝中文介面嗎？'))
if ($wantUi) {
    if (-not $ChinesePackDir) {
        Write-Host "    即將開啟其樂帖子：$KeylolUrl"
        Write-Host '    請從帖子裡的網盤下載中文化包，把壓縮檔和裡面的 zip 全部解壓到同一個資料夾。'
        Start-Process $KeylolUrl
        $ChinesePackDir = Ask-Path '解壓完成後，貼上那個資料夾的路徑' { param($p) Test-Path $p -PathType Container }
    }
    $files = Get-ChildItem -LiteralPath $ChinesePackDir -Recurse -File
    $asi = $files | Where-Object { $_.Name -eq 'LG_AC.asi' -and (Get-FileHash $_.FullName -Algorithm MD5).Hash.StartsWith($LgAc1024Md5) } | Select-Object -First 1
    $tga = $files | Where-Object { $_.Name -eq 'LG_Font_02.tga' -and $_.Length -eq $OriginalFontSize } | Select-Object -First 1
    if ($asi -and $tga) {
        Copy-Item $asi.FullName $Scripts -Force
        Get-ChildItem -LiteralPath $tga.DirectoryName -Filter 'LG*' | Where-Object { $_.Name -ne 'LG_AC.asi' } | Copy-Item -Destination $Scripts -Force
        Ok '已安裝中文介面（1024 穩定版外掛＋原版繁中字庫）'
    } else {
        if (-not $asi) { Warn '找不到 1024 版 LG_AC.asi：請確認「Animus还卡就自己找里面的LG_AC.asi换着试.zip」也解壓了' }
        if (-not $tga) { Warn '找不到原版字庫：請確認「繁中原版字幕（最终保底）」資料夾在裡面' }
        Warn '中文介面略過，其他部分不受影響'
    }
}

# 9. Steam 啟動選項
Step 9 'Steam 啟動選項'
$launch = '"' + (Join-Path $GameDir 'AssassinsCreed_Dx9.exe') + '" %command%'
Set-Clipboard -Value $launch
Write-Host '    Steam 預設會跑 DX10 版，mod 不支援（按「開始」幾秒就跳回來）。'
Write-Host '    已把下面這行複製到剪貼簿，請到 Steam：右鍵遊戲 → 內容 → 一般 → 啟動選項，貼上：'
Write-Host "    $launch" -ForegroundColor White

Write-Host "`n完成！" -ForegroundColor Green
Write-Host '提醒：Windows 遊戲模式會在遊戲執行時暫停 OneDrive，遊戲崩潰後不會自動恢復。'
Write-Host '      可在遊戲中按 Win+G → 設定 → 取消「記住這是遊戲」。'
Write-Host "還原：執行 tools\restore-english.bat，或把 $Backup 的內容複製回去。"
