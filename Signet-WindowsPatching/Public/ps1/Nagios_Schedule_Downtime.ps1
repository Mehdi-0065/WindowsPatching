

function Nagios_Schedule_downtime {

    <#
.Synopsis 
    This is a script for schedulling downtime in nagios
.DESCRIPTION 
    This script is used to schedule downtime in Nagios for a specific host. The script takes the hostname, downtime length, and start time as input parameters. The script calculates the end time based on the start time and downtime length. The script then constructs a comment based on the domain user and hostname. The script then sends a POST request to the Nagios API to schedule the downtime for the specified host. The script also sends a POST request to the Nagios API using the FQDN of the host. The script outputs a success message if the downtime is scheduled successfully, otherwise, it outputs a failure message.
    The script will add or remove downtime for the host based on the input parameters. It uses the nagios api to interact with nagios.
    
.NOTES 
    Created by: Mehdi Rezaei, mehdi.rezaei@signetjewelers.com
    Modified:   10/18/2023 10:30:00 - 
    Version:    1.0 - Initial release
               1.1 - Fixed bug that

                
.PARAMETER length
    The duration of the scheduled downtime in seconds. Default value is 2100 seconds (35 Minutes)
.PARAMETER hostname
    The name of the host to be added to the downtime schedule.
.PARAMETER start_downtime
    Start time of the downtime in the format "M/d/yyyy h:mm". The script will convert this to epoch time for the API request.
    
.EXAMPLE 
   .\Nagios_Schedule_downtime.ps1 -length 2100 -hostname "pwakpshapp01" -start_downtime "3/25/2024 4:04"
   
    This example schedules downtime for the host "pwakpshapp01" for 35 minutes starting at 4:04 AM on 3/25/2024.
    

#>
    
    param(
        [Parameter(Mandatory = $True)]
        [string]$length,
   
        [Parameter(Mandatory = $True)]
        [string]$hostname,

        [Parameter(Mandatory = $True)]
        [string]$start_downtime
    )
    #. .\public\ps1\Get_FQDN.ps1
    #$h = $hostname # Hostname
    $FQDN = Get_FQDN -HostName $hostname


    $Nagios_APIKey_Akron = $env:Nagios_APIKey_Akron #get the API Key from environment variable
    $Nagios_APIKey_Irving = $env:Nagios_APIKey_Irving

    $Nagios_Akron_URL = $env:NagiosAkronURL
    $Nagios_Irving_URL = $env:NagiosIrvingURL
    $parameters = @(
        @{ City = "Akron"; APIKey = $Nagios_APIKey_Akron; URL = $Nagios_Akron_URL },
        @{ City = "Irving"; APIKey = $Nagios_APIKey_Irving; URL = $Nagios_Irving_URL }
    )
    
    # Setting User Specific Variables
    $domainUser = "Corp\SVC_Patching_Auto" #([Environment]::UserDomainName + "\" + [Environment]::UserName)
    
    [int]$length = $length # the length of the downtime in seconds

    # Start time now() in epoch
    #[int]$start = (Get-Date (Get-Date).ToUniversalTime() -UFormat %s).split('.')[0]
    #$start_downtime = "3/25/2024 4:04 AM"
   

    # Parse the string as a DateTime object
    $dateTime = [System.DateTime]::ParseExact($start_downtime, "M/d/yyyy h:mm", $null)

    # Convert the DateTime to Unix timestamp (seconds since Unix epoch)
    [int]$start = ($dateTime.ToUniversalTime() - (Get-Date "1969-12-31 19:00:00").ToUniversalTime()).TotalSeconds
    #$unixTimestamp = [int][double]::Parse($dateTime.ToUniversalTime().Subtract((Get-Date "1/1/1970")).TotalSeconds)


    # End time calculated start time + length given is seconds
    $end = $start + $length

    # Make epoch times human readable for mandatory comment in request
    $readStart = (([System.DateTimeOffset]::FromUnixTimeSeconds($start)).DateTime).AddHours(0).ToString("s")
    $readEnd = (([System.DateTimeOffset]::FromUnixTimeSeconds($end)).DateTime).AddHours(0).ToString("s")

    # Constructing comment
    $comment = "$domainUser has initiated a scheduled downtime for host $hostname in relation to monthly patching process"
    
    foreach ($param in $parameters) {
        $city = $param.City
        $apiKey = $param.APIKey
        $url = $param.URL
               
        # Your processing code for each city (Akron or Irving) goes here
        try {
            $body = "apikey=$apikey&author=$domainUser&comment=$comment&start=$start&end=$end&hosts[]=$hostname"
            
            $jsonResponse = Invoke-WebRequest -Uri $url -Method Post -Body $body -ErrorAction Stop
        }
        catch {
        
        }
        try {
            $body = "apikey=$apikey&author=$domainUser&comment=$comment&start=$start&end=$end&hosts[]=$FQDN"
            
            $jsonResponseFQDN = Invoke-WebRequest -Uri $url -Method Post -Body $body -ErrorAction Stop
            
        }
        catch {
        
        }
      
    }
    if ($jsonResponse -or $jsonResponseFQDN) {
        Write-Host "Downtime scheduled for $hostname in $city from $readStart to $readEnd" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to schedule downtime for $hostname in $city" -ForegroundColor Red
    }
}
# Importing CSV file
<#
$Servers_List_path = "\\isilon01.jewels.com\Archives\WindowsPatching\March\ServersList-March-temp.csv"

$servers = Import-Csv -path $servers_List_path | Where-Object {$_.hostname -eq "pwakpshapp01"}
foreach ($server in $servers) {
    $hostname = $server.hostname
    $reboot = $server.reboot
    if ($reboot) {
        Nagios_Schedule_downtime -length 2100 -hostname "pwakpshapp01" -start_downtime $reboot
    }

}
#>

