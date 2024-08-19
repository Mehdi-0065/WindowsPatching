function Write-Log { 
    <#
.SYNOPSIS
This code performs a logging process.

.DESCRIPTION
This code is responsible for storing patching process in Local and shared files.

.PARAMETER Parameter1
Message = the content that you need to save in log file.

.PARAMETER Parameter2
LogLocation = you can choose either "Local" or "Shared". it is chosen both by default.

.PARAMETER Parameter3
Path = the path of the log file. It will be created if not exists.
by default, it is "C:\temp\patchfiles\Patching-process.log" for local log file.
and it is "\\isilon01.jewels.com\patching$\Windows\Logs\Patching-process.log" for shared log file.

.PARAMETER Parameter4
Level = the level of the log message. It can be "Critical", "Error", "Warn", "Info". It is "Info" by default.

.EXAMPLE
Write-Log -Message "The script has started"  -Path "C:\temp\patchfiles\Patching-process.log"
Write-Log -Message "The script has started"  -Path "C:\temp\patchfiles\Patching-process.log" -Level "Error"
Write-Log -Message "The script has started" -LogLocation "Local" -Path "C:\temp\patchfiles\Patching-process.log" -Level "Warn"
Write-Log -Message "The script has started"  -Level "Critical"


.NOTES
[Add any additional notes or information about the code].
#>
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 

        [Parameter(Mandatory = $false)]
        [ValidateSet("Local", "Shared")]
        [string[]]$LogLocation = @("Local", "Shared"),

        [Parameter(Mandatory = $false)] 
        [Alias('LogPath')] 
        [string]$Path, 
         
        [Parameter(Mandatory = $false)] 
        [ValidateSet("Critical", "Error", "Warn", "Info")] 
        [string]$Level = "Info", 
         
        [Parameter(Mandatory = $false)] 
        [switch]$NoClobber 
    ) 

    Begin { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue'
        $SharedLogPath = $env:Main_log_path + "\Patching-process.log"
        $LocalLogPath = "C:\temp\patchfiles\Patching-process.log" 

        if (-not (Test-Path -Path $SharedLogPath)) {
            New-Item -Path $SharedLogPath -ItemType File
        }
        
        # Check if the local log file exists, if not, create it
        if (-not (Test-Path -Path $LocalLogPath)) {
            New-Item -Path $LocalLogPath -ItemType File
        }

        if ($PSVersionTable.PSVersion.Major -lt 5) {
            Write-Warning "This script was designed for PowerShell 5.1 or later. Some features may not work as expected with the current version."
        } 
        
        # Check if LogLocation is specified, if not, log to both local and shared paths
        if (-not $Path) {
            # Adjust as needed
            $Path = $LocallogPath
        }
    } 
    Process { 
        foreach ($Location in $LogLocation) {
            # Set default log file path based on the selected location
            if ($Location -eq "Local") {
                $Path = $LocallogPath
                
            }
            elseif ($Location -eq "Shared") {
                # Set the shared location path
                $Path = $SharedLogPath
                
            }
             
            # If the file already exists and NoClobber was specified, do not write to the log. 
            if ((Test-Path $Path) -AND $NoClobber) { 
                Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
                Continue
            } 
            
            # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
            elseif (!(Test-Path $Path)) { 
                Write-Verbose "Creating $Path." 
                $NewLogFile = New-Item $Path -Force -ItemType File 
            } 

            # Format Date for our Log File 
            $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 

            # Write message to error, warning, or verbose pipeline and specify $LevelText 
            switch ($Level) { 
                'Critical' {
                    Write-Error $Message
                    $LevelText = 'Critical'
                }
                'Error' { 
                    Write-Error $Message 
                    $LevelText = 'Error' 
                } 
                'Warn' { 
                    Write-Warning $Message 
                    $LevelText = 'Warning' 
                } 
                'Info' { 
                    Write-Verbose $Message 
                    $LevelText = 'Informational' 
                } 
            } 
            # Retry logic if the file is being used by another process
            $retryCount = 0
            while ($retryCount -lt 10) {
                # You can adjust the maximum number of retries
                try {
                    
                    # Write log entry to $Path 
                    "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append -ErrorAction Stop
                    
                      
                }
                catch [System.IO.IOException] {
                    if ($_.Exception.Message -match "The process cannot access the file") {
                        Write-Warning "Log file $Path is being used by another process. Retrying in 1 second..."
                        Start-Sleep -Seconds 1
                        $retryCount++
                    }
                    else {
                        throw  # Rethrow the exception if it's not the expected error
                    }
                }
            }
        }

    } 
    End { 
    } 
}
