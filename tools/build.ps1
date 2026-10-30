# 수능국어 개념서 빌드: content/*.json + 문제은행 기출 → docs/data.js, book/book.json
# 사용법: powershell -ExecutionPolicy Bypass -File tools\build.ps1 [-Bank "<문제은행 docs 폴더>"]
param(
  [string]$Bank = "F:\평가원 기출 문제 모음\문제은행_저장소\docs"
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$U8 = New-Object Text.UTF8Encoding $false
function ReadText($p){ [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) }
function WriteText($p, $t){ [IO.File]::WriteAllText($p, $t, $U8) }
function Arr($x){ ,@($x | Where-Object { $null -ne $_ }) }
function ToJson($o){ ConvertTo-Json -InputObject $o -Depth 30 -Compress }

# ---------- 1. 내용 파일 ----------
$chapters = @()
Get-ChildItem "$Root\content\*.json" | Sort-Object Name | ForEach-Object {
  try { $ch = ReadText $_.FullName | ConvertFrom-Json }
  catch { throw "JSON 오류: $($_.Exception.Message) — $($_.TargetObject)" }
  $ch | Add-Member -NotePropertyName file -NotePropertyValue $_.Name -Force
  $chapters += $ch
}
Write-Host ("장 {0}개, 개념 {1}개" -f $chapters.Count, ($chapters | ForEach-Object { $_.concepts.Count } | Measure-Object -Sum).Sum)

# ---------- 2. 문제은행 데이터 ----------
$html = ReadText "$Bank\index.html"
function BankConst($name){
  $m = [regex]::Match($html, "(?m)^const $name = (.*?);?\s*$")
  if(-not $m.Success){ throw "문제은행에서 $name 을 찾지 못했습니다" }
  $m.Groups[1].Value | ConvertFrom-Json
}
$ITEMS = BankConst 'ITEMS'
$PASSAGES = BankConst 'PASSAGES'
$CHOICES = BankConst 'CHOICES'
$FIGS = BankConst 'FIGS'
$EXPLAIN = (ReadText "$Bank\explain.json" | ConvertFrom-Json).i
# 2028학년도 예시문항도 함께 씀
$ITEMS = @(foreach($x in $ITEMS){ $x }) + @(foreach($x in (BankConst 'ITEMS_2028')){ $x })
foreach($src in @(@((BankConst 'PASSAGES_2028'), $PASSAGES), @((BankConst 'CHOICES_2028'), $CHOICES))){
  foreach($p in $src[0].PSObject.Properties){ $src[1] | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force }
}
function Prop($o, $k){ $p = $o.PSObject.Properties[$k]; if($p){ $p.Value } else { $null } }
function Plain($s){ if($null -eq $s){ return '' }; ([string]$s) -replace '[\uFDD0-\uFDD3]', '' }

$pool = foreach($it in $ITEMS){
  $key = "{0}||{1}||{2}" -f $it.exam_id, $it.영역, $it.문항번호
  $ch = Prop $CHOICES $key
  $text = (Plain $it.발문) + ' ' + (Plain $it.보기) + ' ' + (($ch | ForEach-Object { Plain $_ }) -join ' ')
  $ptext = ''
  if($it.지문범위 -ne '(독립 문항)'){ $ptext = Plain (Prop $PASSAGES ("{0}||{1}||{2}" -f $it.exam_id, $it.영역, $it.지문범위)) }
  [pscustomobject]@{ key=$key; it=$it; text=$text; ptext=$ptext; rank=([int]$it.연도*100 + [int]$it.시행월) }
}
Write-Host "기출 문항 $($pool.Count)개 읽음"

function CountHits($text, $words){
  $n = 0
  foreach($w in $words){ if($w){ $n += ([regex]::Matches($text, [regex]::Escape($w))).Count } }
  $n
}

# ---------- 3. 개념별 기출 고르기 ----------
$used = @{}
foreach($ch in $chapters){
  foreach($c in $ch.concepts){
    $k = $c.kichul
    $picked = New-Object System.Collections.ArrayList
    if($k){
      $areas = @($k.areas | Where-Object { $_ })
      $groups = @($k.groups | Where-Object { $_ })
      $genres = @($k.genres | Where-Object { $_ })
      $words = @($k.any | Where-Object { $_ })
      $max = if($k.max){ [int]$k.max } else { 6 }
      foreach($fk in @($k.items | Where-Object { $_ })){ if($picked.Count -lt $max){ [void]$picked.Add($fk) } }
      $cands = foreach($p in $pool){
        $it = $p.it
        if($areas.Count -and ($areas -notcontains $it.유형갈래)){ continue }
        if($groups.Count -and ($groups -notcontains $it.유형묶음)){ continue }
        if($genres.Count -and -not (@($it.갈래) | Where-Object { $genres -contains $_ })){ continue }
        $h = CountHits $p.text $words
        if($it.유형갈래 -eq '문법' -and $p.ptext){ $h += [math]::Floor((CountHits $p.ptext $words) / 2) }
        if($words.Count -and $h -le 0){ continue }
        [pscustomobject]@{ key=$p.key; score=$h; rank=$p.rank; set=("{0}|{1}|{2}" -f $p.it.exam_id,$p.it.영역,$p.it.지문범위); solo=($p.it.지문범위 -eq '(독립 문항)') }
      }
      $seenSet = @{}
      foreach($cd in ($cands | Sort-Object @{Expression='score';Descending=$true}, @{Expression='rank';Descending=$true})){
        if($picked.Count -ge $max){ break }
        if($picked -contains $cd.key){ continue }
        if(-not $cd.solo){ if($seenSet[$cd.set]){ continue }; $seenSet[$cd.set] = 1 }
        [void]$picked.Add($cd.key)
      }
    }
    # 최근 시험부터 보이도록 정렬
    $sorted = @($picked | Sort-Object @{Expression={ ($_ -split '\|\|')[0] }; Descending=$true}, @{Expression={ [int](($_ -split '\|\|')[2]) }})
    $c | Add-Member -NotePropertyName kichulKeys -NotePropertyValue $sorted -Force
    foreach($x in $sorted){ $used[$x] = 1 }
  }
}
Write-Host "연결한 기출 문항 $($used.Count)개"

# ---------- 4. 기출 자료 묶기 ----------
$itemIndex = @{}; foreach($p in $pool){ $itemIndex[$p.key] = $p.it }
$outItems = [ordered]@{}; $outPass = [ordered]@{}; $figFiles = @{}
foreach($key in ($used.Keys | Sort-Object)){
  $it = $itemIndex[$key]
  if(-not $it){ Write-Warning "문항 없음: $key"; continue }
  $pkey = $null
  if($it.지문범위 -ne '(독립 문항)'){
    $pkey = "{0}||{1}||{2}" -f $it.exam_id, $it.영역, $it.지문범위
    if(-not $outPass.Contains($pkey)){
      $pf = Prop $FIGS.p $pkey
      if($pf){ foreach($ff in ($pf.f -split ' ')){ $figFiles[$ff] = 1 } }
      $outPass[$pkey] = [ordered]@{ text = (Prop $PASSAGES $pkey); fig = $(if($pf){ $pf.f } else { $null }) }
    }
  }
  $fi = Prop $FIGS.i $key
  if($fi){ foreach($ff in ($fi.f -split ' ')){ $figFiles[$ff] = 1 } }
  $outItems[$key] = [ordered]@{
    exam = $it.명칭; no = $it.문항번호; area = $it.영역; range = $it.지문범위; pkey = $pkey
    stem = $it.발문; bogi = $it.보기; choices = (Arr (Prop $CHOICES $key)); answer = $it.정답; score = $it.배점
    group = $it.유형묶음; fig = $(if($fi){ [ordered]@{ f = $fi.f; m = $fi.m } } else { $null })
    explain = (Prop $EXPLAIN $key)
  }
}

# ---------- 5. 내보내기 ----------
$book = foreach($ch in $chapters){
  [ordered]@{
    part = $ch.part; chapter = $ch.chapter; id = $ch.id; intro = $ch.intro
    concepts = @(foreach($c in $ch.concepts){
      [ordered]@{ id=$c.id; title=$c.title; level=$c.level; summary=$c.summary; body=(Arr $c.body); examples=(Arr $c.examples); traps=(Arr $c.traps); kichul=(Arr $c.kichulKeys) }
    })
  }
}
$built = (Get-Date).ToString('yyyy-MM-dd')
New-Item -ItemType Directory -Force "$Root\docs\fig", "$Root\docs\fonts", "$Root\book" | Out-Null
WriteText "$Root\docs\data.js" ("window.BOOK = " + (ToJson @($book)) + ";`nwindow.KICHUL = " + (ToJson $outItems) + ";`nwindow.PASSAGES = " + (ToJson $outPass) + ";`nwindow.BUILT = `"$built`";`n")
WriteText "$Root\book\book.json" (ToJson ([ordered]@{ built=$built; chapters=@($book); items=$outItems; passages=$outPass }))
foreach($f in $figFiles.Keys){ Copy-Item "$Bank\$f" "$Root\docs\$f" -Force }
Copy-Item "$Bank\fonts\*.woff" "$Root\docs\fonts\" -Force
Write-Host "docs\data.js, book\book.json 저장 / 그림 $($figFiles.Count)개 복사"

# ---------- 6. 한글(HWPX) 책 ----------
& "$PSScriptRoot\make_hwpx.ps1"
