function Get-KB-Needed {
    <#
        .SYNOPSIS
            Returns the KB number needed to install on a remote computer.
        
        .DESCRIPTION
            The Get-KB-Needed function retrieves the KB number needed to install on a remote computer. It uses WMI to query the required update information.
            This script will query WMI on a remote computer to get the list of updates that are needed to be installed.
        .PARAMETER ComputerName
            The name of the computer to query for updates. The default value is the local computer.
            
        .EXAMPLE
            Get-KB-Needed -ComputerName "pwakutilapp03"
    
            This command will return the KBs needed to be installed on the computer "pwakutilapp03". If no computer is specified, it defaults to the

            #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    begin {
        
    }
    
    process {
        if ($computername -eq "All") {
            [string]$CurrentMonth = (Get-Date).ToString("MMMM") , # Name of the patch list file. Default is the current month
            [string]$patchList_Path = "$env:Main_Patching_Path\$CurrentMonth\$CurrentMonth.csv" # Path to the patch list file. Default is the main patch list file
            #$HostName = "pwakpshapp01"
            try {
                $servers = import-csv -Path $patchList_Path 
                $KB_Needed = @()
                foreach ($server in $servers) {
                    $ComputerName = $server.hostname
                    $KBs = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                        $UpdateSearcher = $UpdateSession.CreateupdateSearcher()
                        $Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)
                        $Updates | Select-Object Title
                        
                    }
                    $kb_needed += $KBs.Title
                
                }
                $KB_Needed = $kb_needed | sort-object | Get-Unique
                $KB_Needed | export-csv -Path "$env:Main_Patching_Path\$CurrentMonth\KB_Needed.csv" -NoTypeInformation -Verbose
            }
            catch {
                Write-Log -Message "Error occurred while importing the patch list file" -Level "Error"
                Write-Error -Message "the servers haven't been imported from patching list"
                exit
            }
    
        }
        else {
            try {
                $session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
                $KBs = Invoke-Command -Session $session -ScriptBlock {
                    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                    $UpdateSearcher = $UpdateSession.CreateupdateSearcher()
                    $Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)
                    $Updates | Select-Object Title
                }
                Remove-PSSession $session
            }
            catch {
                Write-Error "Failed to retrieve KBs from $ComputerName : $_"
            }
        }
    }
    
    end {
        return $KBs
    }
}

#Get-KB-Needed -ComputerName "pwakutilapp03"


                