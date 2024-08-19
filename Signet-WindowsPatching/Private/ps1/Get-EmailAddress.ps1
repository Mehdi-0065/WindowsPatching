function Get-EmailAddress {
    <#
.SYNOPSIS
Find the email address based on a display name.

.DESCRIPTION
This code is responsible for find the primary address for a display name from 3 different domains.

.PARAMETER Parameter1
Displayname = lastname, firstname  (e.g., Rezaei, Mehdi)

.EXAMPLE
Get-EmailAddress -displayname "Rezaei, Mehdi"


#>
   
    [CmdletBinding()]
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
