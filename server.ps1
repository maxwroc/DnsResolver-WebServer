Param(
    $Url = "http://localhost:8084/"
)

Add-Type -AssemblyName System.Web

$routes = @{
    "/dns" = { 
        Param($requestUrl)
        $queryParams = [System.Web.HttpUtility]::ParseQueryString($requestUrl.Query)
        
        if ($queryParams) {
            $queryParams.GetEnumerator() | % { 
                if ($_.Key) {
                    $queryParams[$_.Key] = $_.Value 
                }
            }
        }
        
        $response = @{
            host = $queryParams["host"]
        }
        
        if (-not $queryParams["host"]) {
            $response["error"] = "Missing host param"
            return $response | ConvertTo-Json -Depth 2
        }
        
        # Iterate over resolve result taking first address fromt he following order IpAddress Ip4Address Ip6Address
        $ip = Resolve-DnsName $queryParams["host"] | % {$ip=$null}{ $ip=@($_.IpAddress, $_.Ip4Address, $_.Ip6Address, $ip, $null -ne $null)[0] }{$ip}
        
        if (-not $ip) {
            $response["error"] = "Could not resolve given host"
            return $response | ConvertTo-Json -Depth 2
        }
        
        $response["ip"] = $ip
        
        return $response | ConvertTo-Json -Depth 2
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

    Write-Host ''
    Write-Host "> $requestUrl"

    $localPath = $requestUrl.LocalPath
    $route = $routes.Get_Item($requestUrl.LocalPath)

    if ($route -eq $null)
    {
        $response.StatusCode = 404
    }
    else
    {
        $content = Invoke-Command $route -ArgumentList @($requestUrl)
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    
    $response.Close()

    $responseStatus = $response.StatusCode
    Write-Host "< $responseStatus"
}

$listener.Stop();