<#
    .SYNOPSIS
    Simple (test) web server.

    .DESCRIPTION
    This is a simple web server. It runs on a single thread so It doesn't support parallel connections. If new request comes it will be on hold till the previous one finishes.

    It should be used only for test purposes (for example to test web client app) or cases when you are sure that parallel connections won't happen.

    To stop the server press Ctrl+C and send the last request to server address. The second step is required for unblocking the code execution ($context = $listener.GetContext()).

    Consider using server-runner.ps1 if you prefer simplified usage.

    .EXAMPLE
    server.ps1 -Url "http://localhost:8084/"
    # Starts
#>
Param(
    $Url = "http://localhost:8084/"
)

Add-Type -AssemblyName System.Web

# Script snippets / handlers for request paths
$routes = @{
    "/sleep" = {
        Param($queryParams)

        $delay = 2000

        if ($queryParams["delay"]) {
            $delay = $queryParams["delay"]
        }

        Start-Sleep -Milliseconds $delay
        return "Ups... sorry, I was sleeping $($delay)ms"
    }
}

Function PrintAdditionalRequestInfo {
    Param($request, $print)

    if ($print -eq "cookies") {
        Write-Host "> Cookie: $($request.Headers["Cookie"])"
    }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($Url)

try {
    $listener.Start()
}
catch {
    Write-Error "Failed to start server.`n$($_.Exception.Message)"
    return
}

while ($listener.IsListening)
{
    $context = $listener.GetContext()
    $requestUrl = $context.Request.Url
    $response = $context.Response

    Write-Host ""
    Write-Host "> $requestUrl"

    $localPath = $requestUrl.LocalPath
    $route = $routes.Get_Item($requestUrl.LocalPath)

    if ($route -eq $null)
    {
        $response.StatusCode = 404
    }
    else
    {
        $queryParams = [System.Web.HttpUtility]::ParseQueryString($requestUrl.Query)
        $parsedParams = @{}
        if ($queryParams) {
            $queryParams.GetEnumerator() | % {
                $parsedParams.Add($_, $queryParams[$_])
            }
        }

        if ($parsedParams["print"]) {
            PrintAdditionalRequestInfo $context.Request $parsedParams["print"]
        }

        $content = Invoke-Command $route -ArgumentList @($parsedParams)
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }

    $response.Close()

    $responseStatus = $response.StatusCode
    Write-Host "< $responseStatus"
}

$listener.Stop();