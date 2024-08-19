<#
.SYNOPSIS
    Retrieves the API response.

.DESCRIPTION
    This function is used to retrieve the response from APEX  RESTful APIs. It takes a URL as input and returns the response from the API.

.PARAMETER ApiUrl
    The URL of the API.

.PARAMETER Header
    The headers to include in the API request.

.EXAMPLE
    $header_get = @{
        Authorization = "Bearer $accessToken_GET"
    }
    Get-ApiResponse -ApiUrl "https://api.example.com" -header $header_get

    Retrieves the response from the specified API using the GET method.

#>
function Get-ApiResponse {

    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Header
    )

    try {
        $response = Invoke-RestMethod -Uri $Uri -Headers $header -Method Get -ErrorAction Stop
        Write-Host "The API response was successfully retrieved." -BackgroundColor Green
        return $response
    }
    catch {
        Write-Error "Error occurred while calling the API: $($_.Exception.Message)"
        return $null
    }
}
