function Update-Server {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        
        [System.Management.Automation.PSCredential]$Credential = $env:Credential
        
    )
    
    begin {

        [string]$CurrentMonth = (Get-Date).ToString("MMMM") , # Name of the patch list file. Default is the current month
        [string]$patchList_Path = "$env:Main_Patching_Path\$CurrentMonth\$CurrentMonth.csv" # Path to the patch list file. Default is the main patch list file
        #$HostName = "pwakpshapp01"
        try {
            $server = import-csv -Path $patchList_Path | Where-Object { $_.hostname -eq $HostName -and $_.reboottime -like "*" }
            $primary_contact = $server.primary_contact
            $secondary_contact = $server.secondary_contact
            $group_email = $server.group_email
            $patch_window = $server.patch_window
            $next_patch_date = $server.next_patch_date
            $rebootTime = $server.rebootTime
        }
        catch {
            Write-Log -Message "Error occurred while importing the patch list file" -Level "Error"
            Write-Error -Message "$hostname is NOT found on the patching list"
            exit
        }

        $headers_get = @{
            Authorization = "Bearer $env:accessToken_GET"
        }
        
        #header for updating the last patch date and reboot time in APEX
        $headers_put = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $env:AccessToken_Put"
        }

        Write-Log -Message "Starting schedulling patching process for $hostname" -Level "info"

        
    }
    
    process {
        
        $Script:credential 
        $filename = "WindowsPatch-Prod.ps1"
        $taskName = "Monthly_Patching"

        $triggerTime = ([datetime]$rebootTime).AddHours(-4)
        
        try {
            Schedule_Task -hostname $hostname -triggerTime $triggerTime -taskName $taskName -filename $filename -Verbose
            write-log -Message "$hostname : a task has been scheduled" -Level "Info"
            Write-Host "$hostname : a task has been scheduled"
        }
        catch {
            Write-Error "Error occurred while scheduling the task"
            Write-Log -Message "Error occurred while scheduling the task" -Level "Error"
            Send-email -subject "$hostname : failed to schedule a patching task" 
            exit
        }

        
        # scheduling Nagios Downtime 
        try {
            Nagios_Schedule_downtime -length 2100 -hostname $hostname -start_downtime $rebootTime
            write-log -Message "$hostname : a downtime has been scheduled in Nagios"
            write-host "$hostname : a downtime has been scheduled in Nagios"

        }
        catch {
            Write-Error "Error occurred while scheduling Nagios downtime"
            Write-Log -Message "Error occurred while scheduling Nagios downtime" -Level "Error"
            Send-email -subject "$hostname : failed to schedule a Nagios downtime" 
            
        }

        $contacts = @()
        if ($primary_contact -ne "") {
            $contacts += $primary_contact
        }
        if ($secondary_contact -ne "") {
            $contacts += $secondary_contact
        }
        if ($group_email -ne "") {
            $contacts += $group_email
        }
        try {
            send-patch-notification Send-Patch-Notification -contacts_grouped $contacts
            write-log -Message "$hostname : Contacts have been notified"
            write-host "$hostname : Contacts have been notified"
        }
        catch {
            Write-Error "Error occurred while sending patch notification"
            Write-Log -Message "Error occurred while sending patch notification" -Level "Error"
            Send-email -subject "$hostname : failed to send patch notification" 
            
        }
        
        
        
    }
    
    end {
        
    }
}