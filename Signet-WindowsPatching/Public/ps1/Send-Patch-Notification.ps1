
function Send-Patch-Notification {
    <#
.SYNOPSIS
    Send an email notification to the contacts about the upcoming patching schedule.
.DESCRIPTION
    This function is responsible for sending an email notification to the contacts about the upcoming patching schedule.
    The email will contain the list of servers that are going to be patched. 
    It is recommended to send this email notification to the contacts before the patching schedule.
.PARAMETER contacts_grouped
    A hashtable containing a group name
.EXAMPLE
  
    
    PS C:\> Send-Patch-Notification -contacts_grouped $contacts
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$contacts_grouped
    )
    
    begin {
        
    }
    
    process {
        foreach ($contact_grouped in $contacts_grouped) {
    
            $primary_contact = $contact_grouped.Group[0].primary_contact
            $secondary_contact = $contact_grouped.Group[0].secondary_contact
            $group_email = $contact_grouped.Group[0].group_email
        
            if ($contact_grouped.Name.count -gt 0) {
                $to_default = Get-Contacts-Email -primary_contact $primary_contact -secondary_contact $secondary_contact -group_email $group_email
            }
        
        
            #Function to find the email address of the contact person
            else {
                Write-Error "there is no contact for $($contact_grouped.Name[0])"
                $hostnames = $contact_grouped.Group.hostname
                $to_default = "mehdi.rezaei@signetjewelers.com"
                $subject_default = "WARNING: $hostnames don't have contact information"
                $body_default = "$hostnames don't have contact information"
                send_email -subject $subject_default -to $to_default -body $body_default
                
                break
            }
        
            $hostnames = $contact_grouped.Group | Select-Object -ExpandProperty hostname -Unique
            $hostnames
            write-host $to_default -ForegroundColor red
            $subject_default = "It is only a test: $hostnames are going to be patched"
            $body_default = @"
            Hi There,<br><br>
        
            Since you are designated as a contact for those servers, We would like to notify you that the servers below will be patched and restarted during $($contact_grouped.group[0].patch_group) on $($contact_grouped.group[0].next_patch_date).<br><br>
            
            $($hostnames -join "<br>")<br><br>
            
            Mehdi Rezaei<br>
            IT Engineer IV<br>
"@
        
            try {
                $Email_Status = send_email -subject $subject_default -to $to_default -body $body_default -Verbose
                if ($Email_Status) {
                    Log-Write -LogPath $LogPath -LogName $LogName -Message "Email sent to $to_default about $hostnames" 
                }
            }
            catch {
                Write-Error "Error occurred while sending email to $to_default"
                Log-Error -LogPath $LogPath -LogName $LogName -Message "Error occurred while sending email to $to_default" 
                exit
            }
        }
        
        
    }
        
 
    
 
}
