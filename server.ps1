$port = 8080
$listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Any, $port)
$listener.Start()
Write-Host "=========================================================="
Write-Host " GAME SERVER LIVE ON ALL NETWORK INTERFACES"
Write-Host " PC Localhost : http://localhost:$port/"
Write-Host " Android Phone: http://192.168.220.33:$port/"
Write-Host "=========================================================="

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

while ($true) {
    try {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $line = $reader.ReadLine()
        if ($line) {
            $parts = $line.Split(' ')
            if ($parts.Length -ge 2) {
                $rawPath = $parts[1].Split('?')[0]
                if ($rawPath -eq '/' -or [string]::IsNullOrWhiteSpace($rawPath)) {
                    $rawPath = '/index.html'
                }
                $clean = $rawPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
                $filePath = Join-Path $baseDir $clean
                if (Test-Path $filePath -PathType Leaf) {
                    $bytes = [System.IO.File]::ReadAllBytes($filePath)
                    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                    $mime = 'text/html; charset=utf-8'
                    if ($ext -eq '.js') { $mime = 'application/javascript; charset=utf-8' }
                    elseif ($ext -eq '.css') { $mime = 'text/css; charset=utf-8' }
                    elseif ($ext -eq '.json') { $mime = 'application/json; charset=utf-8' }
                    elseif ($ext -eq '.png') { $mime = 'image/png' }
                    elseif ($ext -eq '.jpg') { $mime = 'image/jpeg' }

                    $head = "HTTP/1.1 200 OK`r`nContent-Type: $mime`r`nContent-Length: $($bytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nConnection: close`r`n`r`n"
                    $hBytes = [System.Text.Encoding]::ASCII.GetBytes($head)
                    $stream.Write($hBytes, 0, $hBytes.Length)
                    $stream.Write($bytes, 0, $bytes.Length)
                } else {
                    $nf = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 404 Not Found`r`nContent-Length: 0`r`nConnection: close`r`n`r`n")
                    $stream.Write($nf, 0, $nf.Length)
                }
            }
        }
        $stream.Flush()
        $client.Close()
    } catch {
        # ignore client disconnect
    }
}
