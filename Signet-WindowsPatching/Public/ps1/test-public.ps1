
function test-public {
    <#$root = $Script:ModuleRoot
    $private = $root + "\Private\ps1"
    $private
    . $private\Get-DecryptedCredentials.ps1
    
    $KeyPath = "\\isilon01.jewels.com\patching`$\Windows\Keys\Apex_API_Get.json"
    #Get-DecryptedCredentials -KeyPath $KeyPath
    $env:APEX_ClientId_GET
    $env:APEX_clientSecret_GET
    $env:Main_Patching_List
    Write-Log -Message "The script has started root" -Level "error"
    Get-EmailAddress -displayName "rezaei, mehdi" 
    Write-Log -Message "The script has started root" -Level "error"
    #>
    $updates = import-csv -Path "$env:Main_Patching_Path\Update_Apex.csv"
    foreach ($update in $updates) {
    
        Update_Apex -patch_date $update.patch_date -reboot_date $update.reboot_date -Patch_status $update.patch_status -Host_ID $update.HostID
    }

}