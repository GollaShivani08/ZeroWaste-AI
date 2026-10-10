# ZeroWaste AI - Standalone Local HTTP Server (PowerShell .NET HttpListener)
# Runs natively on Windows with zero external runtime dependencies!

$port = 8080
$url = "http://localhost:$port/"
$baseDir = $PSScriptRoot

if (-not [System.Net.HttpListener]::IsSupported) {
    Write-Error "HttpListener is not supported on this platform."
    exit 1
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)

try {
    $listener.Start()
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  ZeroWaste AI Local Web Server Running!" -ForegroundColor Green
    Write-Host "  URL: $url" -ForegroundColor Cyan
    Write-Host "  Serving from: $baseDir" -ForegroundColor DarkGray
    Write-Host "  Press Ctrl+C in this terminal window to stop the server." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host ""

    # Open default browser
    Start-Process $url

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $localPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($localPath)) {
            $localPath = "index.html"
        }

        # Normalize path
        $filePath = [System.IO.Path]::Combine($baseDir, $localPath.Replace('/', '\'))

        if ([System.IO.File]::Exists($filePath)) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".htm"  { "text/html; charset=utf-8" }
                ".js"   { "application/javascript; charset=utf-8" }
                ".mjs"  { "application/javascript; charset=utf-8" }
                ".css"  { "text/css; charset=utf-8" }
                ".json" { "application/json; charset=utf-8" }
                ".png"  { "image/png" }
                ".jpg"  { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".svg"  { "image/svg+xml" }
                ".ico"  { "image/x-icon" }
                default { "application/octet-stream" }
            }

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFoundBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.ContentLength64 = $notFoundBytes.Length
            $response.OutputStream.Write($notFoundBytes, 0, $notFoundBytes.Length)
        }

        $response.OutputStream.Close()
    }
}
catch {
    Write-Host "Server stopped: $_" -ForegroundColor Red
}
finally {
    $listener.Stop()
    $listener.Close()
}
