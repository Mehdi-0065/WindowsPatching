function Get-APEX-Servers {
    <#
    .EXAMPLE
    Get-APEX-Servers -Filter { patch_group -like "Prod*" -and  location -match "Cyrus|Akron"}
}
    
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [scriptblock]$Filter
    )
    
    
    begin {

        $APEX_Filter = "host_Id",
        "patch_group",
        "VM_name",
        "hostname",
        "Location",
        "OS",
        "Short_os",
        "patch_window",
        "application",
        "primary_contact",
        "secondary_contact",
        "next_patch_date",
        "Reboot_only", 
        "patch_notes",
        "patch_priority",
        "group_email",
        "OS",
        "NewPatchGroup"

        # Get APEX token
        Write-Log -Message "Getting APEX token" -Level "Info"
        $clientId_PUT = $env:APEX_ClientId_PUT
        $clientSecret_PUT = $env:APEX_clientSecret_PUT
        $apiURI_PUT = $env:APEX_APIURI_PUT # / host_id

        #HostPatchDetails
        $clientId_GET = $env:APEX_ClientId_GET
        $clientSecret_GET = $env:APEX_clientSecret_GET
        $apiURI_Get = $env:APEX_APIURI_GET

        $tokenURL = $env:APEX_tokenEndpoint
        
    }
    
    process {
        
        
    }
    
    end {
        return $APEX_Servers
    }
}