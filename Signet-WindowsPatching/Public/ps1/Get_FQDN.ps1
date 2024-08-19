function Get_FQDN {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName
    )

    # Check if the hostname is already a FQDN
    if ($HostName -like '*.*') {
        return $HostName
    }

    # List of domains
    $domains = @('jewels.com', 'jewels.local', 'irving.zalecorp.com', 'zalecorp.com', 'zaleweb.com')

    # Loop through each domain to find FQDN
    foreach ($domain in $domains) {
        $fqdn = $HostName + '.' + $domain
        $resolved = Resolve-DnsName -Name $fqdn -ErrorAction SilentlyContinue
        if ($resolved) {
            return $fqdn
        }
    }

    # If FQDN not found, return the input hostname
    return $HostName
}

