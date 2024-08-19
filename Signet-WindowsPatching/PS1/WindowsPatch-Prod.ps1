<#
.Synopsis 
    This is a script for patching windows servers based on a patching spreadsheet
.DESCRIPTION 
    The script is designed to be executed monthly on all of windows servers and patch them and reboot them at the exact time that provide by a spreadsheet from \\isilon01.jewels.com\Archives\WindowsPatching\
    the script is running every day on servers and as soon as the server name is uploaded in the spreadsheet the server start patching
    after reboot we have another script that run and send us a report of the staus of server
    
.NOTES 
    Created by: Mehdi Rezaei, mehdi.rezaei@signetjewelers.com
    Modified:   04/12/2024 
    version : 2.0            
    Change Log: 
    * Release to production
   To Do: 
    * 
.PARAMETER [empty] 
    * NA
.EXAMPLE [empty]
    Write-Log -Message 'Beginning New Account Creation Process Execution' -Level Info
.LINK 
    Write-Log Original Code Found Here...
    https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
#>

#Requires -RunAsAdministrator


#Install-Module -Name PSWindowsUpdate
#Import-Module PSWindowsUpdate

##############################Functions##############################################
function RemainPatches {
    <#
    .SYNOPSIS
        Get the remaining patches that are not installed on the server.
    .DESCRIPTION
        This function will return the remaining patches that are not installed on the server.

    #>
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateupdateSearcher()
    $Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)
    $remainUpdates = $Updates | Select-Object Title
    return $remainUpdates
}
RemainPatches

function Send_Email {
    <#
    .SYNOPSIS
        Send an email to the specified recipients.
    .DESCRIPTION
        This function sends an email to the specified recipients with the specified subject and body.

    .PARAMETER SMTPServer
        It is using smtp-akr.jewels.com by default and it will use smtp-c1.jewels.com is Akron SMTP is not working for the server.
    .PARAMETER subject
        The subject of the email. it is ""WARNING: $env:computername is failing to be patched"" by default
    .PARAMETER body
        The body of the email. it is ""$env:computername is seeing an issue during patching. please check it and make sure it is patching""
    .PARAMETER to
        The email address of the recipient. it is "mehdi.rezaei@signetjewelers.com" by default
    .PARAMETER cc
        The email address of the cc. it is "" by default
    .PARAMETER attachment
        The attachment of the email. it is "" by default
    .EXAMPLE
        Send_Email -subject "Your computer is not patched" -body "Your computer is not patched" -to "youremail@gmail.com" -cc "test@signetjewelrs.com" -attachment "C:\Temp\ADMEmails\MFA-01.png"

    #>
    [CmdletBinding()]
    param (
        [string] $Subject = "WARNING: $env:computername is failing to be patched",
        [System.Object] $body = "$env:computername is seeing an issue during patching. please check it and make sure it is patching",
        [System.Array]$to = "mehdi.rezaei@signetjewelers.com" ,
        [string]$cc = "",
        [string]$attachment = ""
    )

    $mailParams = @{
        SmtpServer = 'smtp-akr.jewels.com'
        Port       = '25' #'587' # or '25' if not using TLS
        UseSSL     = $false #$true ## or not if using non-TLS
        From       = 'no-reply@signetjewelers.com'
        #    To                         = 'Brian.Davis-1@SignetJewelers.com'
        To         = $to
        Subject    = $Subject
        #Priority                   = $priority
        BodyAsHtml = $true
        Body       = $body
    }
    if ($Attachment ) {
        $mailParams['Attachments'] = $Attachment
    }#,'C:\Temp\ADMEmails\MFA-01.png','C:\Temp\ADMEmails\MFA-02.png','C:\Temp\ADMEmails\MFA-03.png','C:\Temp\ADMEmails\MFA-04.png','C:\Temp\ADMEmails\MFA-05.png','C:\Temp\ADMEmails\MFA-06.png','C:\Temp\ADMEmails\MFA-07.png','C:\Temp\ADMEmails\MFA-08.png','C:\Temp\ADMEmails\MFA-09.png'
    #    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
    if ($cc) {
        $mailParams['CC'] = $cc
    }
    #CC                         = 'mehdi.rezaei@signetjewelers.com'
   
    
    try {
        Send-MailMessage @mailParams -Verbose
    }
    catch {
        $mailParams = @{
            SmtpServer = 'smtp-C1.jewels.com'
            Port       = '25' #'587' # or '25' if not using TLS
            UseSSL     = $false #$true ## or not if using non-TLS
            From       = 'no-reply@signetjewelers.com'
            #    To                         = 'Brian.Davis-1@SignetJewelers.com'
            To         = $to
            Subject    = $Subject
            #Priority                   = $priority
            BodyAsHtml = $true
            Body       = $body
        }
        if ($Attachment ) {
            $mailParams['Attachments'] = $Attachment
        }#,'C:\Temp\ADMEmails\MFA-01.png','C:\Temp\ADMEmails\MFA-02.png','C:\Temp\ADMEmails\MFA-03.png','C:\Temp\ADMEmails\MFA-04.png','C:\Temp\ADMEmails\MFA-05.png','C:\Temp\ADMEmails\MFA-06.png','C:\Temp\ADMEmails\MFA-07.png','C:\Temp\ADMEmails\MFA-08.png','C:\Temp\ADMEmails\MFA-09.png'
        #    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
        if ($cc) {
            $mailParams['CC'] = $cc
        }
        Send-MailMessage @mailParams -Verbose
    }
    
}

<#function Get-EmailAddress {
    param (
        [Parameter(Mandatory = $true)]
        [string]$displayName
    )
   
    if ($displayName -match "@") {
        return $displayName
    }
    else {
        # List of domains to search
        $domains = @("jewels.local", "jewels.com", "irving.zalecorp.com")

        # Iterate through the domains and search for the user
        foreach ($domain in $domains) {
            try {
                $users = Get-ADUser -Filter { DisplayName -like $displayName } -Server $domain -ErrorAction Stop -Properties emailaddress | Select-Object emailaddress
                foreach ($user in $users) {

                
                    if (($user.emailaddress -match "@signetjewelers.com") -and ($user.emailaddress -notlike "adm-*")) {
                        return $user.EmailAddress
                        break
                    }
                }
           
            }
            catch {
                Write-Host "An error occurred while searching in $domain : $($_.Exception.Message)"
            }
        }
    }
}
#>

function Get-Contacts-Email {
            
    <#
    .SYNOPSIS
        generate an array of email address for each contact group
    .DESCRIPTION
        we send primary contact display name, secondary contact display name and group email address to this function and it will return an array of email address
    .NOTES
        if there is no contact for a group, it will send an email to the default email address
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        get-contact-email -primary_contact "Rezaei, Mehdi" -secondary_contact "Rexroat, Jim" -group_email "sysops-dl@signetjewelers.com"
    #>
    [CmdletBinding()]
    param (
            
        [string]$primary_contact,
        [string]$secondary_contact,
        [string]$group_email
            
    )
        
    begin {
            
    }
        
    process {
        $to_default = @()
        if ($primary_contact -ne "") {
            $to_default += $primary_contact
            if ($secondary_contact -ne "" ) {
                write-host "test"
                $secondary = $secondary_contact
                $to_default += $secondary
            }
            else {
                $secondary = $null
            }
            if ($group_email -ne "") {
                    
                $to_default += $group_email
            }
            else {
                     
            
            }
               
        }
        
        elseif ($secondary_contact -ne "") {
            $to_default += $secondary_contact
            if ($group_email -ne "") {
                    
                $to_default += $group_email
            }
        }
        elseif ($group_email -ne "") {
            $to_default += $group_email
        }
        else {
            Write-Error "there is no contact for this group"
        }
            
    }
        
    end {
        return $to_default
    }
}

function GetCorrectPath {
    param (
        [string]$PatchPath1,
        [string]$PatchPath2,
        [string]$PatchPath3
    )

    $OrgPatchFilesPath = $null

    if ([System.IO.Directory]::Exists($PatchPath1)) {
        $OrgPatchFilesPath = $PatchPath1
        Write-Host "Connecting to $OrgPatchFilesPath"
    }
    elseif ([System.IO.Directory]::Exists($PatchPath2)) {
        $OrgPatchFilesPath = $PatchPath2
        Write-Host "Connecting to $OrgPatchFilesPath"
        $env:COMPUTERNAME | Out-File  "$OrgPatchFilesPath\NoAccessing-to-Jewelscom.txt" -Append
    }
    elseif ([System.IO.Directory]::Exists($PatchPath3)) {
        $OrgPatchFilesPath = $PatchPath3
        Write-Host "Connecting to $OrgPatchFilesPath"
        $env:COMPUTERNAME | Out-File  "$OrgPatchFilesPath\NoAccessing-to-Jewelscom.txt" -Append
    }
    else {
        Write-Host "this host doesn't have access to any resources" -ForegroundColor Red
        Start-Sleep -Seconds 2
        Send_Email
    }
    return $OrgPatchFilesPath
}

function Write-Log { 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 

        [Parameter(Mandatory = $false)]
        [ValidateSet("Local", "Shared")]
        [string[]]$LogLocation = @("Local", "Shared"),

        [Parameter(Mandatory = $false)] 
        [Alias('LogPath')] 
        [string]$Path, 
         
        [Parameter(Mandatory = $false)] 
        [ValidateSet("Critical", "Error", "Warn", "Info")] 
        [string]$Level = "Info", 
         
        [Parameter(Mandatory = $false)] 
        [switch]$NoClobber 
    ) 

    Begin { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue' 
        
        # Check if LogLocation is specified, if not, log to both local and shared paths
        if (-not $Path) {
            $Path = "$LocalFilesPath\Running-process.log"
        }
    } 
    Process { 
        foreach ($Location in $LogLocation) {
            # Set default log file path based on the selected location
            if ($Location -eq "Local") {
                $Path = "$LocalFilesPath\Running-process.log"
                
            }
            elseif ($Location -eq "Shared") {
                # Set the shared location path
                $Path = $LogFile
                
            }
             
            # If the file already exists and NoClobber was specified, do not write to the log. 
            if ((Test-Path $Path) -AND $NoClobber) { 
                Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
                Continue
            } 
            
            # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
            elseif (!(Test-Path $Path)) { 
                Write-Verbose "Creating $Path." 
                $NewLogFile = New-Item $Path -Force -ItemType File 
            } 

            # Format Date for our Log File 
            $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 

            # Write message to error, warning, or verbose pipeline and specify $LevelText 
            switch ($Level) { 
                'Critical' {
                    Write-Error $Message
                    $LevelText = 'Critical'
                }
                'Error' { 
                    Write-Error $Message 
                    $LevelText = 'Error' 
                } 
                'Warn' { 
                    Write-Warning $Message 
                    $LevelText = 'Warning' 
                } 
                'Info' { 
                    Write-Verbose $Message 
                    $LevelText = 'Informational' 
                } 
            } 
            # Retry logic if the file is being used by another process
            $retryCount = 0
            while ($retryCount -lt 10) {
                # You can adjust the maximum number of retries
                try {
                    
                    # Write log entry to $Path 
                    "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append -ErrorAction Stop
                    
                   
                    break  # Exit the loop if write operation succeeds
                }
                catch [System.IO.IOException] {
                    if ($_.Exception.Message -match "The process cannot access the file") {
                        Write-Warning "Log file $Path is being used by another process. Retrying in 1 second..."
                        Start-Sleep -Seconds 1
                        $retryCount++
                    }
                    else {
                        throw  # Rethrow the exception if it's not the expected error
                    }
                }
            }
        }

    } 
    End { 
    } 
}

function GetServicesReport {
    param([string]$path = [string]$serviceslogs)
    Get-Service | export-csv -Path $path -NoTypeInformation 

}

#get windows version 

function Get-WindowsVersion {
    <#
    .SYNOPSIS
        Get the Windows version of the computer.
    .DESCRIPTION
        This function will return an object containing the Windows version of the computer.
    .EXAMPLE
        Get-WindowsVersion
        
        Major Version   : 1
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true
        )]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
	
	
    Begin {
        $Table = New-Object System.Data.DataTable
        $Table.Columns.AddRange(@("ComputerName", "Windows Edition", "Version", "OS Build"))
    }
    Process {
        Foreach ($Computer in $ComputerName) {
            $Code = {
                $ProductName = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName).ProductName
                Try {
                    $Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction Stop).ReleaseID
                }
                Catch {
                    $Version = "N/A"
                }
                $CurrentBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild).CurrentBuild
                $UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name UBR).UBR
                $OSVersion = $CurrentBuild + "." + $UBR
				
                $TempTable = New-Object System.Data.DataTable
                $TempTable.Columns.AddRange(@("ComputerName", "Windows Edition", "Version", "OS Build"))
                [void]$TempTable.Rows.Add($env:COMPUTERNAME, $ProductName, $Version, $OSVersion)
				
                Return $TempTable
            }
			
            If ($Computer -eq $env:COMPUTERNAME) {
                $Result = Invoke-Command -ScriptBlock $Code
                [void]$Table.Rows.Add($Result.Computername, $Result.'Windows Edition', $Result.Version, $Result.'OS Build')
            }
            Else {
                Try {
                    $Result = Invoke-Command -ComputerName $Computer -ScriptBlock $Code -ErrorAction Stop
                    [void]$Table.Rows.Add($Result.Computername, $Result.'Windows Edition', $Result.Version, $Result.'OS Build')
                }
                Catch {
                    $_
                }
            }
			
        }
		
    }
    End {
        Return $Table
    }
}

function ExportToCSV {
    param($computerName, $domain, $LastReboot, $StartDate, $FinishDate, $InstalledKB, $NotInstalledKB, $RebootStatus, $wmistatus)
                
    $Log = @{
        "ComputerName"   = $ComputerName
        "Domain"         = $Domain
        "LastReboot"     = $Lastreboot
        "StartDate"      = $Startdate
        "EndDate"        = $FinishDate
        "InstalledKB"    = $InstalledKB
        "NotInstalledKB" = $NotInstalledKB
        "RebootStatus"   = $RebootStatus
        
    }
    New-Object PSObject -Property $log | Export-Csv $ExportDetailofServer -NoTypeInformation -Append -force
    Write-Log -Message "the server details are exported to $ExportDetailofServer" -Level Info
}

function Notify_owners {
    <#
    .SYNOPSIS
        Notify the server owners about the patching process.
    .DESCRIPTION
        This function will send an email to the server owners about the patching process.
    .EXAMPLE
        Notify_owners
    #>
    
    write-log -Message "the contacts are $contacts" -Level Info
    $subject = "Notification: Server Patching and Reboot - $computername"

    # Define the variables

    $MaintenanceDate, $MaintenanceTime = $server.Reboot -split ' '
    $ContactEmail = "SysOpsDL@signetjewelers.com"
    $patchWindow = $server.'patch_window'

    # Create the HTML body
    $HTMLBody = @"
<html>
<body>
<p>Dear IT Team,</p>
<p>Scheduled patching and rebooting are planned for server $computername tonight. The server will be rebooted on $MaintenanceDate at $MaintenanceTime according to the scheduled patch window. This is a necessary step to ensure enhanced security and performance.</p>
<p>Expect minimal disruption, and the server should be back online within approximately 10 to 30 minutes. During this maintenance, Nagios Monitoring will be temporarily disabled, starting 5 minutes before the reboot and continuing until 30 minutes after the completion of the reboot process.</p>
<p>If you have any concerns, please feel free to reach out to us at <a href="mailto:$ContactEmail">$ContactEmail</a>.</p>
<p>Thank you for your cooperation.</p>
<br>
<p>Best Regards,</p>
</body>
</html>
"@
    try {
        Send_Email -to $contacts -subject $subject -body $HTMLBody -cc "mehdi.rezaei@signetjewelers.com" -ErrorAction SilentlyContinue
        Write-Log -Message "the email has been sent to Contacts of $env:computername" -Level Info
        Write-host "The email has been sent to Contacts of $env:computername"
    }
    catch {
        Write-Warning $_.Exception.Message
        Write-Log -Message "the email couldn't be sent to Contacts of $env:computername" -Level Error  
        Write-Host "The email couldn't be sent to Contacts of $env:computername" -ForegroundColor Red
    }
}

function Remain_patches {
    # First script: Get installed hotfixes in the current month
    $currentDate = Get-Date
    $firstDayOfMonth = Get-Date -Year $currentDate.Year -Month $currentDate.Month -Day 1
    $installedHotfixes = Get-HotFix | Where-Object { $_.InstalledOn -ge $firstDayOfMonth }

    # Second script: Get available updates
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)

    # Extract the Titles of the available updates
    $availableUpdateTitles = $Updates | Select-Object -ExpandProperty Title

    # Compare the results
    $installedHotfixTitles = $installedHotfixes | Select-Object -ExpandProperty Description
    $updatesNotInstalledInCurrentMonth = $availableUpdateTitles | Where-Object { $installedHotfixTitles -notcontains $_ }

    # Display the updates that are not installed in the current month
    if ($updatesNotInstalledInCurrentMonth.Count -eq 0) {
        Write-Host "No updates found that are not installed in the current month."
    }
    else {
        Write-Host "Updates not installed in the current month:"
        $updatesNotInstalledInCurrentMonth
        return $updatesNotInstalledInCurrentMonth
    }

}

Write-Log "Start patching" -Level Info -LogLocation Local
#set paths
$currentDate = Get-Date

# Format the date to display the full month name
$currentMonth = $currentDate.ToString("MMMM")
#set paths
$Path1 = "\\isilon01.jewels.com\patching$\Windows"
$Path2 = "\\isilon01.jewels.local\ISO\Patching\Windows"
$Path3 = "\\zlvdalmgm01p\Patching\Windows"
try {
    $OrgPatchFilesPath = GetCorrectPath -PatchPath1 $Path1 -PatchPath2 $Path2 -PatchPath3 $Path3
}
catch {
    Write-Log -Message "the server doesn't have access to any resources" -Level Error
    Write-Host "the server doesn't have access to any resources" -ForegroundColor Red
    exit
}


$TranscriptPath = "$OrgPatchFilesPath\Logs\$currentMonth" + "\" + $env:USERNAME + "_Transcript_" + (Get-Date).Date.ToShortDateString().Replace("/", "_") + ".txt"
$ServerListPath = "$OrgPatchFilesPath\PatchList\$currentMonth.csv"
#$PatchLogPathCSV = $OrgPatchFilesPath + "PatchingLogFile.csv"
$OldHotFixPath = "$OrgPatchFilesPath\Logs\$currentMonth" + "_old_hot_fixes.txt"
$LogFile = "$OrgPatchFilesPath\Logs\$currentMonth" + "_Patching_process.log"
$LocalFilesPath = "c:\temp\PatchFiles"
$ExportDetailofServer = "$OrgPatchFilesPath\Logs\$currentmonth" + "_Servers-Details.csv"
$comparescript = "$OrgPatchFilesPath\PatchFiles\compareservices.ps1"
$localCompareScript = "$LocalFilesPath\compareservices.ps1"

$serviceslogs = "$LocalFilesPath\ServicesReport.csv"


#GET detail of the server

$ComputerName = $env:computername
$domain = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select-Object Domain
$domain = $domain.domain
$Startdate = Get-Date
$lastreboot = Get-CimInstance -ClassName win32_operatingsystem | Select-Object lastbootuptime
$lastreboot = $lastreboot.lastbootuptime
$WMI = Get-WmiObject -query "SELECT * FROM Win32_OperatingSystem" -ErrorAction SilentlyContinue


#PS transcript file for troubleshooting (1 transcript file per day)
Start-Transcript $TranscriptPath -Append
Write-Log -Message "starting patching $env:computername on $currentMonth" -Level Info 
Write-Log -Message "$OrgPatchFilesPath is being used for the patching process by $env:computername" -Level Info 
write-log -Message "Transcription process is being started and the file is saved in $TranscriptPath" -Level Info
Write-Log -Message "Computer name : $env:computername Domain : $domain   Last Reboot: $lastreboot" -Level Info



#this line will generate a list of services running on the box before reboot
try {
    GetServicesReport
    Write-Host "The services list has been created and stored at $serviceslogs" -ForegroundColor Green 
    Write-Log -Message "the services list has been created and store at  : $serviceslogs" -Level Info  
 
}
catch {
    Write-Log -Message "the services list couldn't be created" -Level Error
    Write-Host "The services list couldn't be created" -ForegroundColor Red
}





#Export to CSV file



#write-host "When does the host need to restart? Type the time in the appropriate format : 09/06/2022 00:05 .type ""NO"" if you do not wish to reset the host. " -ForegroundColor Green



#check if PatchFiles folder is exist 
if ([System.IO.Directory]::Exists($LocalFilesPath)) {
    Set-Location -Path $LocalFilesPath
}
else {
    New-Item -Path "c:\temp" -Name "PatchFiles" -ItemType Directory
    Set-Location -Path $LocalFilesPath
    Write-Log -Message "PatchFiles folder is created in $env:computername" -Level Info -LogLocation Local

}

Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
Write-host " -------------------Checking CSV file for find the reboot time ------------------" -BackgroundColor Magenta
Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta



# check what files location the server has access

# import data from server list csv file and get the exact reboot time for each server



if ($serverList = import-csv "$ServerListPath" | Where-Object Hostname -EQ $env:ComputerName) {
    Write-Log -Message "the server name is retriving from $ServerListPath" -Level Info 
    Write-host "the server name is retriving from $ServerListPath" -BackgroundColor Green

    #it will check if there is any duplicate hostname for this host 
    $server = $serverList[0]
    if ($server.rebootTime -eq "") {
        write-log -Message "$ComputerName is listed in the server list but it doesn't have any reboot time" -Level Error
        Write-Host "$ComputerName is listed in the server list but it doesn't have any reboot time" -ForegroundColor Red
        Send_Email -Subject "$ComputerName is listed in the server list but it doesn't have any reboot time"
        break

    }
    else {

        $timeinput = $server.reboottime
        $reboot = get-date $timeinput

        write-host "the server is going to reboot on $timeinput" -BackgroundColor Red

        Write-Log -Message "$computername is exist in $ServerListPath and it will be reboooted on $timeinput" -Level Info
    }
    $contacts = @()

    foreach ($Contact in $serverList) {
        $primary_contact = $contact.PRIMARY_CONTACT 
        $secondary_contact = $contact.SECONDARY_CONTACT 
        $group_Email = $contact.GROUP_EMAIL
        $contacts += Get-Contacts-Email -primary_contact $primary_contact -secondary_contact $secondary_contact -group_email $group_Email
    
    }
    Write-Log -Message "the contacts for $ComputerName are $contacts" -Level Info
    write-host " below contacts will be notified about the server patching process:" -ForegroundColor Yellow
    $contacts
    

    if ($contacts) {
        # send email notification with the reboot time of the serve
        #Notify_owners will send an email to all of owner os this servers and will let them know about the reboot time of the server
        try {
            Notify_owners
            Write-Log -Message "the email has been sent to Contacts of $env:computername" -Level Info
            Write-host "The email has been sent to Contacts of $env:computername"
        }
        catch {
            Write-Warning $_.Exception.Message
            Write-Log -Message "the email couldn't be sent to Contacts of $env:computername" -Level Error  
            Write-Host "The email couldn't be sent to Contacts of $env:computername" -ForegroundColor Red
        }
        
        
    }
    else {
        #if the server doesn't have any contacts, it will send an email to the default email address which is defined in the variable $Default_email
        Send_Email -Subject "$computername  doesn't have any contacts"
        Write-Error "$computername doesn't have any contacts"
        Write-Log -Message "$computername doesn't have any contacts" -Level Error
    }
}
else {
    # if the server is not listed in the server list, it will send an email to the default email address which is defined in the variable $Default_email
    $email_subject = "$subject_default - the server is not listed in $serverListPath"
    
    Send_Email  -Subject $email_subject
    
    Write-Error "We are unable to patch this server since it is not listed in the server patch list. Please include the server in the list of servers on $ServerListPath and try again" 
    Write-Log -Message "$computername does not exist in $ServerListPath" -Level Info
    $break = Read-Host "If we carry on, the server will reboot as soon as the patching is complete. Are you certain to go on? Yes/No"
    if ($break -eq "yes") {
        Write-Warning "Immediately following the completion of the patching, the server will reboot."
    }
    else {
        #Start-Sleep -Seconds 20000
        break 
    }
}


# Get the Windows version of the computer and store it into a variable called $OSVersion

$OSVersion = Get-WindowsVersion
Write-Log -Message "$computername is $osversion" -Level Info

if ($OSVersion.'Windows Edition' -like "*2012 R2*") {

    $pathPatchFiles = "$OrgPatchFilesPath\patchfiles\$currentMonth\2012"
}
elseif ($OSVersion.'Windows Edition' -like "*2016*") { 

    $pathPatchFiles = "$OrgPatchFilesPath\patchfiles\$currentMonth\2016"
}
elseif ($OSVersion.'Windows Edition' -like "*2019*") { 

    $pathPatchFiles = "$OrgPatchFilesPath\patchfiles\$currentMonth\2019"
}

else {
    $pathPatchFiles = $null
    Write-Host "there is no patch file for " $OSVersion.'Windows Edition'". you need to reboot the host manually at" $server.'reboot' -ForegroundColor Red
    write-log -Message "there is no patch file for " $OSVersion.'Windows Edition'". you need to reboot the host manually at" $server.'reboot' -Level Error
    Send_Email -Subject "Error: $env:computername there is no patch file for " $OSVersion.'Windows Edition'". you need to reboot the host manually at" $server.'reboot'
    break
}


#remove all of old patch files from c:\temp\patchfiles folder.
try {

    Remove-Item "$LocalFilesPath\*.msu" -Verbose -Force -ErrorAction SilentlyContinue
    Remove-Item "$LocalFilesPath\*.exe" -Verbose -Force -ErrorAction SilentlyContinue
    Remove-Item "$serviceslogs" -Verbose -Force -ErrorAction SilentlyContinue 
}
catch {
    
}
Start-Sleep 10
Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
Write-host " ----------Copying patch files from shared drive to c:\temp\patchfiles ----------" -BackgroundColor Magenta
Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta

try {
    Copy-Item -Path "$pathPatchFiles\*" -Destination $LocalFilesPath -Recurse  -ErrorAction SilentlyContinue
    Write-Log -Message "the related MSU files are copying to $computername" -Level Info
}
catch {
    Write-Error "the patch files couldn't be copied to $computername"
    Send_Email -Subject "Error: $env:computername the patch files couldn't be copied to $computername"
    Write-Log -Message "the patch files couldn't be copied to $computername" -Level Error
    break
}



Start-Sleep -Seconds 60

# Run this script / ISE as administrator!
# Update these variables


# Old hotfix list
#Get-HotFix > "$LocalFilesPath\old_hotfix_list.txt"

# Get all updates
$Updates = Get-ChildItem -Path $LocalFilesPath -Recurse | Where-Object { $_.Name -like "*msu*" }
# Iterate through each update
$InstalledKB = $null
$notInstalledKB = $null

Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
Write-host " -----------------------------installing patch files-----------------------------" -BackgroundColor Magenta
Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta


ForEach ($update in $Updates) {

    # Get the full file path to the update
    $UpdateFilePath = $update.FullName
    Write-Log -Message "$updatefilepath is installing on $computername" -Level Info
    $KB = $updatefilepath.split("-")[1]
    # Logging
    write-host "Installing update $($update.BaseName)"

    # Install update - use start-process -wait so it doesnt launch the next installation until its done
    try {
        Start-Process -wait wusa -ArgumentList "/update $UpdateFilePath", "/quiet", "/norestart" -ErrorAction Stop
        write-log -Message "the $KB has been installed on $computername" -Level Info
        $installedKB = $InstalledKB + ", $KB" 
        write-host "---------$UpdateFilePath has been installed successfully----------" -ForegroundColor Green
        
    }
    catch {
        Write-Host "$KB couldn't be installed" -ForegroundColor Red
        Write-Log -Message "$KB couldn't be installed on $computername" -Level Error
        $NotinstalledKB = $NotInstalledKB + ", $KB" 
    }
}
$EXEs = Get-ChildItem -Path $LocalFilesPath -Recurse | Where-Object { $_.Name -like "*exe*" }
foreach ($EXE in $EXEs) {

    try {
        Start-Process -FilePath $($EXE.name) -ArgumentList "/Q" -Wait -ErrorAction SilentlyContinue -NoNewWindow
    }
    catch {
        Write-Error "$($EXE.name) files couldn't be installed" -ForegroundColor Re
        Write-Log -Message "$($EXE.name) files couldn't be installed on $computername" -Level Error
    
    }
}
# Get the current date
$currentDate = Get-Date

# Calculate the first day of the current month
$firstDayOfMonth = Get-Date -Day 1 -Month $currentDate.Month -Year $currentDate.Year

# Retrieve hotfixes installed within the current month
$hotfixes = Get-HotFix | Where-Object { $_.InstalledOn -ge $firstDayOfMonth }

# Display the list of hotfixes
$hotfixes


if (!$InstalledKB) {
    Write-Error "Non of patch files have been installed"
    Send_Email -Subject "Error: $env:computername Non of patch files have been installed"
    write-log -Message "Non of patch files have been installed on $computername" -Level Error
    break
}
else {
    Write-Information "$InstalledKB have been installed"
    Write-Log -Message "$InstalledKB have been installed on $computername" -Level Info
}

# Old hotfix list
#$hotfix = Get-HotFix 
#$hotfix | Out-File  "$OrgPatchFilesPath\patching.txt" -Append
#get-date | Out-File  "$OrgPatchFilesPath\patchingreport.txt" -Append
#$timeinput | Out-File  "$OrgPatchFilesPath\patchingreport.txt" -Append
Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
Write-host " -----------Schedulling a task for compare the services after reboot ------------" -BackgroundColor Magenta
Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta


Start-Sleep -Seconds 120

#creating a task scheduler to run a script for compare services after reboot
try {
    # Check if Task Scheduler service is running
    Unregister-ScheduledTask -TaskName PatchingAfterReboot -Confirm:$false -ErrorAction SilentlyContinue -Verbose
    Unregister-Scheduledjob -Name PatchingAfterReboot -Confirm:$false -ErrorAction SilentlyContinue -verbose
    Unregister-Scheduledjob -Name CompareServices -Confirm:$false -verbose -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName Monthly_Patching_CompareServices -Confirm:$false -ErrorAction SilentlyContinue -Verbose
}
catch {
    continue
}

if (Copy-Item -Path "$comparescript" -Destination $LocalFilesPath -Recurse -verbose -ErrorAction SilentlyContinue) {
    $trigger = New-JobTrigger -AtStartup -RandomDelay 00:10:00
    try {
        Register-Scheduledtask -Trigger $trigger -FilePath $localCompareScript -Name Monthly_Patching_CompareServices -Verbose -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "the Compare script file couldn't be copied and the task scheduller hasn't been setup"
        Write-Log -Message "the Compare script file couldn't be copied and the task scheduller hasn't been setup" -Level Error
    }
}
else {
    Write-Error "the Compare script file couldn't be copied and the task scheduller hasn't been setup"
    Write-Log -Message "the Compare script file couldn't be copied and the task scheduller hasn't been setup" -Level Error
}



$StartDate = (GET-DATE)
$EndDate = [datetime]$timeinput

$newTime = NEW-TIMESPAN –Start $StartDate –End $EndDate
$totalseconds = $newtime.TotalMinutes * 60
if ($timeinput -eq "NO") {
    write-host " the host won't reboot" -ForegroundColor Red
    $rebootstatus = "the host is waiting for manually reboot"
    break
}
#this will check if the curent time hasn't passed the reboot time, if it passed, it will check the patch window and reboot the server now
elseif ($reboot -lt $Startdate) {
    $timevariable = $server.patch_window
    # Extract the time part (00:00-04:00)
    $timePart = $timeVariable.Split("-")[3]

    # Get the current time
    $currentTime = Get-Date -Format "HH:mm"

    # Compare the time part with 04:00
    if ($currentTime -lt $timePart) {
        shutdown -r -t 120
    }
    else {
        Write-Host "The current time is greater than or equal to 04:00."
        Write-Log -Message "$ComputerName couldn't be rebooted because it missed the patch window" -Level Error
        Send-MailMessage  -Subject "Error: $ComputerName couldn't be rebooted because it missed the patch window" 
        break

    }
}
else {
    Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
    Write-host " ----------------schedulling reboot based on reboot spreadsheet------------------" -BackgroundColor Magenta
    Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
    write-log -Message "The host will be reboot on $timeinput" -Level Info
    write-host " The host will be reboot on $timeinput" -ForegroundColor Yellow
    $i = [int]$totalseconds
    shutdown /r /t $i
    $rebootstatus = " the host will reboot on $timeinput"
    Write-Log -Message "$computername is set to be rebooted on $timeinput" -Level Info
    $totalseconds = $totalseconds - 120
    $FinishDate = Get-Date

    ExportToCSV -ComputerName $ComputerName -Domain $Domain -LastReboot $Lastreboot -StartDate $Startdate -EndDate $FinishDate -InstalledKB $InstalledKB -NotInstalledKB $NotInstalledKB -RebootStatus $RebootStatus -wmistatus $wmistatus
   
    Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
    Write-host " ---------------------------------remain patches --------------------------------" -BackgroundColor Magenta
    Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
    
    $Not_Installed = remain_patches
    $Not_Installed
    write-log -Message "the remain patches are $Not_Installed" -Level Info
    Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
    Write-host " ---------------------Removing all unneccessary files ------------------------" -BackgroundColor Magenta
    Write-host " --------------------------------------------------------------------------------" -BackgroundColor Magenta
    try {
        
        Remove-Item "$LocalFilesPath\*.msu"  -ErrorAction SilentlyContinue
        Remove-Item "$LocalFilesPath\*.exe"  -ErrorAction SilentlyContinue
    }
    catch {
    
    }


    $d = Get-Date
    Write-Host "$d : the process is finished" -ForegroundColor Green
    write-log -Message "$computername : the process is finished" -Level Info
    Start-Sleep $totalseconds

    Stop-Transcript

    [int]$Time = $totalseconds
    $Lenght = $Time / 100
    For ($Time; $Time -gt 0; $Time--) {
        $min = [int](([string]($Time / 60)).split('.')[0])
        $text = " " + $min + " minutes " + ($Time % 60) + " seconds left"
        Write-Progress -Activity "Watiting for..." -Status $Text -PercentComplete ($Time / $Lenght)
        Start-Sleep 1
    }

}








 
 
