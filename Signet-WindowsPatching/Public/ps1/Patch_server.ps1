<#
1- get the API key from an encrypted file
#>
function Patch_Server {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Server")]
        [Alias("ComputerName")]
        [string]$ServerName,

        [Parameter(Position = 1)]
        [datetime]$PatchDate = (Get-Date).ToString("MM/dd/yyyy")
    )
    
    begin {
        
    }
    
    process {
        
    }
    
    end {
        
    }
}