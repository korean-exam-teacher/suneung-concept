# 한글 책 두 판을 만들고, 한글로 열어 차례 쪽 번호를 채운 뒤 PDF도 저장함
# 사용법: powershell -ExecutionPolicy Bypass -File tools\make_book.ps1 [-Only Lite|Full]
# 한글이 '파일 접근' 확인 창을 띄우면 [모두 허용]을 눌러 주세요(한 번만 뜹니다).
param([ValidateSet('Lite', 'Full', 'Both')][string]$Only = 'Both')
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Gen = "$PSScriptRoot\make_hwpx.ps1"
$Tmp = Join-Path $env:TEMP 'smgm-book'; New-Item -ItemType Directory -Force $Tmp | Out-Null
$U8 = New-Object Text.UTF8Encoding $false
function Log($m){ Write-Host ("[{0:HH:mm:ss}] {1}" -f (Get-Date), $m) }

$editions = @()
if($Only -ne 'Full'){ $editions += @{ name = 'Lite'; out = "$Root\book\수능국어_개념서_가벼운판.hwpx"; lite = $true } }
if($Only -ne 'Lite'){ $editions += @{ name = 'Full'; out = "$Root\book\수능국어_개념서.hwpx"; lite = $false } }

$hwp = New-Object -ComObject HWPFrame.HwpObject
try { $hwp.XHwpWindows.Item(0).Visible = $false } catch {}
# 비교용: 한글 음절·영문·숫자만 남김(줄 바꿈·띄어쓰기·옛한글 차이를 없앰)
function Norm($s){ ([string]$s) -replace '[^가-힣A-Za-z0-9]', '' }
try {
  foreach($ed in $editions){
    $p1 = Join-Path $Tmp "$($ed.name)_pass1.hwpx"
    Log "$($ed.name): 1차 만들기"
    if($ed.lite){ & $Gen -Lite -Out $p1 } else { & $Gen -Out $p1 }
    Log "$($ed.name): 한글로 열어 쪽 번호 찾기"
    [void]$hwp.Open($p1, 'HWPX', 'forceopen:true')
    $anchors = [IO.File]::ReadAllText("$p1.paras.json", [Text.Encoding]::UTF8) | ConvertFrom-Json
    $n = $hwp.PageCount
    $texts = @(for($pg = 0; $pg -lt $n; $pg++){ Norm ($hwp.GetPageText($pg, 0)) })
    # 차례 항목은 책 순서대로이므로 앞에서 찾은 쪽부터 이어서 찾음
    $map = [ordered]@{}; $at = 1; $miss = @()
    foreach($pr in $anchors.PSObject.Properties){
      $needle = Norm $pr.Value
      if($needle.Length -gt 24){ $needle = $needle.Substring(0, 24) }
      $found = -1
      for($pg = $at; $pg -lt $n; $pg++){ if($texts[$pg].Contains($needle)){ $found = $pg; break } }
      if($found -lt 0){ $miss += $pr.Name; $found = $at }
      $map[$pr.Name] = $found + 1; $at = $found
    }
    if($miss.Count){ Log ("찾지 못한 항목 {0}개: {1}" -f $miss.Count, (($miss | Select-Object -First 8) -join ', ')) }
    $hwp.Clear(1)
    $pm = Join-Path $Tmp "$($ed.name)_pages.json"
    [IO.File]::WriteAllText($pm, (ConvertTo-Json -InputObject $map -Compress), $U8)
    Log ("$($ed.name): 쪽 번호 {0}개 (예: 차례 {1}쪽)" -f $map.Count, $map['toc'])
    Log "$($ed.name): 쪽 번호를 채워 다시 만들기"
    # 한글은 USB 같은 바깥 드라이브의 파일을 열 때 '파일 접근' 확인 창을 띄우므로, 임시 폴더에서 만들고 연 뒤 옮김
    $p2 = Join-Path $Tmp "$($ed.name)_final.hwpx"
    if($ed.lite){ & $Gen -Lite -Out $p2 -PageMap $pm } else { & $Gen -Out $p2 -PageMap $pm }
    Remove-Item "$p2.paras.json" -ErrorAction SilentlyContinue
    Log "$($ed.name): 확인하고 PDF 저장"
    [void]$hwp.Open($p2, 'HWPX', 'forceopen:true')
    $pages = $hwp.PageCount
    $pdfTmp = [IO.Path]::ChangeExtension($p2, '.pdf')
    [void]$hwp.SaveAs($pdfTmp, 'PDF', '')
    $hwp.Clear(1)
    $pdf = [IO.Path]::ChangeExtension($ed.out, '.pdf')
    Copy-Item $p2 $ed.out -Force
    Copy-Item $pdfTmp $pdf -Force
    Log ("$($ed.name): 완료 — {0}쪽, {1}" -f $pages, (Split-Path $pdf -Leaf))
  }
} finally {
  try { $hwp.Quit() } catch {}
}
