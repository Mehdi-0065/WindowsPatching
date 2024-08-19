function Get-DecryptedCredentials {
    [CmdletBinding()]
    param (
        [string] $KeyPath
    )
    # Load JSON configuration
    $jsonConfiguration = Get-Content -Path $KeyPath | ConvertFrom-Json
    if ($jsonConfiguration -match "clientID") {
       


        # Retrieve and decrypt the encrypted values
        $encryptedClientId = $jsonConfiguration.ClientId
        $encryptedClientSecret = $jsonConfiguration.ClientSecret

        # Decrypt the encrypted values
        $clientIdSecure = ConvertTo-SecureString -String $encryptedClientId
        $clientSecretSecure = ConvertTo-SecureString -String $encryptedClientSecret

        # Convert SecureString objects to plaintext
        $clientIdPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientIdSecure))
        $clientSecretPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecretSecure))
        write-host "ClientID and SecretID are returned"
        # Return decrypted credentials
        return @{
            ClientId     = $clientIdPlain
            ClientSecret = $clientSecretPlain
        }
    }
    else {
        $clientIdSecure = ConvertTo-SecureString -String $jsonConfiguration
        $clientIdPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientIdSecure))
        Write-Host "API Key is returned"
        return $clientIdPlain

    }
}
