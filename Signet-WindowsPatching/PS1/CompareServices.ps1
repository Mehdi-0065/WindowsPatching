
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

$currentDate = Get-Date

# Format the date to display the full month name
$currentMonth = $currentDate.ToString("MMMM")
#set paths
$Path1 = "\\isilon01.jewels.com\Archives\WindowsPatching\$currentMonth"
$Path2 = "\\nas01\ISO\Patching\$currentMonth"
$Path3 = "\\zlvdalmgm01p\Patching\$currentMonth"
$OrgPatchFilesPath = GetCorrectPath -PatchPath1 $Path1 -PatchPath2 $Path2 -PatchPath3 $Path3
$ExportDetailofServer = "$OrgPatchFilesPath\Servers-Detail-after-reboot.csv"


$LocalFilesPath = "c:\temp\PatchFiles"
$serviceslogs = "$LocalFilesPath\ServicesReport.csv"
$DifferencesFile = "$LocalFilesPath\Compare-Services.csv"
$ComputerName = $env:computername
$body = " $ComputerName has been patched and restarted. Variations in the state of the services before and after the reboot where noticed on the server 15 minutes after start up. Informatiom on the services are attached to this email. Please check the services to ensure there will be no issues with the production environment. "
$lastreboot = Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime
$lastreboot = $lastreboot.lastbootuptime

$domain = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain
$domain = $domain.domain
$Startdate = Get-Date


$mailParams = @{
    SmtpServer  = 'smtp-akr.jewels.com'
    Port        = '25' #'587' # or '25' if not using TLS
    UseSSL      = $false #$true ## or not if using non-TLS
    From        = 'no-reply@signetjewelers.com'
    #    To                         = 'Brian.Davis-1@SignetJewelers.com'
    To          = 'Mehdi.Rezaei@SignetJewelers.com'
    Subject     = " Services alert after rebooting $ComputerName "
    #Priority                   = $priority
    BodyAsHtml  = $true
    Body        = $body
    Attachments = $DifferencesFile #,'C:\Temp\ADMEmails\MFA-01.png','C:\Temp\ADMEmails\MFA-02.png','C:\Temp\ADMEmails\MFA-03.png','C:\Temp\ADMEmails\MFA-04.png','C:\Temp\ADMEmails\MFA-05.png','C:\Temp\ADMEmails\MFA-06.png','C:\Temp\ADMEmails\MFA-07.png','C:\Temp\ADMEmails\MFA-08.png','C:\Temp\ADMEmails\MFA-09.png'
    #    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
    #CC                         = 'christopher.gerbasi@signetjewelers.com'
    #CC                         = 'paul.andres@signetjewelers.com'
    #CC                         = 'Jonathan.Rivera@signetjewelers.com'
}
       
## Send the message
        



#Start-Sleep 900


if (Test-Path -Path $serviceslogs) {


    $oldservices = import-csv -Path $serviceslogs
    $currentServices = Get-Service

    $Result = Compare-Object -ReferenceObject $oldservices -DifferenceObject $currentServices -Property "name", "status", "ServiceType" -PassThru

    if ($Result) {

        Compare-Object -ReferenceObject $oldservices -DifferenceObject $currentServices -Property "name", "status", "ServiceType" -PassThru | export-csv -Path $DifferencesFile -NoTypeInformation

        Send-MailMessage @mailParams
        Write-Host "The following differences were found:"
        $Result
        $compare = "False"
    }
    else {
        Write-Host "The files are identical."
        $compare = "True"
    }
}
else {

    write-host "we couldn't find the old services log file"
    $compare = "True"
}


                
$Log = @{
    "ComputerName"   = $ComputerName
    "Domain"         = $Domain
    "LastReboot"     = $Lastreboot
    "StartDate"      = $Startdate
    "Service status" = $compare
       
}
New-Object PSObject -Property $log | Export-Csv $ExportDetailofServer -NoTypeInformation -Append -force



Unregister-ScheduledTask -TaskName Compareservices -Confirm:$false
