# book/book.json(빌드 결과) → book/수능국어_개념서.hwpx
# 사용법: powershell -ExecutionPolicy Bypass -File tools\make_hwpx.ps1   (build.ps1이 끝에서 자동으로 부름)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$U8 = New-Object Text.UTF8Encoding $false
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$B = [IO.File]::ReadAllText("$Root\book\book.json", [Text.Encoding]::UTF8) | ConvertFrom-Json
function Prop($o, $k){ $p = $o.PSObject.Properties[$k]; if($p){ $p.Value } else { $null } }
$CIRCLED = @('', '①', '②', '③', '④', '⑤')

# ---------- 쪽 ----------
$PW = 59528; $PH = 84186; $ML = 7087; $MR = 7087
$TW = $PW - $ML - $MR   # 본문 폭(HWPUNIT, 1pt = 100)

# ---------- 글자 모양 ----------
# 이름 → id. font 0 = 함초롬돋움, 1 = 함초롬바탕
$charDefs = [ordered]@{
  body      = @{ h=1000; f=1; c='#000000' }
  bodyB     = @{ h=1000; f=1; c='#1F4A3E'; b=1 }
  bodyU     = @{ h=1000; f=1; c='#000000'; u=1 }
  partT     = @{ h=2800; f=0; c='#1F4A3E'; b=1 }
  chT       = @{ h=2000; f=0; c='#000000'; b=1 }
  conT      = @{ h=1500; f=0; c='#1F4A3E'; b=1 }
  label     = @{ h=950;  f=0; c='#5B5852'; b=1 }
  small     = @{ h=880;  f=0; c='#5B5852' }
  smallB    = @{ h=880;  f=0; c='#1F4A3E'; b=1 }
  exT       = @{ h=1000; f=1; c='#000000'; b=1 }
  cell      = @{ h=920;  f=0; c='#000000' }
  cellB     = @{ h=920;  f=0; c='#1F4A3E'; b=1 }
  cellU     = @{ h=920;  f=0; c='#000000'; u=1 }
  head      = @{ h=920;  f=0; c='#1F4A3E'; b=1 }
  q         = @{ h=950;  f=1; c='#000000' }
  qB        = @{ h=950;  f=1; c='#000000'; b=1 }
  qU        = @{ h=950;  f=1; c='#000000'; u=1 }
  qUB       = @{ h=950;  f=1; c='#000000'; u=1; b=1 }
  src       = @{ h=900;  f=0; c='#1F4A3E'; b=1 }
  cover     = @{ h=4400; f=1; c='#1F4A3E'; b=1 }
  coverS    = @{ h=1600; f=0; c='#5B5852' }
  levelD    = @{ h=850;  f=0; c='#9A4A1C'; b=1 }
  levelK    = @{ h=850;  f=0; c='#2F5D50'; b=1 }
}
$CHR = @{}; $i = 0; foreach($k in $charDefs.Keys){ $CHR[$k] = $i; $i++ }
$BOLD = @{ body='bodyB'; cell='cellB'; q='qB'; qU='qUB'; exT='exT'; small='smallB' }
$UND  = @{ body='bodyU'; cell='cellU'; q='qU'; qB='qUB' }

function CharPrXml($id, $d){
  $five = 'hangul="{0}" latin="{0}" hanja="{0}" japanese="{0}" other="{0}" symbol="{0}" user="{0}"'
  $x = "<hh:charPr id=`"$id`" height=`"$($d.h)`" textColor=`"$($d.c)`" shadeColor=`"none`" useFontSpace=`"0`" useKerning=`"0`" symMark=`"NONE`" borderFillIDRef=`"2`">"
  $x += "<hh:fontRef $($five -f $d.f)/><hh:ratio $($five -f 100)/><hh:spacing $($five -f 0)/><hh:relSz $($five -f 100)/><hh:offset $($five -f 0)/>"
  if($d.b){ $x += '<hh:bold/>' }
  $x += $(if($d.u){ '<hh:underline type="BOTTOM" shape="SOLID" color="#000000"/>' } else { '<hh:underline type="NONE" shape="SOLID" color="#000000"/>' })
  $x += '<hh:strikeout shape="NONE" color="#000000"/><hh:outline type="NONE"/><hh:shadow type="NONE" color="#C0C0C0" offsetX="10" offsetY="10"/></hh:charPr>'
  $x
}

# ---------- 테두리·배경 ----------
function BorderFill($id, $line, $fill){
  $t = $(if($line){ 'SOLID' } else { 'NONE' })
  $x = "<hh:borderFill id=`"$id`" threeD=`"0`" shadow=`"0`" centerLine=`"NONE`" breakCellSeparateLine=`"0`"><hh:slash type=`"NONE`" Crooked=`"0`" isCounter=`"0`"/><hh:backSlash type=`"NONE`" Crooked=`"0`" isCounter=`"0`"/>"
  foreach($s in 'left','right','top','bottom'){ $x += "<hh:${s}Border type=`"$t`" width=`"0.12 mm`" color=`"#8A867E`"/>" }
  $x += '<hh:diagonal type="SOLID" width="0.1 mm" color="#000000"/>'
  if($fill){ $x += "<hc:fillBrush><hc:winBrush faceColor=`"$fill`" hatchColor=`"#999999`" alpha=`"0`"/></hc:fillBrush>" }
  $x + '</hh:borderFill>'
}
$borderFills = @(
  (BorderFill 1 $false $null),
  (BorderFill 2 $false $null),
  (BorderFill 3 $false '#E7EFE9'),   # 요약·정리 상자
  (BorderFill 4 $true  $null),       # <보기>, 표 칸
  (BorderFill 5 $true  '#E7EFE9'),   # 표 머리 칸
  (BorderFill 6 $false '#FBEFE6')    # 자주 틀리는 점
)
$BFID = @{ none=2; box=3; line=4; headCell=5; trap=6 }

# ---------- 문단 모양 ----------
# 이름 → 정의: align, line(%), left, right, indent, prev, next, border, keep
$paraDefs = [ordered]@{
  body    = @{ a='JUSTIFY'; l=165; prev=0;    next=300 }
  center  = @{ a='CENTER';  l=150; prev=0;    next=300 }
  partT   = @{ a='LEFT';    l=140; prev=6000; next=1200 }
  chT     = @{ a='LEFT';    l=140; prev=0;    next=800; keep=1 }
  conT    = @{ a='LEFT';    l=140; prev=1800; next=500; keep=1 }
  label   = @{ a='LEFT';    l=140; prev=900;  next=300; keep=1 }
  list    = @{ a='JUSTIFY'; l=160; left=1400; indent=-700; next=200 }
  box     = @{ a='JUSTIFY'; l=160; left=700; right=700; prev=200; next=200; border=$BFID.box }
  trap    = @{ a='JUSTIFY'; l=160; left=700; right=700; prev=150; next=150; border=$BFID.trap }
  cell    = @{ a='LEFT';    l=135 }
  cellC   = @{ a='CENTER';  l=135 }
  ex      = @{ a='LEFT';    l=150; left=700; next=80; keep=1 }
  exN     = @{ a='JUSTIFY'; l=150; left=1800; next=260 }
  q       = @{ a='JUSTIFY'; l=160; next=200 }
  qHang   = @{ a='JUSTIFY'; l=155; left=1300; indent=-1300; next=200; keep=1 }
  bogi    = @{ a='JUSTIFY'; l=160; left=900; right=900; prev=100; next=100; border=$BFID.line }
  bogiC   = @{ a='CENTER';  l=160; left=900; right=900; prev=100; next=0; border=$BFID.line }
  choice  = @{ a='JUSTIFY'; l=155; left=1700; indent=-900; next=60 }
  passage = @{ a='JUSTIFY'; l=165; indent=1000; next=0 }
  src     = @{ a='LEFT';    l=150; prev=1200; next=300; keep=1 }
  toc1    = @{ a='LEFT';    l=150; prev=500; next=100 }
  toc2    = @{ a='LEFT';    l=150; left=1400; next=0 }
}
$PA = @{}; $i = 0; foreach($k in $paraDefs.Keys){ $PA[$k] = $i; $i++ }
function ParaPrXml($id, $d){
  $m = "<hh:margin><hc:intent value=`"$([int]$d.indent)`" unit=`"HWPUNIT`"/><hc:left value=`"$([int]$d.left)`" unit=`"HWPUNIT`"/><hc:right value=`"$([int]$d.right)`" unit=`"HWPUNIT`"/><hc:prev value=`"$([int]$d.prev)`" unit=`"HWPUNIT`"/><hc:next value=`"$([int]$d.next)`" unit=`"HWPUNIT`"/></hh:margin><hh:lineSpacing type=`"PERCENT`" value=`"$($d.l)`" unit=`"HWPUNIT`"/>"
  $bf = $(if($d.border){ $d.border } else { 2 })
  $off = $(if($d.border){ 'offsetLeft="400" offsetRight="400" offsetTop="300" offsetBottom="300" connect="1"' } else { 'offsetLeft="0" offsetRight="0" offsetTop="0" offsetBottom="0" connect="0"' })
  "<hh:paraPr id=`"$id`" tabPrIDRef=`"0`" condense=`"0`" fontLineHeight=`"0`" snapToGrid=`"0`" suppressLineNumbers=`"0`" checked=`"0`" textDir=`"LTR`"><hh:align horizontal=`"$($d.a)`" vertical=`"BASELINE`"/><hh:heading type=`"NONE`" idRef=`"0`" level=`"0`"/><hh:breakSetting breakLatinWord=`"KEEP_WORD`" breakNonLatinWord=`"KEEP_WORD`" widowOrphan=`"1`" keepWithNext=`"$([int]$d.keep)`" keepLines=`"0`" pageBreakBefore=`"0`" lineWrap=`"BREAK`"/><hh:autoSpacing eAsianEng=`"0`" eAsianNum=`"0`"/><hp:switch><hp:case hp:required-namespace=`"http://www.hancom.co.kr/hwpml/2016/HwpUnitChar`">$m</hp:case><hp:default>$m</hp:default></hp:switch><hh:border borderFillIDRef=`"$bf`" $off ignoreMargin=`"0`"/></hh:paraPr>"
}

# ---------- 글자 다루기 ----------
function X($s){ ([string]$s).Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;') }
# 문자열 → run 목록. **굵게**, U+FDD0…FDD1 밑줄, U+FDD2…FDD3 상자(밑줄로 대신)
function Runs($text, $base){
  $s = [string]$text
  $out = New-Object Text.StringBuilder
  $parts = [regex]::Split($s, '(\*\*.+?\*\*)')
  foreach($p in $parts){
    if(-not $p){ continue }
    $style = $base; $t = $p
    if($p.StartsWith('**') -and $p.EndsWith('**') -and $p.Length -gt 4){ $t = $p.Substring(2, $p.Length - 4); if($BOLD[$base]){ $style = $BOLD[$base] } }
    $segs = [regex]::Split($t, '([﷐﷒][^﷑﷓]*[﷑﷓]?)')
    foreach($g in $segs){
      if(-not $g){ continue }
      $st = $style
      if($g[0] -eq [char]0xFDD0 -or $g[0] -eq [char]0xFDD2){ if($UND[$style]){ $st = $UND[$style] } }
      $g = $g -replace '[﷐-﷓]', ''
      if($g){ [void]$out.Append("<hp:run charPrIDRef=`"$($CHR[$st])`"><hp:t>$(X $g)</hp:t></hp:run>") }
    }
  }
  if($out.Length -eq 0){ [void]$out.Append("<hp:run charPrIDRef=`"$($CHR[$base])`"/>") }
  $out.ToString()
}
$sb = New-Object Text.StringBuilder
function P($text, $para = 'body', $char = 'body', [switch]$Break){
  $first = $true
  foreach($line in ([string]$text -split "`n")){
    $pb = $(if($Break -and $first){ '1' } else { '0' }); $first = $false
    [void]$sb.Append("<hp:p id=`"0`" paraPrIDRef=`"$($PA[$para])`" styleIDRef=`"0`" pageBreak=`"$pb`" columnBreak=`"0`" merged=`"0`">$(Runs $line $char)</hp:p>")
  }
}
function PRuns($runsXml, $para = 'body'){
  [void]$sb.Append("<hp:p id=`"0`" paraPrIDRef=`"$($PA[$para])`" styleIDRef=`"0`" pageBreak=`"0`" columnBreak=`"0`" merged=`"0`">$runsXml</hp:p>")
}

# ---------- 표 ----------
$script:objId = 1000
function Table($head, $rows, $widths = $null){
  $rows = @($rows)
  $nc = $(if($head){ @($head).Count } else { @($rows[0]).Count })
  $all = @(); if($head){ $all += ,@($head) }; foreach($r in $rows){ $all += ,@($r) }
  $nr = $all.Count
  if(-not $widths){
    # 글자 수에 비례한 열 너비(최소 12%)
    $len = @(for($c = 0; $c -lt $nc; $c++){ ($all | ForEach-Object { ([string]$_[$c]).Length } | Measure-Object -Maximum).Maximum + 4 })
    $sum = ($len | Measure-Object -Sum).Sum
    $widths = @($len | ForEach-Object { [math]::Max([int]($TW * 0.12), [int]($TW * $_ / $sum)) })
    $scale = $TW / ($widths | Measure-Object -Sum).Sum
    $widths = @($widths | ForEach-Object { [int]($_ * $scale) })
  }
  $script:objId++
  $x = "<hp:tbl id=`"$script:objId`" zOrder=`"0`" numberingType=`"TABLE`" textWrap=`"TOP_AND_BOTTOM`" textFlow=`"BOTH_SIDES`" lock=`"0`" dropcapstyle=`"None`" pageBreak=`"CELL`" repeatHeader=`"1`" rowCnt=`"$nr`" colCnt=`"$nc`" cellSpacing=`"0`" borderFillIDRef=`"$($BFID.line)`" noAdjust=`"0`"><hp:sz width=`"$TW`" widthRelTo=`"ABSOLUTE`" height=`"$($nr * 1800)`" heightRelTo=`"ABSOLUTE`" protect=`"0`"/><hp:pos treatAsChar=`"0`" affectLSpacing=`"0`" flowWithText=`"1`" allowOverlap=`"0`" holdAnchorAndSO=`"0`" vertRelTo=`"PARA`" horzRelTo=`"COLUMN`" vertAlign=`"TOP`" horzAlign=`"LEFT`" vertOffset=`"0`" horzOffset=`"0`"/><hp:outMargin left=`"0`" right=`"0`" top=`"200`" bottom=`"400`"/><hp:inMargin left=`"510`" right=`"510`" top=`"200`" bottom=`"200`"/>"
  for($r = 0; $r -lt $nr; $r++){
    $isHead = ($head -and $r -eq 0)
    $x += '<hp:tr>'
    for($c = 0; $c -lt $nc; $c++){
      $cellText = [string]$all[$r][$c]
      $bf = $(if($isHead){ $BFID.headCell } else { $BFID.line })
      $cp = $(if($isHead){ 'head' } else { 'cell' })
      $pp = $(if($isHead){ 'cellC' } else { 'cell' })
      $x += "<hp:tc name=`"`" header=`"$(if($isHead){1}else{0})`" hasMargin=`"0`" protect=`"0`" editable=`"0`" dirty=`"0`" borderFillIDRef=`"$bf`"><hp:subList id=`"`" textDirection=`"HORIZONTAL`" lineWrap=`"BREAK`" vertAlign=`"CENTER`" linkListIDRef=`"0`" linkListNextIDRef=`"0`" textWidth=`"0`" textHeight=`"0`" hasTextRef=`"0`" hasNumRef=`"0`">"
      $x += "<hp:p id=`"0`" paraPrIDRef=`"$($PA[$pp])`" styleIDRef=`"0`" pageBreak=`"0`" columnBreak=`"0`" merged=`"0`">$(Runs $cellText $cp)</hp:p>"
      $x += "</hp:subList><hp:cellAddr colAddr=`"$c`" rowAddr=`"$r`"/><hp:cellSpan colSpan=`"1`" rowSpan=`"1`"/><hp:cellSz width=`"$($widths[$c])`" height=`"1800`"/><hp:cellMargin left=`"510`" right=`"510`" top=`"200`" bottom=`"200`"/></hp:tc>"
    }
    $x += '</hp:tr>'
  }
  $x += '</hp:tbl>'
  PRuns "<hp:run charPrIDRef=`"$($CHR.body)`">$x<hp:t/></hp:run>" 'body'
}

# ---------- 그림 ----------
$images = [ordered]@{}   # binId → 원본 경로
function Picture($rel, $maxW){
  $path = Join-Path "$Root\docs" $rel
  if(-not (Test-Path $path)){ P '(그림을 찾지 못했습니다)' 'body' 'small'; return }
  $binId = 'image' + ($images.Count + 1)
  $images[$binId] = $path
  $img = [System.Drawing.Image]::FromFile($path)
  $pw = $img.Width; $ph = $img.Height; $img.Dispose()
  $ow = $pw * 75; $oh = $ph * 75                    # 96dpi 기준 원래 크기
  $w = [int][math]::Min($maxW, $ow * 0.62)           # 문제지 그림은 크게 잘라 두었으므로 줄여 넣음
  $h = [int]($oh * $w / $ow)
  $script:objId++
  $sx = '{0:0.######}' -f ($w / $ow); $sy = '{0:0.######}' -f ($h / $oh)
  $x = "<hp:pic id=`"$script:objId`" zOrder=`"0`" numberingType=`"PICTURE`" textWrap=`"TOP_AND_BOTTOM`" textFlow=`"BOTH_SIDES`" lock=`"0`" dropcapstyle=`"None`" href=`"`" groupLevel=`"0`" instid=`"$($script:objId + 500000)`" reverse=`"0`"><hp:offset x=`"0`" y=`"0`"/><hp:orgSz width=`"$ow`" height=`"$oh`"/><hp:curSz width=`"$w`" height=`"$h`"/><hp:flip horizontal=`"0`" vertical=`"0`"/><hp:rotationInfo angle=`"0`" centerX=`"$([int]($w/2))`" centerY=`"$([int]($h/2))`" rotateimage=`"1`"/><hp:renderingInfo><hc:transMatrix e1=`"1`" e2=`"0`" e3=`"0`" e4=`"0`" e5=`"1`" e6=`"0`"/><hc:scaMatrix e1=`"$sx`" e2=`"0`" e3=`"0`" e4=`"0`" e5=`"$sy`" e6=`"0`"/><hc:rotMatrix e1=`"1`" e2=`"0`" e3=`"0`" e4=`"0`" e5=`"1`" e6=`"0`"/></hp:renderingInfo><hp:imgRect><hc:pt0 x=`"0`" y=`"0`"/><hc:pt1 x=`"$ow`" y=`"0`"/><hc:pt2 x=`"$ow`" y=`"$oh`"/><hc:pt3 x=`"0`" y=`"$oh`"/></hp:imgRect><hp:imgClip left=`"0`" right=`"$ow`" top=`"0`" bottom=`"$oh`"/><hp:inMargin left=`"0`" right=`"0`" top=`"0`" bottom=`"0`"/><hp:imgDim dimwidth=`"$ow`" dimheight=`"$oh`"/><hc:img binaryItemIDRef=`"$binId`" bright=`"0`" contrast=`"0`" effect=`"REAL_PIC`" alpha=`"0`"/><hp:effects/><hp:sz width=`"$w`" widthRelTo=`"ABSOLUTE`" height=`"$h`" heightRelTo=`"ABSOLUTE`" protect=`"0`"/><hp:pos treatAsChar=`"1`" affectLSpacing=`"0`" flowWithText=`"1`" allowOverlap=`"0`" holdAnchorAndSO=`"0`" vertRelTo=`"PARA`" horzRelTo=`"COLUMN`" vertAlign=`"TOP`" horzAlign=`"LEFT`" vertOffset=`"0`" horzOffset=`"0`"/><hp:outMargin left=`"0`" right=`"0`" top=`"0`" bottom=`"0`"/><hp:shapeComment>문제지 그림</hp:shapeComment></hp:pic>"
  PRuns "<hp:run charPrIDRef=`"$($CHR.body)`">$x<hp:t/></hp:run>" 'center'
}

# ---------- 기출 문항 ----------
function ExamName($it){ ($it.exam -replace '학년도 ', ' ' -replace '대학수학능력시험', '수능') + " $($it.no)번" }
function ItemXml($key, $num){
  $it = Prop $B.items $key
  $stem = ([string]$it.stem) -replace '^\s*\d+\.\s*', ''
  PRuns ("<hp:run charPrIDRef=`"$($CHR.qB)`"><hp:t>$num. </hp:t></hp:run>" + (Runs $stem 'q') + "<hp:run charPrIDRef=`"$($CHR.small)`"><hp:t>  [$(X (ExamName $it))]</hp:t></hp:run>") 'qHang'
  if($it.fig -and $it.fig.m -eq 'bogi'){ foreach($ff in ($it.fig.f -split ' ')){ Picture $ff ($TW - 1800) } }
  elseif($it.bogi){
    $m = [regex]::Match([string]$it.bogi, '^<\s*([^<>]{1,12}?)\s*>\s*')
    if($m.Success){ P "< $($m.Groups[1].Value) >" 'bogiC' 'q'; P ([string]$it.bogi).Substring($m.Length) 'bogi' 'q' }
    else { P $it.bogi 'bogi' 'q' }
  }
  if($it.fig -and $it.fig.m -eq 'ch'){ foreach($ff in ($it.fig.f -split ' ')){ Picture $ff ($TW - 1800) } }
  else {
    $ch = @($it.choices)
    for($n = 1; $n -le 5; $n++){ P ("$($CIRCLED[$n]) " + $(if($ch.Count -ge $n){ $ch[$n - 1] } else { '' })) 'choice' 'q' }
  }
}

# ================= 본문 짜기 =================
$secPr = "<hp:secPr id=`"`" textDirection=`"HORIZONTAL`" spaceColumns=`"1134`" tabStop=`"8000`" tabStopVal=`"4000`" tabStopUnit=`"HWPUNIT`" outlineShapeIDRef=`"1`" memoShapeIDRef=`"0`" textVerticalWidthHead=`"0`" masterPageCnt=`"0`"><hp:grid lineGrid=`"0`" charGrid=`"0`" wonggojiFormat=`"0`"/><hp:startNum pageStartsOn=`"BOTH`" page=`"0`" pic=`"0`" tbl=`"0`" equation=`"0`"/><hp:visibility hideFirstHeader=`"0`" hideFirstFooter=`"0`" hideFirstMasterPage=`"0`" border=`"SHOW_ALL`" fill=`"SHOW_ALL`" hideFirstPageNum=`"1`" hideFirstEmptyLine=`"0`" showLineNumber=`"0`"/><hp:lineNumberShape restartType=`"0`" countBy=`"0`" distance=`"0`" startNumber=`"0`"/><hp:pagePr landscape=`"WIDELY`" width=`"$PW`" height=`"$PH`" gutterType=`"LEFT_ONLY`"><hp:margin header=`"2834`" footer=`"2834`" gutter=`"0`" left=`"$ML`" right=`"$MR`" top=`"5102`" bottom=`"4252`"/></hp:pagePr><hp:footNotePr><hp:autoNumFormat type=`"DIGIT`" userChar=`"`" prefixChar=`"`" suffixChar=`")`" supscript=`"0`"/><hp:noteLine length=`"-1`" type=`"SOLID`" width=`"0.12 mm`" color=`"#000000`"/><hp:noteSpacing betweenNotes=`"283`" belowLine=`"567`" aboveLine=`"850`"/><hp:numbering type=`"CONTINUOUS`" newNum=`"1`"/><hp:placement place=`"EACH_COLUMN`" beneathText=`"0`"/></hp:footNotePr><hp:endNotePr><hp:autoNumFormat type=`"DIGIT`" userChar=`"`" prefixChar=`"`" suffixChar=`")`" supscript=`"0`"/><hp:noteLine length=`"14692344`" type=`"SOLID`" width=`"0.12 mm`" color=`"#000000`"/><hp:noteSpacing betweenNotes=`"0`" belowLine=`"567`" aboveLine=`"850`"/><hp:numbering type=`"CONTINUOUS`" newNum=`"1`"/><hp:placement place=`"END_OF_DOCUMENT`" beneathText=`"0`"/></hp:endNotePr><hp:pageBorderFill type=`"BOTH`" borderFillIDRef=`"1`" textBorder=`"PAPER`" headerInside=`"0`" footerInside=`"0`" fillArea=`"PAPER`"><hp:offset left=`"1417`" right=`"1417`" top=`"1417`" bottom=`"1417`"/></hp:pageBorderFill><hp:pageBorderFill type=`"EVEN`" borderFillIDRef=`"1`" textBorder=`"PAPER`" headerInside=`"0`" footerInside=`"0`" fillArea=`"PAPER`"><hp:offset left=`"1417`" right=`"1417`" top=`"1417`" bottom=`"1417`"/></hp:pageBorderFill><hp:pageBorderFill type=`"ODD`" borderFillIDRef=`"1`" textBorder=`"PAPER`" headerInside=`"0`" footerInside=`"0`" fillArea=`"PAPER`"><hp:offset left=`"1417`" right=`"1417`" top=`"1417`" bottom=`"1417`"/></hp:pageBorderFill></hp:secPr>"
$first = "<hp:p id=`"0`" paraPrIDRef=`"$($PA.center)`" styleIDRef=`"0`" pageBreak=`"0`" columnBreak=`"0`" merged=`"0`"><hp:run charPrIDRef=`"$($CHR.body)`">$secPr<hp:ctrl><hp:colPr id=`"`" type=`"NEWSPAPER`" layout=`"LEFT`" colCount=`"1`" sameSz=`"1`" sameGap=`"0`"/></hp:ctrl><hp:ctrl><hp:pageNum pos=`"BOTTOM_CENTER`" formatType=`"DIGIT`" sideChar=`"-`"/></hp:ctrl></hp:run></hp:p>"
[void]$sb.Append($first)

# 표지
for($k = 0; $k -lt 6; $k++){ P '' 'center' 'body' }
P 'ᄉᆡ미 기픈 믈' 'center' 'cover'
P '수능 국어 개념서 — 개념 · 예문 · 평가원 기출' 'center' 'coverS'
for($k = 0; $k -lt 14; $k++){ P '' 'center' 'body' }
P "$($B.built) 엮음 · 기출 문항·지문·선택지의 저작권은 한국교육과정평가원에 있으며 비영리 학습용으로만 씁니다." 'center' 'small'

# 일러두기
P '일러두기' 'chT' 'chT' -Break
P '이 책은 웹 사이트 「ᄉᆡ미 기픈 믈」과 같은 내용으로 만들어졌습니다. 한 개념은 ‘핵심 요약 → 개념 → 예문 → 자주 틀리는 점 → 관련 평가원 기출’ 순서로 짜여 있습니다.' 'body' 'body'
P '관련 기출의 문제 전문은 각 장 끝 ‘기출 풀어 보기’에 모았고, 정답과 해설은 책 맨 끝에 있습니다. 웹 사이트에서는 같은 문제를 바로 풀고 채점할 수 있습니다.' 'body' 'body'
P '2028학년도 수능부터 국어는 선택 과목 없이 화법과 언어(1~10번), 독서와 작문(11~30번), 문학(31~45번)의 45문항을 모두 풉니다. 문법은 ‘화법과 언어’에 들어가며 화법 상황과 섞여 나올 수 있습니다.' 'box' 'body'

# 차례
P '차례' 'chT' 'chT' -Break
$lastPart = ''
foreach($ch in $B.chapters){
  if($ch.part -ne $lastPart){ P $ch.part 'toc1' 'label'; $lastPart = $ch.part }
  P ("$($ch.chapter)  —  " + (($ch.concepts | ForEach-Object { $_.title }) -join ' · ')) 'toc2' 'small'
}

# 장
$answers = New-Object System.Collections.ArrayList
$lastPart = ''
foreach($ch in $B.chapters){
  if($ch.part -ne $lastPart){ P $ch.part 'partT' 'partT' -Break; $lastPart = $ch.part }
  P $ch.chapter 'chT' 'chT' -Break
  if($ch.intro){ P $ch.intro 'box' 'body' }
  $chItems = New-Object System.Collections.ArrayList
  foreach($c in $ch.concepts){
    $lv = $(if($c.level -eq '심화'){ 'levelD' } else { 'levelK' })
    PRuns ((Runs $c.title 'conT') + "<hp:run charPrIDRef=`"$($CHR[$lv])`"><hp:t>  $(X $(if($c.level){$c.level}else{'핵심'}))</hp:t></hp:run>") 'conT'
    P $c.summary 'box' 'body'
    foreach($bl in @($c.body)){
      if($null -ne (Prop $bl 'p')){ P $bl.p 'body' 'body' }
      elseif($null -ne (Prop $bl 'h')){ P ('■ ' + $bl.h) 'label' 'smallB' }
      elseif($null -ne (Prop $bl 'list')){ foreach($li in @($bl.list)){ P ('• ' + $li) 'list' 'body' } }
      elseif($null -ne (Prop $bl 'table')){ Table (Prop $bl.table 'head') $bl.table.rows }
      elseif($null -ne (Prop $bl 'box')){ if($bl.title){ P ('**' + $bl.title + '**  ' + $bl.box) 'box' 'body' } else { P $bl.box 'box' 'body' } }
    }
    if(@($c.examples).Count){
      P '예문' 'label' 'label'
      foreach($e in @($c.examples)){ P ('▸ ' + $e.ex) 'ex' 'exT'; if($e.note){ P $e.note 'exN' 'small' } }
    }
    if(@($c.traps).Count){
      P '자주 틀리는 점' 'label' 'label'
      foreach($t in @($c.traps)){ P ('! ' + $t) 'trap' 'body' }
    }
    $ks = @($c.kichul | Where-Object { Prop $B.items $_ })
    if($ks.Count){
      P '관련 평가원 기출' 'label' 'label'
      $refs = foreach($k in $ks){
        if(-not ($chItems -contains $k)){ [void]$chItems.Add($k) }
        $n = $chItems.IndexOf($k) + 1
        "[$n] " + (ExamName (Prop $B.items $k))
      }
      P ($refs -join '   ') 'body' 'small'
    }
  }
  # 장 끝 기출 풀어 보기
  if($chItems.Count){
    P "$($ch.chapter) — 기출 풀어 보기" 'chT' 'chT' -Break
    P '앞에서 [번호]로 소개한 문항입니다. 지문이 있는 문항은 지문을 먼저 실었습니다. 정답과 해설은 책 맨 끝에 있습니다.' 'body' 'small'
    $shownP = @{}
    for($n = 1; $n -le $chItems.Count; $n++){
      $key = $chItems[$n - 1]; $it = Prop $B.items $key
      if($it.pkey -and -not $shownP[$it.pkey]){
        $shownP[$it.pkey] = 1
        $ptxt = (Prop $B.passages $it.pkey).text
        P "[$($it.range)] $($it.exam -replace '학년도 ', ' ' -replace '대학수학능력시험', '수능') 지문" 'src' 'src'
        foreach($line in ([string]$ptxt -split "`n")){ if($line.Trim()){ P $line 'passage' 'q' } }
      } elseif(-not $it.pkey){ P '' 'body' 'body' }
      ItemXml $key $n
      [void]$answers.Add(@{ ch = $ch.chapter; n = $n; key = $key })
    }
  }
}

# 정답과 해설
P '정답과 해설' 'partT' 'partT' -Break
$lastCh = ''
foreach($a in $answers){
  if($a.ch -ne $lastCh){ P $a.ch 'conT' 'conT'; $lastCh = $a.ch }
  $it = Prop $B.items $a.key
  PRuns ("<hp:run charPrIDRef=`"$($CHR.qB)`"><hp:t>[$($a.n)] 정답 $($CIRCLED[[int]$it.answer])</hp:t></hp:run><hp:run charPrIDRef=`"$($CHR.small)`"><hp:t>  $(X (ExamName $it))</hp:t></hp:run>") 'src'
  if($it.explain){ foreach($line in ([string]$it.explain -split "`n")){ if($line.Trim()){ P $line 'body' 'q' } } }
}

# ================= 꾸러미 =================
$ns = 'xmlns:ha="http://www.hancom.co.kr/hwpml/2011/app" xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph" xmlns:hp10="http://www.hancom.co.kr/hwpml/2016/paragraph" xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section" xmlns:hc="http://www.hancom.co.kr/hwpml/2011/core" xmlns:hh="http://www.hancom.co.kr/hwpml/2011/head" xmlns:hhs="http://www.hancom.co.kr/hwpml/2011/history" xmlns:hm="http://www.hancom.co.kr/hwpml/2011/master-page" xmlns:hpf="http://www.hancom.co.kr/schema/2011/hpf" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf/" xmlns:ooxmlchart="http://www.hancom.co.kr/hwpml/2016/ooxmlchart" xmlns:hwpunitchar="http://www.hancom.co.kr/hwpml/2016/HwpUnitChar" xmlns:epub="http://www.idpf.org/2007/ops" xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0"'
$xmlHead = '<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>'
$section = "$xmlHead<hs:sec $ns>" + $sb.ToString() + '</hs:sec>'

$fontFace = '<hh:font id="0" face="함초롬돋움" type="TTF" isEmbedded="0"><hh:typeInfo familyType="FCAT_GOTHIC" weight="6" proportion="4" contrast="0" strokeVariation="1" armStyle="1" letterform="1" midline="1" xHeight="1"/></hh:font><hh:font id="1" face="함초롬바탕" type="TTF" isEmbedded="0"><hh:typeInfo familyType="FCAT_MYUNGJO" weight="6" proportion="4" contrast="0" strokeVariation="1" armStyle="1" letterform="1" midline="1" xHeight="1"/></hh:font>'
$faces = (('HANGUL','LATIN','HANJA','JAPANESE','OTHER','SYMBOL','USER') | ForEach-Object { "<hh:fontface lang=`"$_`" fontCnt=`"2`">$fontFace</hh:fontface>" }) -join ''
$i = 0; $charXml = ($charDefs.Keys | ForEach-Object { CharPrXml ($i++) $charDefs[$_] }) -join ''
$i = 0; $paraXml = ($paraDefs.Keys | ForEach-Object { ParaPrXml ($i++) $paraDefs[$_] }) -join ''
$header = "$xmlHead<hh:head $ns version=`"1.5`" secCnt=`"1`"><hh:beginNum page=`"1`" footnote=`"1`" endnote=`"1`" pic=`"1`" tbl=`"1`" equation=`"1`"/><hh:refList>" +
  "<hh:fontfaces itemCnt=`"7`">$faces</hh:fontfaces>" +
  "<hh:borderFills itemCnt=`"$($borderFills.Count)`">$($borderFills -join '')</hh:borderFills>" +
  "<hh:charProperties itemCnt=`"$($charDefs.Count)`">$charXml</hh:charProperties>" +
  '<hh:tabProperties itemCnt="1"><hh:tabPr id="0" autoTabLeft="0" autoTabRight="0"/></hh:tabProperties>' +
  "<hh:paraProperties itemCnt=`"$($paraDefs.Count)`">$paraXml</hh:paraProperties>" +
  "<hh:styles itemCnt=`"1`"><hh:style id=`"0`" type=`"PARA`" name=`"바탕글`" engName=`"Normal`" paraPrIDRef=`"$($PA.body)`" charPrIDRef=`"$($CHR.body)`" nextStyleIDRef=`"0`" langID=`"1042`" lockForm=`"0`"/></hh:styles>" +
  '</hh:refList><hh:compatibleDocument targetProgram="HWP201X"><hh:layoutCompatibility/></hh:compatibleDocument><hh:docOption><hh:linkinfo path="" pageInherit="0" footnoteInherit="0"/></hh:docOption><hh:trackchageConfig flags="56"/></hh:head>'

$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$imgItems = ($images.Keys | ForEach-Object { "<opf:item id=`"$_`" href=`"BinData/$_.png`" media-type=`"image/png`" isEmbeded=`"1`"/>" }) -join ''
$hpf = "$xmlHead<opf:package $ns version=`"`" unique-identifier=`"`" id=`"`"><opf:metadata><opf:title>수능 국어 개념서</opf:title><opf:language>ko</opf:language><opf:meta name=`"creator`" content=`"text`">ᄉᆡ미 기픈 믈</opf:meta><opf:meta name=`"CreatedDate`" content=`"text`">$now</opf:meta><opf:meta name=`"ModifiedDate`" content=`"text`">$now</opf:meta></opf:metadata><opf:manifest><opf:item id=`"header`" href=`"Contents/header.xml`" media-type=`"application/xml`"/>$imgItems<opf:item id=`"section0`" href=`"Contents/section0.xml`" media-type=`"application/xml`"/><opf:item id=`"settings`" href=`"settings.xml`" media-type=`"application/xml`"/></opf:manifest><opf:spine><opf:itemref idref=`"header`" linear=`"yes`"/><opf:itemref idref=`"section0`" linear=`"yes`"/></opf:spine></opf:package>"

$files = [ordered]@{
  'version.xml' = "$xmlHead<hv:HCFVersion xmlns:hv=`"http://www.hancom.co.kr/hwpml/2011/version`" tagetApplication=`"WORDPROCESSOR`" major=`"5`" minor=`"1`" micro=`"1`" buildNumber=`"0`" os=`"1`" xmlVersion=`"1.5`" application=`"Hancom Office Hangul`" appVersion=`"13, 0, 0, 2151 WIN32LEWindows_10`"/>"
  'Contents/header.xml' = $header
  'Contents/section0.xml' = $section
  'Contents/content.hpf' = $hpf
  'settings.xml' = "$xmlHead<ha:HWPApplicationSetting xmlns:ha=`"http://www.hancom.co.kr/hwpml/2011/app`" xmlns:config=`"urn:oasis:names:tc:opendocument:xmlns:config:1.0`"><ha:CaretPosition listIDRef=`"0`" paraIDRef=`"0`" pos=`"0`"/></ha:HWPApplicationSetting>"
  'META-INF/container.xml' = "$xmlHead<ocf:container xmlns:ocf=`"urn:oasis:names:tc:opendocument:xmlns:container`" xmlns:hpf=`"http://www.hancom.co.kr/schema/2011/hpf`"><ocf:rootfiles><ocf:rootfile full-path=`"Contents/content.hpf`" media-type=`"application/hwpml-package+xml`"/><ocf:rootfile full-path=`"Preview/PrvText.txt`" media-type=`"text/plain`"/></ocf:rootfiles></ocf:container>"
  'META-INF/manifest.xml' = "$xmlHead<odf:manifest xmlns:odf=`"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0`"/>"
  'META-INF/container.rdf' = "$xmlHead<rdf:RDF xmlns:rdf=`"http://www.w3.org/1999/02/22-rdf-syntax-ns#`"><rdf:Description rdf:about=`"`"><ns0:hasPart xmlns:ns0=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#`" rdf:resource=`"Contents/header.xml`"/></rdf:Description><rdf:Description rdf:about=`"Contents/header.xml`"><rdf:type rdf:resource=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#HeaderFile`"/></rdf:Description><rdf:Description rdf:about=`"`"><ns0:hasPart xmlns:ns0=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#`" rdf:resource=`"Contents/section0.xml`"/></rdf:Description><rdf:Description rdf:about=`"Contents/section0.xml`"><rdf:type rdf:resource=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#SectionFile`"/></rdf:Description><rdf:Description rdf:about=`"`"><rdf:type rdf:resource=`"http://www.hancom.co.kr/hwpml/2016/meta/pkg#Document`"/></rdf:Description></rdf:RDF>"
  'Preview/PrvText.txt' = "ᄉᆡ미 기픈 믈 — 수능 국어 개념서"
}

# XML이 올바른지 먼저 확인
foreach($k in 'Contents/header.xml', 'Contents/section0.xml', 'Contents/content.hpf'){ $d = New-Object Xml.XmlDocument; $d.LoadXml($files[$k]) }

$out = "$Root\book\수능국어_개념서.hwpx"
if(Test-Path $out){ Remove-Item $out -Force }
$fs = [IO.File]::Open($out, 'Create')
$zip = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
function AddEntry($name, [byte[]]$bytes, $level){
  $e = $zip.CreateEntry($name, $level)
  $s = $e.Open(); $s.Write($bytes, 0, $bytes.Length); $s.Dispose()
}
AddEntry 'mimetype' ([Text.Encoding]::ASCII.GetBytes('application/hwp+zip')) ([IO.Compression.CompressionLevel]::NoCompression)
foreach($k in $files.Keys){ AddEntry $k ($U8.GetBytes($files[$k])) ([IO.Compression.CompressionLevel]::Optimal) }
foreach($k in $images.Keys){ AddEntry "BinData/$k.png" ([IO.File]::ReadAllBytes($images[$k])) ([IO.Compression.CompressionLevel]::NoCompression) }
$zip.Dispose(); $fs.Dispose()
Write-Host ("책 저장: {0} ({1:N0} KB, 그림 {2}개, 기출 {3}문항)" -f $out, ((Get-Item $out).Length / 1KB), $images.Count, $answers.Count)
