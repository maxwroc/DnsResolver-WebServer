<#
    .SYNOPSIS
    Helper script for running server.

    .DESCRIPTION
    This script allows to run the server in background job (unblocking current command line), stop the background server job and restart server when changes are detected.

    .EXAMPLE
    server-runner.ps1 -RunInBackground -Watch
    # Runs server in background mode and watches server.ps1 file for changes.

    .EXAMPLE
    server-runner.ps1 -Url "http://localhost:8084/" -Stop
    # Stops server listening on http://localhost:8084/
#>
Param(
    [string]$Url = "http://localhost:8084/",
    [switch]$RunInBackground = $false,
    [switch]$Stop = $null,
    [switch]$Watch = $false
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
Write-Host "Listening at $Url..."

if ($Watch) {
    $fsw = New-Object IO.FileSystemWatcher $PSScriptRoot, "server.ps1" -Property @{IncludeSubdirectories = $false;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}

    Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action {
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        Write-Host "The file '$name' was $changeType at $timeStamp $jobName" -fore white
    }
}

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

                if ($Watch) {
                    Unregister-Event FileChanged
                }

                break
            }
        }

        Receive-Job $serverJob.Id
        Start-Sleep -s 1
    }
}
else {
    Write-Host "To get server logs use the following cmd: Receive-Job $($serverJob.Id))"
}