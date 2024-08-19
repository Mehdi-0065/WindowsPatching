function Update_Apex {
    <#
        .SYNOPSIS
            Updates the APEX database with the patching information.
        
        .DESCRIPTION
            This function is used to update the APEX database with the patching information for a specific host.
            This script will update the APEX database with the patch date, reboot date, and patch status for a specific host.
        .PARAMETER patch_date
            The date the patch was installed.  This is used to determine if a patch has been installed on a host.
        .PARAMETER reboot_date
        The date and time when a system should be rebooted after a patch has been installed.  This parameter is required if you are using the
        .PARAMETER Patch_status
            The status of the patch installation.  This parameter is optional and defaults to "Success".
        .PARAMETER Host_ID
            The ID of the host that this patch information is being updated for. This is a mandatory parameter. HostID is a unique identifier for each host assigned to each host in APEX.
        .EXAMPLE
            Update-Apex -patch_date "2024-03-18" -reboot_date "2024-03-19 03:00:00" -Patch_status "Success" -Host_ID "12345"
        


        #>
    [CmdletBinding()]
    param (
        [string]$patch_date,
        [string]$reboot_date,  
        [string]$Patch_status = "Success",
        [Parameter(Mandatory = $true)]
        [string]$Host_ID
    )
    $host_URL = $env:APEX_APIURI_PUT+$host_ID
  $host_URL
    $accessToken_PUT = $env:AccessToken_Put
    $headers_put = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $accessToken_PUT"
    }
    try {
        $response = Invoke-RestMethod -Uri $host_URL -Method PUT -Headers $headers_put -Body (ConvertTo-Json @{

                patch_date   = $patch_date
                reboot_date  = $reboot_date
                patch_status = $Patch_status
                #last_os_patch_installed = "March Security Patch"
            })
        Write-Host "The API response was successfully retrieved." -BackgroundColor Green
    }
    catch {
        $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody
    }
    
}

<#
$updates= import-csv -Path "$env:Main_Patching_Path\Update_Apex.csv"
foreach ($update in $updates) {
    
    Update_Apex -patch_date $update.patch_date -reboot_date $update.reboot_date -Patch_status $update.patch_status -Host_ID $update.HostID
}
#>
