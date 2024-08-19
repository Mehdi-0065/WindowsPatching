function Schedule_Task {
    <#
    .SYNOPSIS
        Adds a task to the schedule.
    
    .DESCRIPTION
        The Schedule_Task function adds a task to the schedule on the specified computer. The task is scheduled to run at the specified time.
        The Schedule_Task cmdlet Adds a task to the schedule on the specified computer. The task is scheduled to run at the specified time.

        .PARAMETER hostname
            The name of the computer on which to schedule the task. If not specified, defaults to localhost.
        
        .PARAMETER TaskName
            The name of the task to be scheduled.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$hostname,
        [Parameter(Mandatory = $true)]
        [string]$triggerTime,
        [Parameter(Mandatory = $true)]
        [string]$taskName,
        [Parameter(Mandatory = $true)]
        [string]$filename
    )
    
    $credentials = $script:Credential
    $SourceFile = "$env:Main_PatchingFiles_Path\$filename" #Join-Path $Main_Patching_Path -ChildPath $filename -Verbose
    
    $destinationPath = "\\$hostname\c$\temp\PatchFiles"
    
    
    $scriptPath = Join-Path "c:\temp\PatchFiles" -ChildPath $filename
    if (-not (Test-Path $destinationPath -PathType Container)) {
        New-Item -Path $destinationPath -ItemType Directory -Verbose
    }
    else {
        write-host "the path exist"
    }
    try {
        Copy-Item -Path $SourceFile -Destination $destinationPath -Force -Verbose -ErrorAction Stop 
        Write-Log -Message "Script copied to $hostname" -Level "Info" 
        write-host "$hostname : $sourcefile is copied to $destinationPath" -ForegroundColor green
    }
    catch {
        Write-Error "Error occurred while copying the script to $hostname"
        Write-Log -Message "Error occurred while copying the script to $hostname" -Level "Error"
        exit
      
        
    }
    # Schedule task parameters
    $delayMinutes = 5
    
    # Calculate the trigger time
    
    
    # Create the trigger for the scheduled task
    $trigger = New-ScheduledTaskTrigger -Once -At $triggerTime -Verbose
    
    # Create the action to run the PowerShell script
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $scriptPath" -Verbose
          
    # Register the scheduled task on the remote computer
    try {
        Invoke-Command -ComputerName $hostname -Credential $credentials -ScriptBlock {
            param ($taskName, $trigger, $action)
    
            #$principal = New-ScheduledTaskPrincipal -UserId $using:credentials.UserName -LogonType S4U
            $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

            Register-ScheduledTask -Action $using:action -Trigger $using:trigger -TaskName $using:taskName -Principal $principal -Verbose
        } -ArgumentList $taskName, $trigger, $action
        Write-Log -Message "Scheduled task registered on $hostname" -Level "Info" -LogLocation "Shared"
    }
    catch {
        Write-Error "Error occurred while registering the scheduled task on $hostname"
        Write-Log -Message "Error occurred while registering the scheduled task on $hostname" -Level "Error"
        exit
        
    }

}

<#

$hostname = "pwakvarocol01"
$filename = "WindowsPatch-Prod.ps1"
$taskName = "test-Patching-V4"
$triggerTime = "5/2/2024 15:59:00 PM"


Schedule_Task -hostname $hostname -triggerTime $triggerTime -taskName $taskName -filename $filename

#$cred = Get-Credential
Invoke-Command -ComputerName $hostname -Credential $cred -ScriptBlock {
        
    c:\temp\PatchFiles\test.ps1
}


#>
    
    