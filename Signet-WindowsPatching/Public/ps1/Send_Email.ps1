function Send_Email {
    
    <#
.SYNOPSIS
this function is being used for sending email.

.DESCRIPTION
This code is responsible for sending email to Signet emails. it wil luse 2 Akron and C1 SMTP server.

.PARAMETER Subject
Subject = the text  that will be on top of the mail body.
the default value is "WARNING: $env:computername is failing to be patched"

.PARAMETER body
body = the text that will be in the body of the email.
the default value is "The patching process is failing on $env:computername. Please check the log file for more information."
.PARAMETER to
to = the email address that the email will be sent to.if there are more then one email add them with ","
the default is "mehdi.rezaei@signetjewelers.com"

.PARAMETER cc
cc = the email address that the email will be sent to. if there are more then one email add them with ",".

.PARAMETER attachment
attachment = the path of the file that will be attached to the email.

.EXAMPLE
Send-email -subject "test" -body "test test" -to "adm-mrezaei@jewels.com","mehdi.rezaei@signetjewelers.com" -cc "ariel@sig.com" -attachment "c:\temp\test.txt"


#>
   
    [CmdletBinding()]
    param (
        [string] $Subject = "WARNING: $env:computername is failing to be patched",
        [System.Object] $body = "The patching process is failing on $env:computername. Please check the log file for more information.",
        [System.Array]$to = "mehdi.rezaei@signetjewelers.com",
        [string]$cc = "",
        [string]$attachment = ""
    )

    $primarySmtpServer = 'smtp-akr.jewels.com'
    $secondarySmtpServer = 'smtp-c1.jewels.com'

    $mailParams = @{
        SmtpServer = $primarySmtpServer
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
    #CC                         = 'paul.andres@signetjewelers.com'
    #CC                         = 'Jonathan.Rivera@signetjewelers.com'
    
    try {
        Send-MailMessage @mailParams -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to send email using the primary SMTP server. Trying secondary SMTP server..."
        $mailParams['SmtpServer'] = $secondarySmtpServer
        Send-MailMessage @mailParams -ErrorAction Stop
    }
}

