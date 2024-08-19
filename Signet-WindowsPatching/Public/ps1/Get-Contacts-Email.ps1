function Get-Contacts-Email {
            
    <#
    .SYNOPSIS
        generate an array of email address for each serves
    .DESCRIPTION
        we send primary contact display name, secondary contact display name and group email address to this function and it will return an array of email address
    .PARAMETER primary_contact
        the display name of the primary contact
    .PARAMETER secondary_contact
        a comma separated list of additional contacts to send the email to.  The first contact will be added as 'To' and the rest will be added as 'CC'
    .PARAMETER group_email
        this is Group email that is provided in APEX for each servers
    .NOTES
        if there is no contact for a group, it will send an email to the default email address
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        get-contact-email -primary_contact "Rezaei, Mehdi" -secondary_contact "Mehdi Rezaei" -group_email "Mehdi Rezaei"
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
            $to_default += Get-EmailAddress -displayName $primary_contact
            if ($secondary_contact -ne "" ) {
                $secondary = Get-EmailAddress -displayName $secondary_contact
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
            $to_default += Get-EmailAddress -displayName $secondary_contact
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
        Write-Log -Message "The email address is $to_default" -Level "Info"
        return $to_default
    }
}
