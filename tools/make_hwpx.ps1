# book/book.json(빌드 결과) → 한글 책(HWPX)
# 사용법: make_hwpx.ps1 [-Lite] [-Out <파일>] [-PageMap <쪽 번호 json>]
#   -Lite     가벼운판(기출은 출처·발문·정답만)
#   -PageMap  pagenums.ps1이 알아낸 쪽 번호. 없으면 차례에 '000'을 넣고, 같은 이름의 .paras.json에 문단 위치를 적음
param([string]$In, [string]$Out, [switch]$NoPictures, [switch]$Lite, [string]$PageMap)
$SITE = 'https://korean-exam-teacher.github.io/suneung-concept/'
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
if(-not $In){ $In = "$Root\book\book.json" }
if(-not $Out){ $Out = "$Root\book\수능국어_개념서.hwpx" }
$U8 = New-Object Text.UTF8Encoding $false
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$B = [IO.File]::ReadAllText($In, [Text.Encoding]::UTF8) | ConvertFrom-Json
function Prop($o, $k){ $p = $o.PSObject.Properties[$k]; if($p){ $p.Value } else { $null } }
$CIRCLED = @('', '①', '②', '③', '④', '⑤')
$LEVELS = @('기본', '심화', '발전', '도약')
$LVDESC = @('용어와 뼈대를 세우는 첫 개념', '수능에 해마다 나오는 규칙과 개념', '여러 개념을 엮어 자료와 지문에 적용', '고난도·통합·3점 문항 대비')
function LvOf($c){ $i = [array]::IndexOf($LEVELS, [string]$c.level); if($i -lt 0){ 0 } else { $i } }
$PAGES = @{}
if($PageMap -and (Test-Path $PageMap)){ $pm = [IO.File]::ReadAllText($PageMap, [Text.Encoding]::UTF8) | ConvertFrom-Json; foreach($p in $pm.PSObject.Properties){ $PAGES[$p.Name] = [int]$p.Value } }

# ---------- 쪽: A4, 좁은 여백, 본문 2단 ----------
$PW = 59528; $PH = 84186
$ML = 4819; $MR = 4819; $MT = 5386; $MB = 4535; $MH = 2835; $MF = 2268
$TW = $PW - $ML - $MR            # 본문 전체 폭
$GAP = 1700                       # 단 사이
$CW = [int](($TW - $GAP) / 2)     # 한 단 폭

# ---------- 색 ----------
$NAVY = '#0E5C55'; $ACC = '#0E6B63'; $BAND = '#0C3B37'; $INK = '#1D1D1F'; $INK2 = '#3A3A3C'; $INK3 = '#6E6E73'; $INK4 = '#A1A1A6'
$LINE = '#DADDE2'; $TINT = '#F4F5F7'
$LV = @('#0071E3', '#248A3D', '#C25E00', '#8944AB')
$LVT = @('#E8F2FD', '#E9F6EC', '#FDF0E3', '#F4ECF8')

# ---------- 글자 모양 (font 0 함초롬돋움, 1 함초롬바탕, 2 맑은 고딕, 3·4 맑은 고딕 굵게) ----------
$charDefs = [ordered]@{
  # 본문은 함초롬바탕, 제목·표·딸린 글은 Noto Sans KR. 크기는 제목 11.5 / 본문 9.2 / 표 8 / 작은 글 7.8pt
  body   = @{ h=950;  f=1; c=$INK }
  bodyB  = @{ h=950;  f=1; c=$INK; b=1 }
  bodyU  = @{ h=950;  f=1; c=$INK; u=1 }
  small  = @{ h=780;  f=2; c=$INK3 }
  smallB = @{ h=780;  f=3; c=$INK2 }
  cell   = @{ h=850;  f=2; c=$INK }
  cellB  = @{ h=850;  f=3; c=$INK }
  cellU  = @{ h=850;  f=2; c=$INK; u=1 }
  head   = @{ h=740;  f=3; c=$INK3 }
  exE    = @{ h=900;  f=1; c=$INK; b=1 }
  exN    = @{ h=830;  f=2; c=$INK2 }
  exNB   = @{ h=830;  f=3; c=$INK }
  label  = @{ h=900;  f=3; c=$ACC }
  h3     = @{ h=950;  f=3; c=$ACC }
  conT   = @{ h=1500; f=4; c=$INK }
  labelM = @{ h=700;  f=3; c=$ACC }
  lv1    = @{ h=740;  f=3; c=$LV[0] }
  lv2    = @{ h=740;  f=3; c=$LV[1] }
  lv3    = @{ h=740;  f=3; c=$LV[2] }
  lv4    = @{ h=740;  f=3; c=$LV[3] }
  trapM  = @{ h=900;  f=3; c=$ACC }
  sum    = @{ h=930;  f=3; c=$INK2 }
  sumB   = @{ h=930;  f=4; c=$INK }
  chNo   = @{ h=820;  f=3; c='#7FC4BA' }
  chT    = @{ h=1900; f=4; c='#FFFFFF' }
  chIn   = @{ h=820;  f=2; c='#CFE3E0' }
  chInB  = @{ h=800;  f=3; c='#FFFFFF' }
  idx    = @{ h=800;  f=2; c=$INK }
  idxPg  = @{ h=780;  f=3; c=$INK3 }
  tocNo  = @{ h=1000; f=2; c=$INK4 }
  tocBig = @{ h=2400; f=4; c=$ACC }
  tocMeta= @{ h=760;  f=2; c=$INK3 }
  tiny   = @{ h=200;  f=2; c=$INK }
  partNo = @{ h=9000; f=4; c='#E3E6EC' }
  partK  = @{ h=1100; f=3; c=$INK3 }
  partT  = @{ h=3600; f=4; c=$NAVY }
  partS  = @{ h=1050; f=2; c=$INK2 }
  cover  = @{ h=6600; f=0; c=$NAVY; b=1 }
  coverK = @{ h=1150; f=3; c=$LV[0] }
  coverS = @{ h=1350; f=2; c=$INK3 }
  coverW = @{ h=1000; f=3; c='#FFFFFF' }
  coverF = @{ h=760;  f=2; c=$INK4 }
  secT   = @{ h=1700; f=4; c=$INK }
  tocP   = @{ h=1150; f=4; c=$ACC }
  tocPN  = @{ h=1400; f=4; c=$INK }
  tocCh  = @{ h=1000; f=3; c=$INK }
  tocC   = @{ h=800;  f=2; c=$INK2 }
  tocPg  = @{ h=800;  f=2; c=$INK3 }
  tocPgB = @{ h=1000; f=3; c=$INK }
  hdr    = @{ h=720;  f=2; c=$INK4 }
  hdrB   = @{ h=720;  f=3; c=$NAVY }
  q      = @{ h=880;  f=1; c=$INK }
  qB     = @{ h=880;  f=1; c=$INK; b=1 }
  qU     = @{ h=880;  f=1; c=$INK; u=1 }
  qUB    = @{ h=880;  f=1; c=$INK; u=1; b=1 }
  src    = @{ h=780;  f=3; c=$NAVY }
  ans    = @{ h=820;  f=3; c=$NAVY }
}
$CHR = @{}; $i = 0; foreach($k in $charDefs.Keys){ $CHR[$k] = $i; $i++ }
$BOLD = @{ body='bodyB'; cell='cellB'; q='qB'; qU='qUB'; small='smallB'; exN='exNB'; sum='sumB'; chIn='chInB' }
$UND  = @{ body='bodyU'; cell='cellU'; q='qU'; qB='qUB' }
function CharPrXml($id, $d){
  $five = 'hangul="{0}" latin="{0}" hanja="{0}" japanese="{0}" other="{0}" symbol="{0}" user="{0}"'
  $x = "<hh:charPr id=`"$id`" height=`"$($d.h)`" textColor=`"$($d.c)`" shadeColor=`"none`" useFontSpace=`"0`" useKerning=`"0`" symMark=`"NONE`" borderFillIDRef=`"2`">"
  $sp = $(if($d.h -ge 1200){ -3 } else { -1 })
  $x += "<hh:fontRef $($five -f $d.f)/><hh:ratio $($five -f 100)/><hh:spacing $($five -f $sp)/><hh:relSz $($five -f 100)/><hh:offset $($five -f 0)/>"
  if($d.b -or $d.f -ge 3){ $x += '<hh:bold/>' }   # 글꼴 3·4는 맑은 고딕 굵게
  $x += $(if($d.u){ '<hh:underline type="BOTTOM" shape="SOLID" color="#000000"/>' } else { '<hh:underline type="NONE" shape="SOLID" color="#000000"/>' })
  $x + '<hh:strikeout shape="NONE" color="#000000"/><hh:outline type="NONE"/><hh:shadow type="NONE" color="#C0C0C0" offsetX="10" offsetY="10"/></hh:charPr>'
}

# ---------- 테두리·배경 ----------
$bfList = New-Object System.Collections.ArrayList
$BF = @{}
function AddBF($name, $sides, $fill){
  # $sides: @{ left=@('SOLID','0.12 mm','#..'); ... } 빠진 쪽은 NONE
  $id = $bfList.Count + 1
  $x = "<hh:borderFill id=`"$id`" threeD=`"0`" shadow=`"0`" centerLine=`"NONE`" breakCellSeparateLine=`"0`"><hh:slash type=`"NONE`" Crooked=`"0`" isCounter=`"0`"/><hh:backSlash type=`"NONE`" Crooked=`"0`" isCounter=`"0`"/>"
  foreach($s in 'left','right','top','bottom'){
    $v = $(if($sides -and $sides[$s]){ $sides[$s] } else { @('NONE', '0.1 mm', '#000000') })
    $x += "<hh:${s}Border type=`"$($v[0])`" width=`"$($v[1])`" color=`"$($v[2])`"/>"
  }
  $x += '<hh:diagonal type="SOLID" width="0.1 mm" color="#000000"/>'
  if($fill){ $x += "<hc:fillBrush><hc:winBrush faceColor=`"$fill`" hatchColor=`"#999999`" alpha=`"0`"/></hc:fillBrush>" }
  [void]$bfList.Add($x + '</hh:borderFill>')
  $BF[$name] = $id
}
$hair = @('SOLID', '0.12 mm', $LINE)
AddBF 'page' $null $null
AddBF 'none' $null $null
AddBF 'sum' $null $TINT                                   # 바탕색은 이 연회색 하나만 씀
AddBF 'cell' @{ bottom=$hair } $null
AddBF 'cellHead' @{ bottom=@('SOLID', '0.3 mm', $INK) } $null
AddBF 'box' $null $TINT
AddBF 'conRule' @{ top=@('SOLID', '0.3 mm', $INK) } $null   # 개념과 개념 사이의 굵은 선
AddBF 'navy' $null $BAND
AddBF 'conLine' @{ bottom=@('SOLID', '0.4 mm', $ACC) } $null
AddBF 'hdr' @{ bottom=$hair } $null
AddBF 'bogi' @{ left=@('SOLID', '0.12 mm', $INK3); right=@('SOLID', '0.12 mm', $INK3); top=@('SOLID', '0.12 mm', $INK3); bottom=@('SOLID', '0.12 mm', $INK3) } $null
AddBF 'rule' @{ top=@('SOLID', '0.4 mm', $NAVY) } $null
$blk = @('SOLID', '0.12 mm', '#000000')
AddBF 'bogiCell' @{ left=$blk; right=$blk; top=$blk; bottom=$blk } $null
AddBF 'tocRow' @{ bottom=@('SOLID', '0.1 mm', '#E8EAEE') } $null
for($k = 0; $k -lt 4; $k++){
  AddBF "lvFill$k" $null $LV[$k]
  AddBF "lvTint$k" $null $LVT[$k]
}

# ---------- 문단 모양 ----------
$paraDefs = [ordered]@{
  body    = @{ a='JUSTIFY'; l=172; next=420 }
  center  = @{ a='CENTER';  l=150 }
  right   = @{ a='RIGHT';   l=140 }
  list    = @{ a='JUSTIFY'; l=168; left=800; indent=-800; next=90 }
  h3      = @{ a='LEFT';    l=150; prev=900; next=260; keep=1 }
  label   = @{ a='LEFT';    l=140; prev=1000; next=300; keep=1 }
  conTag  = @{ a='LEFT';    l=130; prev=600; next=100; keep=1 }
  conT    = @{ a='LEFT';    l=125; prev=0; next=0; keep=1 }
  spacer  = @{ a='LEFT';    l=100; prev=0; next=0 }
  sum     = @{ a='JUSTIFY'; l=165; prev=200; next=700; border=$BF.sum }
  box     = @{ a='JUSTIFY'; l=165; prev=500; next=600; border=$BF.box }
  trap    = @{ a='JUSTIFY'; l=165; left=800; indent=-800; next=100 }
  cell    = @{ a='LEFT';    l=135 }
  cellC   = @{ a='CENTER';  l=135 }
  cellR   = @{ a='RIGHT';   l=135 }
  q       = @{ a='JUSTIFY'; l=160; next=120 }
  qHang   = @{ a='JUSTIFY'; l=160; left=1000; indent=-1000; prev=900; next=240; keep=1 }
  bogi    = @{ a='JUSTIFY'; l=158; left=500; right=500; prev=60; next=60; border=$BF.bogi }
  bogiC   = @{ a='CENTER';  l=158; left=500; right=500; prev=60; next=0; border=$BF.bogi }
  choice  = @{ a='JUSTIFY'; l=158; left=1800; indent=-800; next=60 }
  passage = @{ a='JUSTIFY'; l=165; indent=900 }
  src     = @{ a='LEFT';    l=150; prev=1100; next=260; keep=1 }
  navy    = @{ a='LEFT';    l=150; left=900; right=900; border=$BF.navy }
  hdr     = @{ a='RIGHT';   l=130; border=$BF.hdr }
  secT    = @{ a='LEFT';    l=130; prev=0; next=500 }
  partNo  = @{ a='LEFT';    l=100 }
  partT   = @{ a='LEFT';    l=120; next=300 }
  coverT  = @{ a='LEFT';    l=110; next=200 }
  gap     = @{ a='LEFT';    l=100 }
  bogiL   = @{ a='CENTER';  l=160; next=120 }
  bogiT   = @{ a='JUSTIFY'; l=165 }
  bogiWrap= @{ a='LEFT';    l=100; left=200 }
  bandP   = @{ a='JUSTIFY'; l=160; next=60 }
  bandT   = @{ a='LEFT';    l=120; prev=80; next=320 }
}
$PA = @{}; $i = 0; foreach($k in $paraDefs.Keys){ $PA[$k] = $i; $i++ }
function ParaPrXml($id, $d){
  $m = "<hh:margin><hc:intent value=`"$([int]$d.indent)`" unit=`"HWPUNIT`"/><hc:left value=`"$([int]$d.left)`" unit=`"HWPUNIT`"/><hc:right value=`"$([int]$d.right)`" unit=`"HWPUNIT`"/><hc:prev value=`"$([int]$d.prev)`" unit=`"HWPUNIT`"/><hc:next value=`"$([int]$d.next)`" unit=`"HWPUNIT`"/></hh:margin><hh:lineSpacing type=`"PERCENT`" value=`"$($d.l)`" unit=`"HWPUNIT`"/>"
  $pbf = $(if($d.border){ $d.border } else { 2 })
  $off = $(if($d.border){ 'offsetLeft="340" offsetRight="340" offsetTop="260" offsetBottom="260" connect="1"' } else { 'offsetLeft="0" offsetRight="0" offsetTop="0" offsetBottom="0" connect="0"' })
  if($d.border -eq $BF.conLine){ $off = 'offsetLeft="0" offsetRight="0" offsetTop="0" offsetBottom="260" connect="0"' }
  if($d.border -eq $BF.hdr){ $off = 'offsetLeft="0" offsetRight="0" offsetTop="0" offsetBottom="200" connect="0"' }
  if($d.border -eq $BF.rule){ $off = 'offsetLeft="0" offsetRight="0" offsetTop="200" offsetBottom="0" connect="0"' }
  if($d.border -eq $BF.navy){ $off = 'offsetLeft="0" offsetRight="0" offsetTop="420" offsetBottom="420" connect="1"' }
  "<hh:paraPr id=`"$id`" tabPrIDRef=`"0`" condense=`"0`" fontLineHeight=`"0`" snapToGrid=`"0`" suppressLineNumbers=`"0`" checked=`"0`" textDir=`"LTR`"><hh:align horizontal=`"$($d.a)`" vertical=`"BASELINE`"/><hh:heading type=`"NONE`" idRef=`"0`" level=`"0`"/><hh:breakSetting breakLatinWord=`"KEEP_WORD`" breakNonLatinWord=`"KEEP_WORD`" widowOrphan=`"1`" keepWithNext=`"$([int]$d.keep)`" keepLines=`"0`" pageBreakBefore=`"0`" lineWrap=`"BREAK`"/><hh:autoSpacing eAsianEng=`"0`" eAsianNum=`"0`"/><hp:switch><hp:case hp:required-namespace=`"http://www.hancom.co.kr/hwpml/2016/HwpUnitChar`">$m</hp:case><hp:default>$m</hp:default></hp:switch><hh:border borderFillIDRef=`"$pbf`" $off ignoreMargin=`"0`"/></hh:paraPr>"
}

# ---------- 글자 다루기 ----------
function X($s){ ([string]$s).Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;') }
function Rn($text, $style){ "<hp:run charPrIDRef=`"$($CHR[$style])`"><hp:t>$(X $text)</hp:t></hp:run>" }
# **굵게**, U+FDD0…FDD1 밑줄, U+FDD2…FDD3 상자(밑줄로 대신)
function Runs($text, $base){
  $s = [string]$text
  $buf = New-Object Text.StringBuilder
  foreach($p in [regex]::Split($s, '(\*\*.+?\*\*)')){
    if(-not $p){ continue }
    $style = $base; $t = $p
    if($p.StartsWith('**') -and $p.EndsWith('**') -and $p.Length -gt 4){ $t = $p.Substring(2, $p.Length - 4); if($BOLD[$base]){ $style = $BOLD[$base] } }
    foreach($g in [regex]::Split($t, '([﷐﷒][^﷑﷓]*[﷑﷓]?)')){
      if(-not $g){ continue }
      $st = $style
      if($g[0] -eq [char]0xFDD0 -or $g[0] -eq [char]0xFDD2){ if($UND[$style]){ $st = $UND[$style] } }
      $g = $g -replace '[﷐-﷓]', ''
      if($g){ [void]$buf.Append((Rn $g $st)) }
    }
  }
  if($buf.Length -eq 0){ [void]$buf.Append("<hp:run charPrIDRef=`"$($CHR[$base])`"/>") }
  $buf.ToString()
}
$sb = New-Object Text.StringBuilder
$script:paraNo = 0                 # 맨 위 문단 번호(차례 쪽 번호 찾기용)
$ANCHOR = [ordered]@{}             # 차례 항목 → 문단 번호
function Emit($xml, $para, [switch]$Break, [switch]$ColBreak){
  $pb = $(if($Break){ '1' } else { '0' }); $cb = $(if($ColBreak){ '1' } else { '0' })
  [void]$sb.Append("<hp:p id=`"0`" paraPrIDRef=`"$($PA[$para])`" styleIDRef=`"0`" pageBreak=`"$pb`" columnBreak=`"$cb`" merged=`"0`">$xml</hp:p>")
  $script:paraNo++
}
function P($text, $para = 'body', $char = 'body', [switch]$Break){
  $first = $true
  foreach($ln2 in ([string]$text -split "`n")){
    Emit (Runs $ln2 $char) $para -Break:($Break -and $first)
    $first = $false
  }
}
function Mark($key, $needle){ $ANCHOR[$key] = $needle }   # 쪽 번호를 찾을 때 그 쪽 글에서 찾을 낱말
function PageOf($key){ if($PAGES.ContainsKey($key)){ [string]$PAGES[$key] } else { '000' } }

# 단 바꾸기·머리말은 문단 안의 조종 문자로 넣음
function ColCtrl($n){ "<hp:ctrl><hp:colPr id=`"`" type=`"NEWSPAPER`" layout=`"LEFT`" colCount=`"$n`" sameSz=`"1`" sameGap=`"$GAP`"/></hp:ctrl>" }
$script:hdrId = 0
function HeaderCtrl($left, $right){
  $script:hdrId++
  $inner = "<hp:p id=`"0`" paraPrIDRef=`"$($PA.hdr)`" styleIDRef=`"0`" pageBreak=`"0`" columnBreak=`"0`" merged=`"0`">$(Rn $left 'hdrB')$(Rn ('    ' + $right) 'hdr')</hp:p>"
  "<hp:ctrl><hp:header id=`"$($script:hdrId)`" applyPageType=`"BOTH`"><hp:subList id=`"`" textDirection=`"HORIZONTAL`" lineWrap=`"BREAK`" vertAlign=`"BOTTOM`" linkListIDRef=`"0`" linkListNextIDRef=`"0`" textWidth=`"$TW`" textHeight=`"$MH`" hasTextRef=`"0`" hasNumRef=`"0`">$inner</hp:subList></hp:header></hp:ctrl>"
}
function CtrlPara($ctrls, $para = 'gap', [switch]$Break){ Emit "<hp:run charPrIDRef=`"$($CHR.small)`">$ctrls</hp:run>" $para -Break:$Break }

# ---------- 표 ----------
$script:objId = 1000
function TableXml($rows, $widths, $opt){
  # $rows: 칸 배열의 배열. 칸 = 글자 또는 @{ t=글자; c=글자모양; p=문단모양; bf=테두리 }
  # 줄이 하나뿐이면 PowerShell이 바깥 배열을 벗겨 버리므로 다시 감쌈
  $rows = @($rows); if($rows.Count -and -not ($rows[0] -is [array])){ $rows = ,$rows }
  $nr = $rows.Count; $nc = $widths.Count; $W = ($widths | Measure-Object -Sum).Sum
  $script:objId++
  $x = "<hp:tbl id=`"$script:objId`" zOrder=`"0`" numberingType=`"TABLE`" textWrap=`"TOP_AND_BOTTOM`" textFlow=`"BOTH_SIDES`" lock=`"0`" dropcapstyle=`"None`" pageBreak=`"CELL`" repeatHeader=`"$([int]$opt.head)`" rowCnt=`"$nr`" colCnt=`"$nc`" cellSpacing=`"0`" borderFillIDRef=`"$($BF.none)`" noAdjust=`"0`"><hp:sz width=`"$W`" widthRelTo=`"ABSOLUTE`" height=`"$($nr * 1200)`" heightRelTo=`"ABSOLUTE`" protect=`"0`"/><hp:pos treatAsChar=`"0`" affectLSpacing=`"0`" flowWithText=`"1`" allowOverlap=`"0`" holdAnchorAndSO=`"0`" vertRelTo=`"PARA`" horzRelTo=`"COLUMN`" vertAlign=`"TOP`" horzAlign=`"LEFT`" vertOffset=`"0`" horzOffset=`"0`"/><hp:outMargin left=`"0`" right=`"0`" top=`"120`" bottom=`"$(if($opt.after){$opt.after}else{420})`"/><hp:inMargin left=`"340`" right=`"340`" top=`"150`" bottom=`"150`"/>"
  for($r = 0; $r -lt $nr; $r++){
    $isHead = ($opt.head -and $r -eq 0)
    $x += '<hp:tr>'
    for($c = 0; $c -lt $nc; $c++){
      $cv = @($rows[$r])[$c]
      if($cv -is [hashtable]){ $txt = $cv.t; $cs = $cv.c; $ps = $cv.p; $cbf = $cv.bf } else { $txt = [string]$cv; $cs = $null; $ps = $null; $cbf = $null }
      if(-not $cs){ $cs = $(if($isHead){ 'head' } else { $(if($opt.cellChar){ $opt.cellChar } else { 'cell' }) }) }
      if(-not $ps){ $ps = 'cell' }
      if(-not $cbf){ $cbf = $(if($isHead){ $BF.cellHead } elseif($opt.rowBF){ $opt.rowBF } else { $BF.cell }) }
      $cm = $(if($opt.pad -ne $null){ $opt.pad } elseif($opt.tight){ 100 } else { 340 })
      $cmV = $(if($opt.pad -ne $null){ $opt.pad } elseif($opt.tight){ 110 } else { 240 })
      $x += "<hp:tc name=`"`" header=`"$(if($isHead){1}else{0})`" hasMargin=`"1`" protect=`"0`" editable=`"0`" dirty=`"0`" borderFillIDRef=`"$cbf`"><hp:subList id=`"`" textDirection=`"HORIZONTAL`" lineWrap=`"BREAK`" vertAlign=`"$(if($opt.vtop){'TOP'}else{'CENTER'})`" linkListIDRef=`"0`" linkListNextIDRef=`"0`" textWidth=`"0`" textHeight=`"0`" hasTextRef=`"0`" hasNumRef=`"0`">"
      if($cv -is [hashtable] -and $cv.lines){
        # 한 칸에 모양이 다른 여러 문단: lines = @(@{ t; c; p }, ...)
        foreach($ln in $cv.lines){
          $lp = $(if($ln.p){ $ln.p } else { 'cell' })
          foreach($ll in (([string]$ln.t) -split "`n")){ $x += "<hp:p id=`"0`" paraPrIDRef=`"$($PA[$lp])`" styleIDRef=`"0`" pageBreak=`"0`" columnBreak=`"0`" merged=`"0`">$(Runs $ll $ln.c)</hp:p>" }
        }
      } else {
        foreach($ln in (([string]$txt) -split "`n")){ $x += "<hp:p id=`"0`" paraPrIDRef=`"$($PA[$ps])`" styleIDRef=`"0`" pageBreak=`"0`" columnBreak=`"0`" merged=`"0`">$(Runs $ln $cs)</hp:p>" }
      }
      $x += "</hp:subList><hp:cellAddr colAddr=`"$c`" rowAddr=`"$r`"/><hp:cellSpan colSpan=`"1`" rowSpan=`"1`"/><hp:cellSz width=`"$($widths[$c])`" height=`"$(if($opt.h){$opt.h}else{900})`"/><hp:cellMargin left=`"$cm`" right=`"$cm`" top=`"$cmV`" bottom=`"$cmV`"/></hp:tc>"
    }
    $x += '</hp:tr>'
  }
  $x + '</hp:tbl>'
}
function Table($rows, $widths, $opt = @{}, $para = 'body'){
  Emit "<hp:run charPrIDRef=`"$($CHR.body)`">$(TableXml $rows $widths $opt)<hp:t/></hp:run>" $para
}
function AutoWidths($all, $W){
  $nc = @($all[0]).Count
  $len = @(for($c = 0; $c -lt $nc; $c++){ [math]::Min(40, ($all | ForEach-Object { ([string]@($_)[$c]).Length } | Measure-Object -Maximum).Maximum) + 3 })
  $sum = ($len | Measure-Object -Sum).Sum
  $ws = @($len | ForEach-Object { [math]::Max([int]($W * 0.13), [int]($W * $_ / $sum)) })
  $sc = $W / ($ws | Measure-Object -Sum).Sum
  @($ws | ForEach-Object { [int]($_ * $sc) })
}
function ContentTable($head, $rows){
  $all = @(); if($head){ $all += ,@($head) }; foreach($r in @($rows)){ $all += ,@($r) }
  $first = $true
  $rowsX = foreach($r in $all){
    if($first -and $head){ $first = $false; ,@($r); continue }
    $first = $false
    ,@(for($c = 0; $c -lt @($r).Count; $c++){ if($c -eq 0){ @{ t = @($r)[$c]; c = 'cellB' } } else { [string]@($r)[$c] } })
  }
  Table @($rowsX) (AutoWidths $all $TW) @{ head = [bool]$head }
}

# ---------- 그림 ----------
$images = [ordered]@{}
function Picture($rel, $maxW){
  if($NoPictures){ P '(그림 생략)' 'body' 'small'; return }
  $path = Join-Path "$Root\docs" $rel
  if(-not (Test-Path $path)){ P '(그림을 찾지 못했습니다)' 'body' 'small'; return }
  $binId = 'image' + ($images.Count + 1)
  $images[$binId] = $path
  $img = [System.Drawing.Image]::FromFile($path)
  $imgW = $img.Width; $imgH = $img.Height; $img.Dispose()   # 쪽 크기 변수와 이름이 겹치지 않게 함
  $ow = $imgW * 75; $oh = $imgH * 75
  $w = [int][math]::Min($maxW, $ow * 0.5)
  $h = [int]($oh * $w / $ow)
  # 단 높이보다 긴 그림은 한글이 쪽을 나누지 못해 멈추므로 줄임
  $maxH = [int](($PH - $MT - $MB - $MH - $MF) * 0.8)
  if($h -gt $maxH){ $w = [int]($w * $maxH / $h); $h = $maxH }
  $script:objId++
  $sx = '{0:0.######}' -f ($w / $ow); $sy = '{0:0.######}' -f ($h / $oh)
  $x = "<hp:pic id=`"$script:objId`" zOrder=`"0`" numberingType=`"PICTURE`" textWrap=`"TOP_AND_BOTTOM`" textFlow=`"BOTH_SIDES`" lock=`"0`" dropcapstyle=`"None`" href=`"`" groupLevel=`"0`" instid=`"$($script:objId + 500000)`" reverse=`"0`"><hp:offset x=`"0`" y=`"0`"/><hp:orgSz width=`"$ow`" height=`"$oh`"/><hp:curSz width=`"$w`" height=`"$h`"/><hp:flip horizontal=`"0`" vertical=`"0`"/><hp:rotationInfo angle=`"0`" centerX=`"$([int]($w/2))`" centerY=`"$([int]($h/2))`" rotateimage=`"1`"/><hp:renderingInfo><hc:transMatrix e1=`"1`" e2=`"0`" e3=`"0`" e4=`"0`" e5=`"1`" e6=`"0`"/><hc:scaMatrix e1=`"$sx`" e2=`"0`" e3=`"0`" e4=`"0`" e5=`"$sy`" e6=`"0`"/><hc:rotMatrix e1=`"1`" e2=`"0`" e3=`"0`" e4=`"0`" e5=`"1`" e6=`"0`"/></hp:renderingInfo><hp:imgRect><hc:pt0 x=`"0`" y=`"0`"/><hc:pt1 x=`"$ow`" y=`"0`"/><hc:pt2 x=`"$ow`" y=`"$oh`"/><hc:pt3 x=`"0`" y=`"$oh`"/></hp:imgRect><hp:imgClip left=`"0`" right=`"$ow`" top=`"0`" bottom=`"$oh`"/><hp:inMargin left=`"0`" right=`"0`" top=`"0`" bottom=`"0`"/><hp:imgDim dimwidth=`"$ow`" dimheight=`"$oh`"/><hc:img binaryItemIDRef=`"$binId`" bright=`"0`" contrast=`"0`" effect=`"REAL_PIC`" alpha=`"0`"/><hp:effects/><hp:sz width=`"$w`" widthRelTo=`"ABSOLUTE`" height=`"$h`" heightRelTo=`"ABSOLUTE`" protect=`"0`"/><hp:pos treatAsChar=`"1`" affectLSpacing=`"0`" flowWithText=`"1`" allowOverlap=`"0`" holdAnchorAndSO=`"0`" vertRelTo=`"PARA`" horzRelTo=`"COLUMN`" vertAlign=`"TOP`" horzAlign=`"LEFT`" vertOffset=`"0`" horzOffset=`"0`"/><hp:outMargin left=`"0`" right=`"0`" top=`"0`" bottom=`"0`"/><hp:shapeComment>문제지 그림</hp:shapeComment></hp:pic>"
  Emit "<hp:run charPrIDRef=`"$($CHR.body)`">$x<hp:t/></hp:run>" 'center'
}

# ---------- 기출 ----------
function ExamName($it){ ($it.exam -replace '학년도 ', ' ' -replace '대학수학능력시험', '수능') + " $($it.no)번" }
# 수능 시험지 모양: 굵은 번호 + 발문 [3점] / <보기>는 테두리 상자 맨 위 가운데에 '< 보 기 >' / 선택지는 ①~⑤ 한 줄씩
function ItemXml($key, $num){
  $it = Prop $B.items $key
  $stem = ([string]$it.stem) -replace '^\s*\d+\.\s*', ''
  $score = $(if($it.score -eq 3 -and $stem -notmatch '3점'){ ' [3점]' } else { '' })
  Emit ((Rn "$num. " 'qB') + (Runs ($stem + $score) 'q') + (Rn "   $(ExamName $it)" 'small')) 'qHang'
  if($it.fig -and $it.fig.m -eq 'bogi'){
    # 원본 문제지에서 오린 <보기> 그림(상자까지 들어 있음)을 그대로 씀
    foreach($ff in ($it.fig.f -split ' ')){ Picture $ff ($CW - 400) }
  } elseif($it.bogi){
    $m = [regex]::Match([string]$it.bogi, '^<\s*([^<>]{1,12}?)\s*>\s*')
    $label = $(if($m.Success){ ($m.Groups[1].Value -replace '\s', '') } else { '보기' })
    $label = (($label.ToCharArray()) -join ' ')               # '보기' → '보 기'
    $bodyT = $(if($m.Success){ ([string]$it.bogi).Substring($m.Length) } else { [string]$it.bogi })
    $cell = @{ lines = @(@{ t = "< $label >"; c = 'q'; p = 'bogiL' }, @{ t = $bodyT; c = 'q'; p = 'bogiT' }); bf = $BF.bogiCell }
    Table @(,@($cell)) @($CW - 200) @{ pad = 420; after = 300 } 'bogiWrap'
  }
  if($it.fig -and $it.fig.m -eq 'ch'){ foreach($ff in ($it.fig.f -split ' ')){ Picture $ff ($CW - 400) } }
  else { $ch = @($it.choices); for($n = 1; $n -le 5; $n++){ P ("$($CIRCLED[$n]) " + $(if($ch.Count -ge $n){ $ch[$n - 1] } else { '' })) 'choice' 'q' } }
}

# ---------- 반복 조각 ----------
$allConcepts = @($B.chapters | ForEach-Object { $_.concepts })
$partNames = @(); foreach($ch in $B.chapters){ if($partNames -notcontains $ch.part){ $partNames += $ch.part } }
$PARTNOTE = @{ '언어(문법)'='2028 수능 · 화법과 언어'; '문학'='2028 수능 · 문학'; '독서'='2028 수능 · 독서와 작문'; '화법·작문·매체'='2028 수능 · 화법과 언어 · 독서와 작문' }
function SectionTitle($kor, $sub){
  P $kor 'secT' 'secT'
  if($sub){ P $sub 'body' 'small' }
}
function TocRows($items){
  # $items: @{ t; style; key; pgStyle; lv }
  $rows = foreach($e in $items){
    $title = $(if($e.lv -ne $null){ @{ t = $e.t; c = $e.style } } else { @{ t = $e.t; c = $e.style } })
    ,@($title, @{ t = (PageOf $e.key); c = $e.pg; p = 'cellR' })
  }
  Table @($rows) @(($CW - 1500), 1500) @{ rowBF = $BF.tocRow; tight = 1; h = 600 }
}

# ================= 본문 짜기 =================
$secPr = "<hp:secPr id=`"`" textDirection=`"HORIZONTAL`" spaceColumns=`"$GAP`" tabStop=`"8000`" tabStopVal=`"4000`" tabStopUnit=`"HWPUNIT`" outlineShapeIDRef=`"1`" memoShapeIDRef=`"0`" textVerticalWidthHead=`"0`" masterPageCnt=`"0`"><hp:grid lineGrid=`"0`" charGrid=`"0`" wonggojiFormat=`"0`"/><hp:startNum pageStartsOn=`"BOTH`" page=`"0`" pic=`"0`" tbl=`"0`" equation=`"0`"/><hp:visibility hideFirstHeader=`"1`" hideFirstFooter=`"1`" hideFirstMasterPage=`"0`" border=`"SHOW_ALL`" fill=`"SHOW_ALL`" hideFirstPageNum=`"1`" hideFirstEmptyLine=`"0`" showLineNumber=`"0`"/><hp:lineNumberShape restartType=`"0`" countBy=`"0`" distance=`"0`" startNumber=`"0`"/><hp:pagePr landscape=`"WIDELY`" width=`"$PW`" height=`"$PH`" gutterType=`"LEFT_ONLY`"><hp:margin header=`"$MH`" footer=`"$MF`" gutter=`"0`" left=`"$ML`" right=`"$MR`" top=`"$MT`" bottom=`"$MB`"/></hp:pagePr><hp:footNotePr><hp:autoNumFormat type=`"DIGIT`" userChar=`"`" prefixChar=`"`" suffixChar=`")`" supscript=`"0`"/><hp:noteLine length=`"-1`" type=`"SOLID`" width=`"0.12 mm`" color=`"#000000`"/><hp:noteSpacing betweenNotes=`"283`" belowLine=`"567`" aboveLine=`"850`"/><hp:numbering type=`"CONTINUOUS`" newNum=`"1`"/><hp:placement place=`"EACH_COLUMN`" beneathText=`"0`"/></hp:footNotePr><hp:endNotePr><hp:autoNumFormat type=`"DIGIT`" userChar=`"`" prefixChar=`"`" suffixChar=`")`" supscript=`"0`"/><hp:noteLine length=`"14692344`" type=`"SOLID`" width=`"0.12 mm`" color=`"#000000`"/><hp:noteSpacing betweenNotes=`"0`" belowLine=`"567`" aboveLine=`"850`"/><hp:numbering type=`"CONTINUOUS`" newNum=`"1`"/><hp:placement place=`"END_OF_DOCUMENT`" beneathText=`"0`"/></hp:endNotePr><hp:pageBorderFill type=`"BOTH`" borderFillIDRef=`"1`" textBorder=`"PAPER`" headerInside=`"0`" footerInside=`"0`" fillArea=`"PAPER`"><hp:offset left=`"1417`" right=`"1417`" top=`"1417`" bottom=`"1417`"/></hp:pageBorderFill><hp:pageBorderFill type=`"EVEN`" borderFillIDRef=`"1`" textBorder=`"PAPER`" headerInside=`"0`" footerInside=`"0`" fillArea=`"PAPER`"><hp:offset left=`"1417`" right=`"1417`" top=`"1417`" bottom=`"1417`"/></hp:pageBorderFill><hp:pageBorderFill type=`"ODD`" borderFillIDRef=`"1`" textBorder=`"PAPER`" headerInside=`"0`" footerInside=`"0`" fillArea=`"PAPER`"><hp:offset left=`"1417`" right=`"1417`" top=`"1417`" bottom=`"1417`"/></hp:pageBorderFill></hp:secPr>"
Emit "<hp:run charPrIDRef=`"$($CHR.body)`">$secPr$(ColCtrl 1)<hp:ctrl><hp:pageNum pos=`"BOTTOM_CENTER`" formatType=`"DIGIT`" sideChar=`"`"/></hp:ctrl></hp:run>" 'gap'

# ----- 표지 -----
for($k = 0; $k -lt 9; $k++){ P '' 'gap' 'body' }
P '수능 국어 개념서' 'coverT' 'coverK'
P 'ᄉᆡ미 기픈 믈' 'coverT' 'cover'
P $(if($Lite){ '개념 · 예문 · 함정 · 평가원 기출 — 가벼운판' } else { '개념 · 예문 · 함정 · 평가원 기출' }) 'coverT' 'coverS'
for($k = 0; $k -lt 5; $k++){ P '' 'gap' 'body' }
# 표지의 네 계단
$cw4 = [int]($TW / 4)
$stair = New-Object System.Collections.ArrayList
[void]$stair.Add(@(for($k = 0; $k -lt 4; $k++){ @{ t = "$($k + 1)  $($LEVELS[$k])"; c = 'coverW'; bf = $BF["lvFill$k"] } }))
[void]$stair.Add(@(for($k = 0; $k -lt 4; $k++){ @{ t = $LVDESC[$k]; c = 'small'; bf = $BF["lvTint$k"] } }))
$stair = $stair.ToArray()
Table $stair @($cw4, $cw4, $cw4, ($TW - 3 * $cw4)) @{ h = 900 }
for($k = 0; $k -lt 10; $k++){ P '' 'gap' 'body' }
P "$($B.built) · 기출 문항·지문·선택지의 저작권은 한국교육과정평가원에 있으며, 이 책은 비영리 학습용입니다." 'coverT' 'coverF'
P $SITE 'coverT' 'coverF'

# ----- 차례: 영역과 장만, 한 쪽에 -----
CtrlPara ((HeaderCtrl 'ᄉᆡ미 기픈 믈' '차례') + (ColCtrl 1)) -Break
Mark 'toc' '차례'
SectionTitle '차례'
$chNoOf = @{}; $k = 0; foreach($ch in $B.chapters){ $k++; $chNoOf[$ch.id] = $k }
$tw4 = @([int]($TW * .07), [int]($TW * .55), [int]($TW * .28)); $tw4 += ($TW - ($tw4 | Measure-Object -Sum).Sum)
foreach($pn in $partNames){
  $pi = [array]::IndexOf($partNames, $pn) + 1
  $rows = @(,@(@{ t = "$pi"; c = 'tocBig' }, @{ t = $pn; c = 'tocP' }, @{ t = $PARTNOTE[$pn]; c = 'tocMeta' }, @{ t = (PageOf "part:$pi"); c = 'tocP'; p = 'cellR' }))
  foreach($ch in @($B.chapters | Where-Object { $_.part -eq $pn })){
    $cs = @($ch.concepts)
    $cnt = @(for($j = 0; $j -lt 4; $j++){ $n = @($cs | Where-Object { (LvOf $_) -eq $j }).Count; if($n){ "$($LEVELS[$j]) $n" } }) -join ' · '
    $rows += ,@(@{ t = ('{0:00}' -f $chNoOf[$ch.id]); c = 'tocNo' }, @{ t = $ch.chapter; c = 'tocCh' }, @{ t = $cnt; c = 'tocMeta' }, @{ t = (PageOf "ch:$($ch.id)"); c = 'tocPgB'; p = 'cellR' })
    if(-not $Lite -and @($cs | Where-Object { @($_.kichul).Count }).Count){ $rows += ,@(@{ t = '' ; c = 'tocC' }, @{ t = '기출 풀어 보기'; c = 'tocC' }, @{ t = ''; c = 'tocMeta' }, @{ t = (PageOf "kx:$($ch.id)"); c = 'tocPg'; p = 'cellR' }) }
  }
  Table $rows $tw4 @{ rowBF = $BF.tocRow; h = 900; tight = 1; after = 900 }
}
if(-not $Lite){ Table @(,@(@{ t = ''; c = 'tocP' }, @{ t = '정답과 해설'; c = 'tocCh' }, @{ t = ''; c = 'tocMeta' }, @{ t = (PageOf 'ans'); c = 'tocPgB'; p = 'cellR' })) $tw4 @{ rowBF = $BF.tocRow; h = 720; tight = 1 } }

# ----- 이 책을 보는 법 + 처음 공부하는 길 -----
CtrlPara ((HeaderCtrl 'ᄉᆡ미 기픈 믈' '이 책을 보는 법') + (ColCtrl 1)) -Break
SectionTitle '이 책을 보는 법'
P '한 개념은 **요약 → 개념 → 예문 → 자주 틀리는 점 → 관련 평가원 기출** 순서로 짜여 있습니다. 개념 제목 위의 색 글자는 학습 단계입니다.' 'body' 'body'
P '처음에는 각 장에서 **기본** 개념만 훑고, 한 바퀴를 돈 뒤 **심화 → 발전 → 도약** 순서로 다시 올라가면 부담이 적습니다.' 'body' 'body'
$lvRows = @(,@('단계', '무엇을 배우나', '개념')) + @(for($k = 0; $k -lt 4; $k++){ ,@(@{ t = $LEVELS[$k]; c = "lv$($k + 1)" }, $LVDESC[$k], "$(@($allConcepts | Where-Object { (LvOf $_) -eq $k }).Count)개") })
Table $lvRows @([int]($TW * .14), [int]($TW * .72), ($TW - [int]($TW * .14) - [int]($TW * .72))) @{ head = 1 }
if($Lite){ P '가벼운판에는 기출의 출처·발문·정답만 실었습니다. 지문·선택지·해설은 웹 사이트에서 바로 풀고 채점할 수 있습니다.' 'body' 'body' }
else { P '관련 기출 문제는 장마다 끝의 **기출 풀어 보기**에 모았고, 정답과 해설은 책 맨 끝에 있습니다.' 'body' 'body' }
P '**2028학년도 수능**부터 국어는 선택 과목 없이 화법과 언어(1~10번), 독서와 작문(11~30번), 문학(31~45번)의 45문항을 모두 풉니다.' 'box' 'body'
Emit ((Rn '■  ' 'labelM') + (Rn "처음 공부하는 길 — 기본 개념 $(@($allConcepts | Where-Object { (LvOf $_) -eq 0 }).Count)개" 'label')) 'label'
# 기본 개념을 좌우 두 줄로 나란히(한 줄 = 왼쪽 개념 | 쪽 || 오른쪽 개념 | 쪽)
$basic = @($allConcepts | Where-Object { (LvOf $_) -eq 0 })
$half = [math]::Ceiling($basic.Count / 2)
$bRows = for($j = 0; $j -lt $half; $j++){
  $a = $basic[$j]; $b2 = $(if($j + $half -lt $basic.Count){ $basic[$j + $half] } else { $null })
  ,@(@{ t = $a.title; c = 'idx' }, @{ t = (PageOf "c:$($a.id)"); c = 'idxPg'; p = 'cellR' }, '',
     @{ t = $(if($b2){ $b2.title } else { '' }); c = 'idx' }, @{ t = $(if($b2){ PageOf "c:$($b2.id)" } else { '' }); c = 'idxPg'; p = 'cellR' })
}
$bw = [int](($TW - 1400) / 2)
Table @($bRows) @(($bw - 1300), 1300, 1400, ($bw - 1300), ($TW - 2 * $bw - 1400 + 1300)) @{ rowBF = $BF.tocRow; h = 600; tight = 1 }

# ----- 영역과 장 -----
$answers = New-Object System.Collections.ArrayList
foreach($pn in $partNames){
  $pi = [array]::IndexOf($partNames, $pn) + 1
  $pchs = @($B.chapters | Where-Object { $_.part -eq $pn })
  # 영역 첫 쪽
  CtrlPara ((HeaderCtrl 'ᄉᆡ미 기픈 믈' $pn) + (ColCtrl 1)) -Break
  Mark "part:$pi" "PART $pi · $($PARTNOTE[$pn])"
  for($k = 0; $k -lt 3; $k++){ P '' 'gap' 'body' }
  P ('{0:00}' -f $pi) 'partNo' 'partNo'
  P "PART $pi · $($PARTNOTE[$pn])" 'partT' 'partK'
  P $pn 'partT' 'partT'
  $pcs = @($pchs | ForEach-Object { $_.concepts })
  P ("장 {0}개 · 개념 {1}개 — 기본 {2} · 심화 {3} · 발전 {4} · 도약 {5}" -f $pchs.Count, $pcs.Count, @($pcs | ? { (LvOf $_) -eq 0 }).Count, @($pcs | ? { (LvOf $_) -eq 1 }).Count, @($pcs | ? { (LvOf $_) -eq 2 }).Count, @($pcs | ? { (LvOf $_) -eq 3 }).Count) 'partT' 'partS'
  $rows = foreach($ch in $pchs){ ,@(@{ t = $ch.chapter; c = 'tocCh' }, @{ t = "개념 $($ch.concepts.Count)"; c = 'tocPg' }, @{ t = (PageOf "ch:$($ch.id)"); c = 'tocPgB'; p = 'cellR' }) }
  Table @($rows) @([int]($TW * .62), [int]($TW * .2), ($TW - [int]($TW * .62) - [int]($TW * .2))) @{ rowBF = $BF.tocRow; h = 900 }

  $cn = 0
  foreach($ch in $pchs){
    $cn++
    $chItems = New-Object System.Collections.ArrayList
    # 장 첫 쪽: 짙은 띠 + 이 장의 개념 목록(단계·쪽 번호) → 바로 본문(1단)
    $chNum = $chNoOf[$ch.id]
    CtrlPara ((HeaderCtrl 'ᄉᆡ미 기픈 믈' "$pn · $($ch.chapter)") + (ColCtrl 1)) -Break
    # 띠(표) 안 글은 한글의 쪽 글 읽기에 잡히지 않으므로 띠 아래 제목 줄로 쪽을 찾음
    Mark "ch:$($ch.id)" "이 장의 개념 · $($ch.chapter)"
    # 띠는 한 칸짜리 표로(문단 테두리로 칠하면 줄 사이에 틈이 보임)
    $bandLines = @(@{ t = ("CHAPTER {0:00}" -f $chNum); c = 'chNo'; p = 'bandP' }, @{ t = $ch.chapter; c = 'chT'; p = 'bandT' })
    if($ch.intro){ $bandLines += @{ t = $ch.intro; c = 'chIn'; p = 'bandP' } }
    Table @(,@(@{ lines = $bandLines; bf = $BF.navy })) @($TW) @{ pad = 1100; after = 900 }
    Emit ((Rn '■  ' 'labelM') + (Rn "이 장의 개념 · $($ch.chapter)" 'label') + (Rn "   $(@($ch.concepts).Count)개" 'small')) 'label'
    $ix = 0
    $iRows = foreach($c in $ch.concepts){ $ix++; $l = LvOf $c; ,@(@{ t = ('{0:00}' -f $ix); c = 'tocNo' }, @{ t = $c.title; c = 'idx' }, @{ t = $LEVELS[$l]; c = "lv$($l + 1)" }, @{ t = (PageOf "c:$($c.id)"); c = 'idxPg'; p = 'cellR' }) }
    Table @($iRows) @([int]($TW * .07), [int]($TW * .73), [int]($TW * .1), ($TW - [int]($TW * .07) - [int]($TW * .73) - [int]($TW * .1))) @{ rowBF = $BF.tocRow; h = 640; tight = 1 }
    $ix = 0
    foreach($c in $ch.concepts){
      $ix++
      $clv = LvOf $c
      Mark "c:$($c.id)" (("{0}   {1} {2:00}" -f $LEVELS[$clv], $ch.chapter, $ix) + $c.title)
      # 개념 머리: 단계·번호 한 줄, 큰 제목, 강조색 가는 선
      P '' 'spacer' 'body'   # 뜬 표 뒤에서는 문단 앞 간격이 무시되므로 빈 줄로 띄움
      Emit ((Rn "$($LEVELS[$clv])" "lv$($clv + 1)") + (Rn ("   {0} {1:00}" -f $ch.chapter, $ix) 'small')) 'conTag'
      Emit (Runs $c.title 'conT') 'conT'
      # 제목 아래 강조색 선: 문단 한쪽 테두리는 한글이 그리지 않아 얇은 한 칸 표로 그림
      Table @(,@(@{ t = ''; c = 'tiny'; bf = $BF.conLine })) @($TW) @{ pad = 0; h = 120; after = 500 }
      P $c.summary 'sum' 'sum'
      foreach($bl in @($c.body)){
        if($null -ne (Prop $bl 'p')){ P $bl.p 'body' 'body' }
        elseif($null -ne (Prop $bl 'h')){ Emit ((Rn '■  ' 'labelM') + (Runs $bl.h 'h3')) 'h3' }
        elseif($null -ne (Prop $bl 'list')){ foreach($li in @($bl.list)){ P ('•  ' + $li) 'list' 'body' } }
        elseif($null -ne (Prop $bl 'table')){ ContentTable (Prop $bl.table 'head') $bl.table.rows }
        elseif($null -ne (Prop $bl 'box')){ if($bl.title){ P ('**' + $bl.title + '**   ' + $bl.box) 'box' 'body' } else { P $bl.box 'box' 'body' } }
      }
      if(@($c.examples).Count){
        Emit ((Rn '■  ' 'labelM') + (Rn '예문' 'label')) 'label'
        $exRows = foreach($e in @($c.examples)){ ,@(@{ t = $e.ex; c = 'exE' }, @{ t = [string]$e.note; c = 'exN' }) }
        Table @($exRows) @([int]($TW * .38), ($TW - [int]($TW * .38))) @{ vtop = 1 }
      }
      if(@($c.traps).Count){
        Emit ((Rn '■  ' 'labelM') + (Rn '자주 틀리는 점' 'label')) 'label'
        foreach($t in @($c.traps)){ Emit ((Rn '!   ' 'trapM') + (Runs $t 'body')) 'trap' }
      }
      $ks = @($c.kichul | Where-Object { Prop $B.items $_ })
      if($ks.Count){
        Emit ((Rn '■  ' 'labelM') + (Rn '관련 평가원 기출' 'label')) 'label'
        if($Lite){
          foreach($k in $ks){
            $it = Prop $B.items $k
            $stem = ([string]$it.stem) -replace '^\s*\d+\.\s*', ''
            Emit ((Rn '•  ' 'small') + (Rn (ExamName $it) 'smallB') + (Rn "  $stem  " 'small') + (Rn "정답 $($CIRCLED[[int]$it.answer])" 'smallB')) 'list'
          }
        } else {
          $refs = foreach($k in $ks){
            if(-not ($chItems -contains $k)){ [void]$chItems.Add($k) }
            "[$($chItems.IndexOf($k) + 1)] " + (ExamName (Prop $B.items $k))
          }
          P ($refs -join '   ') 'body' 'small'
        }
      }
    }
    # 장 끝: 기출 풀어 보기 (2단, 시험지처럼)
    if($chItems.Count -and -not $Lite){
      CtrlPara ((HeaderCtrl 'ᄉᆡ미 기픈 믈' "$($ch.chapter) · 기출 풀어 보기") + (ColCtrl 1)) -Break
      Mark "kx:$($ch.id)" "$($ch.chapter) — 기출 풀어 보기"
      SectionTitle "$($ch.chapter) — 기출 풀어 보기" '앞에서 [번호]로 소개한 평가원 기출입니다. 지문이 있는 문항은 지문을 먼저 실었습니다. 정답과 해설은 책 맨 끝에 있습니다.'
      CtrlPara (ColCtrl 2)
      $shownP = @{}
      for($n = 1; $n -le $chItems.Count; $n++){
        $key = $chItems[$n - 1]; $it = Prop $B.items $key
        if($it.pkey -and -not $shownP[$it.pkey]){
          $shownP[$it.pkey] = 1
          $ptxt = (Prop $B.passages $it.pkey).text
          Emit ((Rn "[$($it.range)] " 'qB') + (Rn '다음 글을 읽고 물음에 답하시오.' 'q') + (Rn "   $($it.exam -replace '학년도 ', ' ' -replace '대학수학능력시험', '수능')" 'small')) 'src'
          foreach($ln2 in ([string]$ptxt -split "`n")){ if($ln2.Trim()){ P $ln2 'passage' 'q' } }
        }
        ItemXml $key $n
        [void]$answers.Add(@{ ch = $ch.chapter; n = $n; key = $key })
      }
    }
  }
}

# ----- 정답과 해설 -----
if(-not $Lite){
  CtrlPara ((HeaderCtrl 'ᄉᆡ미 기픈 믈' '정답과 해설') + (ColCtrl 1)) -Break
  # '정답과 해설'은 기출 쪽 안내 문장에도 있으므로, 이 쪽에만 있는 문장으로 찾음
  Mark 'ans' '장마다 기출 풀어 보기의 번호 순서대로 정답과 해설을 실었습니다'
  SectionTitle '정답과 해설' "장마다 기출 풀어 보기의 번호 순서대로 정답과 해설을 실었습니다. 모두 $($answers.Count)문항입니다."
  CtrlPara (ColCtrl 2)
  $lastCh = ''
  foreach($a in $answers){
    if($a.ch -ne $lastCh){ P $a.ch 'label' 'h3'; $lastCh = $a.ch }
    $it = Prop $B.items $a.key
    Emit ((Rn "[$($a.n)] 정답 $($CIRCLED[[int]$it.answer])" 'ans') + (Rn "   $(ExamName $it)" 'small')) 'h3'
    if($it.explain){ foreach($ln2 in ([string]$it.explain -split "`n")){ if($ln2.Trim()){ P $ln2 'q' 'exN' } } }
  }
}

# ================= 꾸러미 =================
$ns = 'xmlns:ha="http://www.hancom.co.kr/hwpml/2011/app" xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph" xmlns:hp10="http://www.hancom.co.kr/hwpml/2016/paragraph" xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section" xmlns:hc="http://www.hancom.co.kr/hwpml/2011/core" xmlns:hh="http://www.hancom.co.kr/hwpml/2011/head" xmlns:hhs="http://www.hancom.co.kr/hwpml/2011/history" xmlns:hm="http://www.hancom.co.kr/hwpml/2011/master-page" xmlns:hpf="http://www.hancom.co.kr/schema/2011/hpf" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf/" xmlns:ooxmlchart="http://www.hancom.co.kr/hwpml/2016/ooxmlchart" xmlns:hwpunitchar="http://www.hancom.co.kr/hwpml/2016/HwpUnitChar" xmlns:epub="http://www.idpf.org/2007/ops" xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0"'
$xmlHead = '<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>'
$section = "$xmlHead<hs:sec $ns>" + $sb.ToString() + '</hs:sec>'

$fontList = @(@('함초롬돋움', 'FCAT_GOTHIC'), @('함초롬바탕', 'FCAT_MYUNGJO'), @('맑은 고딕', 'FCAT_GOTHIC'), @('맑은 고딕', 'FCAT_GOTHIC'), @('맑은 고딕', 'FCAT_GOTHIC'))
$fontFace = $(for($k = 0; $k -lt $fontList.Count; $k++){ "<hh:font id=`"$k`" face=`"$($fontList[$k][0])`" type=`"TTF`" isEmbedded=`"0`"><hh:typeInfo familyType=`"$($fontList[$k][1])`" weight=`"6`" proportion=`"4`" contrast=`"0`" strokeVariation=`"1`" armStyle=`"1`" letterform=`"1`" midline=`"1`" xHeight=`"1`"/></hh:font>" }) -join ''
$faces = (('HANGUL','LATIN','HANJA','JAPANESE','OTHER','SYMBOL','USER') | ForEach-Object { "<hh:fontface lang=`"$_`" fontCnt=`"$($fontList.Count)`">$fontFace</hh:fontface>" }) -join ''
$i = 0; $charXml = ($charDefs.Keys | ForEach-Object { CharPrXml ($i++) $charDefs[$_] }) -join ''
$i = 0; $paraXml = ($paraDefs.Keys | ForEach-Object { ParaPrXml ($i++) $paraDefs[$_] }) -join ''
$header = "$xmlHead<hh:head $ns version=`"1.5`" secCnt=`"1`"><hh:beginNum page=`"1`" footnote=`"1`" endnote=`"1`" pic=`"1`" tbl=`"1`" equation=`"1`"/><hh:refList>" +
  "<hh:fontfaces itemCnt=`"7`">$faces</hh:fontfaces>" +
  "<hh:borderFills itemCnt=`"$($bfList.Count)`">$($bfList -join '')</hh:borderFills>" +
  "<hh:charProperties itemCnt=`"$($charDefs.Count)`">$charXml</hh:charProperties>" +
  '<hh:tabProperties itemCnt="1"><hh:tabPr id="0" autoTabLeft="0" autoTabRight="0"/></hh:tabProperties>' +
  "<hh:paraProperties itemCnt=`"$($paraDefs.Count)`">$paraXml</hh:paraProperties>" +
  "<hh:styles itemCnt=`"1`"><hh:style id=`"0`" type=`"PARA`" name=`"바탕글`" engName=`"Normal`" paraPrIDRef=`"$($PA.body)`" charPrIDRef=`"$($CHR.body)`" nextStyleIDRef=`"0`" langID=`"1042`" lockForm=`"0`"/></hh:styles>" +
  '</hh:refList><hh:compatibleDocument targetProgram="HWP201X"><hh:layoutCompatibility/></hh:compatibleDocument><hh:docOption><hh:linkinfo path="" pageInherit="0" footnoteInherit="0"/></hh:docOption><hh:trackchageConfig flags="56"/></hh:head>'

$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$imgItems = ($images.Keys | ForEach-Object { "<opf:item id=`"$_`" href=`"BinData/$_.png`" media-type=`"image/png`" isEmbeded=`"1`"/>" }) -join ''
$title = $(if($Lite){ '수능 국어 개념서 (가벼운판)' } else { '수능 국어 개념서' })
$hpf = "$xmlHead<opf:package $ns version=`"`" unique-identifier=`"`" id=`"`"><opf:metadata><opf:title>$title</opf:title><opf:language>ko</opf:language><opf:meta name=`"creator`" content=`"text`">ᄉᆡ미 기픈 믈</opf:meta><opf:meta name=`"CreatedDate`" content=`"text`">$now</opf:meta><opf:meta name=`"ModifiedDate`" content=`"text`">$now</opf:meta></opf:metadata><opf:manifest><opf:item id=`"header`" href=`"Contents/header.xml`" media-type=`"application/xml`"/>$imgItems<opf:item id=`"section0`" href=`"Contents/section0.xml`" media-type=`"application/xml`"/><opf:item id=`"settings`" href=`"settings.xml`" media-type=`"application/xml`"/></opf:manifest><opf:spine><opf:itemref idref=`"header`" linear=`"yes`"/><opf:itemref idref=`"section0`" linear=`"yes`"/></opf:spine></opf:package>"
$files = [ordered]@{
  'version.xml' = "$xmlHead<hv:HCFVersion xmlns:hv=`"http://www.hancom.co.kr/hwpml/2011/version`" tagetApplication=`"WORDPROCESSOR`" major=`"5`" minor=`"1`" micro=`"1`" buildNumber=`"0`" os=`"1`" xmlVersion=`"1.5`" application=`"Hancom Office Hangul`" appVersion=`"13, 0, 0, 2151 WIN32LEWindows_10`"/>"
  'Contents/header.xml' = $header
  'Contents/section0.xml' = $section
  'Contents/content.hpf' = $hpf
  'settings.xml' = "$xmlHead<ha:HWPApplicationSetting xmlns:ha=`"http://www.hancom.co.kr/hwpml/2011/app`" xmlns:config=`"urn:oasis:names:tc:opendocument:xmlns:config:1.0`"><ha:CaretPosition listIDRef=`"0`" paraIDRef=`"0`" pos=`"0`"/></ha:HWPApplicationSetting>"
  'META-INF/container.xml' = "$xmlHead<ocf:container xmlns:ocf=`"urn:oasis:names:tc:opendocument:xmlns:container`" xmlns:hpf=`"http://www.hancom.co.kr/schema/2011/hpf`"><ocf:rootfiles><ocf:rootfile full-path=`"Contents/content.hpf`" media-type=`"application/hwpml-package+xml`"/><ocf:rootfile full-path=`"Preview/PrvText.txt`" media-type=`"text/plain`"/></ocf:rootfiles></ocf:container>"
  'META-INF/manifest.xml' = "$xmlHead<odf:manifest xmlns:odf=`"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0`"/>"
  'META-INF/container.rdf' = "$xmlHead<rdf:RDF xmlns:rdf=`"http://www.w3.org/1999/02/22-rdf-syntax-ns#`"><rdf:Description rdf:about=`"`"><ns0:hasPart xmlns:ns0=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#`" rdf:resource=`"Contents/header.xml`"/></rdf:Description><rdf:Description rdf:about=`"Contents/header.xml`"><rdf:type rdf:resource=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#HeaderFile`"/></rdf:Description><rdf:Description rdf:about=`"`"><ns0:hasPart xmlns:ns0=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#`" rdf:resource=`"Contents/section0.xml`"/></rdf:Description><rdf:Description rdf:about=`"Contents/section0.xml`"><rdf:type rdf:resource=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#SectionFile`"/></rdf:Description><rdf:Description rdf:about=`"`"><rdf:type rdf:resource=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#Document`"/></rdf:Description></rdf:RDF>"
  'Preview/PrvText.txt' = "ᄉᆡ미 기픈 믈 — $title"
}
foreach($k in 'Contents/header.xml', 'Contents/section0.xml', 'Contents/content.hpf'){ $d = New-Object Xml.XmlDocument; $d.LoadXml($files[$k]) }

if(Test-Path $Out){ Remove-Item $Out -Force }
$fs = [IO.File]::Open($Out, 'Create')
$zip = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
function AddEntry($name, [byte[]]$bytes, $level){ $e = $zip.CreateEntry($name, $level); $s = $e.Open(); $s.Write($bytes, 0, $bytes.Length); $s.Dispose() }
AddEntry 'mimetype' ([Text.Encoding]::ASCII.GetBytes('application/hwp+zip')) ([IO.Compression.CompressionLevel]::NoCompression)
foreach($k in $files.Keys){ AddEntry $k ($U8.GetBytes($files[$k])) ([IO.Compression.CompressionLevel]::Optimal) }
foreach($k in $images.Keys){ AddEntry "BinData/$k.png" ([IO.File]::ReadAllBytes($images[$k])) ([IO.Compression.CompressionLevel]::NoCompression) }
$zip.Dispose(); $fs.Dispose()
# 차례 쪽 번호를 찾을 문단 위치
[IO.File]::WriteAllText("$Out.paras.json", (ConvertTo-Json -InputObject $ANCHOR -Compress), $U8)
Write-Host ("책 저장: {0} ({1:N0} KB, 그림 {2}개, 기출 {3}문항, 쪽 번호 {4})" -f $Out, ((Get-Item $Out).Length / 1KB), $images.Count, $answers.Count, $(if($PAGES.Count){ '채움' } else { '빈칸' }))
