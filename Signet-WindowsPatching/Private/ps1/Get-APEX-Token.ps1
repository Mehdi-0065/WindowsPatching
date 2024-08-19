

function Get-APEX-Token {
    <#
.SYNOPSIS
    Retrieves an APEX token for authentication.

.DESCRIPTION
    The Get-APEX-Token function retrieves an APEX token by sending a request to the specified token endpoint. 
    The token is used for authentication purposes.

.PARAMETER clientId
    The client ID used for authentication.

.PARAMETER clientSecret
    The client secret used for authentication.

.PARAMETER tokenEndpoint
    The endpoint URL where the token request is sent.

.EXAMPLE
    Get-APEX-Token -clientId "myClientId" -clientSecret "myClientSecret" -tokenEndpoint "https://api.example.com/token"

.NOTES
    This function requires an internet connection to send the token request.
#>
    param (
        [Parameter(Mandatory = $true)]
        [string]$clientId,
        
        [Parameter(Mandatory = $true)]
        [string]$clientSecret,
        
        [Parameter(Mandatory = $true)]
        [string]$tokenEndpoint
    )

    $pair = "${clientId}:${clientSecret}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
  

    $headers_Token = @{
        "Authorization" = "Basic $base64"
    }

    $body = @{
        "grant_type" = "client_credentials"
    }

    $tokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -Headers $headers_Token
    write-host $tokenResponse
    # Extract the access token from the response
    $accessToken = $tokenResponse.access_token
    return $accessToken
}

