# 미리 보기용 로컬 서버: powershell -ExecutionPolicy Bypass -File tools\serve.ps1 [-Port 8765]
param([int]$Port = 8765)
$Root = Join-Path (Split-Path -Parent $PSScriptRoot) 'docs'
$types = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.json'='application/json; charset=utf-8'; '.png'='image/png'; '.woff'='font/woff'; '.svg'='image/svg+xml'; '.pdf'='application/pdf' }
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/")
$l.Start()
Write-Host "http://localhost:$Port/"
while($l.IsListening){
  $ctx = $l.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
  if(-not $path){ $path = 'index.html' }
  $file = Join-Path $Root $path
  $res = $ctx.Response
  if((Test-Path $file -PathType Leaf) -and ([IO.Path]::GetFullPath($file)).StartsWith([IO.Path]::GetFullPath($Root))){
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file).ToLower()
    $res.ContentType = $(if($types[$ext]){ $types[$ext] } else { 'application/octet-stream' })
    $res.Headers.Add('Cache-Control', 'no-store')
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  } else { $res.StatusCode = 404 }
  $res.Close()
}
