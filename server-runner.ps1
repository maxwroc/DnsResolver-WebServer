Param(
    [string]$Url = "http://localhost:8084/",
    [switch]$RunInBackground = $false,
    [switch]$Stop = $null
)

Function Stop-Server {
    Param($serverJob, $url)
    Write-Host "Terminating..."
            
    Write-Host "    Sending termination request in 1s"
    # To break server loop we need to issue last web request
    $terminatingJob = Start-Job -ArgumentList $url -ScriptBlock { 
        Param($Url)
        Start-Sleep -s 1
        Invoke-WebRequest -Uri $Url -ErrorAction SilentlyContinue
    }
    
    Write-Host "    Stopping job"
    $serverJob | Stop-Job 
    $terminatingJob | Stop-Job
    
    Remove-Job $serverJob
    Remove-Job $terminatingJob
    
    Write-Host "Done"
}

$jobName = "WebService:$Url"

if ($Stop) {
    if (-not $Url) {
        Write-Error "Missing Url parameter"
        return
    }
    
    $job = Get-Job $jobName -ErrorAction SilentlyContinue
    
    if (-not $job) {
        Write-Error "Cannot find server job: $jobName"
        return
    }
    
    Stop-Server $job $Url
    return
}

$serverJob = Start-Job -FilePath "$PSScriptRoot\server.ps1" -ArgumentList $Url -Name $jobName
Write-Host "To get server logs use the following cmd: Receive-Job $($serverJob.Id))"
Write-Host "Listening at $Url..."

if (-not $RunInBackground) {
    Write-Host "Press Ctrl+C to terminate" 
     
    [console]::TreatControlCAsInput = $true

    # Wait for it all to complete
    while ($serverJob.State -eq "Running")
    {
         if ([console]::KeyAvailable) {
            $key = [system.console]::readkey($true)
            if (($key.modifiers -band [consolemodifiers]"control") -and ($key.key -eq "C"))
            {
                Stop-Server $serverJob $url
                break
            }
        }
        
        Receive-Job $serverJob.Id
        Start-Sleep -s 1
    } 
}