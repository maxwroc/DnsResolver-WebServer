Param(
    [string]$HostToResolve,
    [switch]$UpdateHostsFile = $false,
    [string]$Server = $null
)

$defaultServer = "localhost:8084"

Function Add-HostIp {
    Param($HostName, $Ip)
    
    $Pattern = '^(?<IP>\d{1,3}(\.\d{1,3}){3})\s+(?<Host>.+)$'
    $File    = "$env:SystemDrive\Windows\System32\Drivers\etc\hosts"
    
    $okToAdd = $true
    (Get-Content -Path $File)  | % {
        If ($_ -match $Pattern) {
            $Entries += "$env:COMPUTERNAME,$($Matches.IP),$($Matches.Host)"
            if (($Matches.Host -like $HostName) -or ($Matches.Ip -like $Ip)) {
                Write-Host -ForegroundColor Yeallow "Already in hosts file (Host: $HostName, Ip: $Ip)`n$_"
                $okToAdd = $false
            }
        }
    }
    
    if ($okToAdd) {
        Add-Content -Path $File -Value "`n$Ip`t$HostName"
        Write-Host -ForegroundColor Green "Host added to hosts file"
    }
}

Function Get-ServerHost {
    $configFile = "$PSScriptRoot\server-address.conf"
    
    if ($Server) {
        Set-Content -Path $configFile -Value $Server
        return $Server
    }
    
    if (Test-Path $configFile) {
        return Get-Content -Path $configFile
    }
    
    return $defaultServer
}

# Check if name cannot be resolved locally
$ipResult = Resolve-DnsName $HostToResolve -ErrorAction SilentlyContinue | select -First 1

if ($ipResult) {
    return $ipResult.IpAddress
}

$Server = Get-ServerHost

$result = Invoke-WebRequest -Uri "http://$Server/dns?host=$HostToResolve" -ErrorAction SilentlyContinue

if ($result) {
    $response = $result | ConvertFrom-Json
    
    if ($response.error) {
        Write-Error "Failed to resolve $HostToResolve. Server error: $($response.error)"
        return
    }
    
    if (-not $response.ip) {
        Write-Error "Invalid server response: $result"
        return
    }
    
    Add-HostIp $response.host $response.ip
    
    return $response.ip
}
else {
    Write-Error "Couldn't resolve given host ($HostToResolve). `n$result"
}

