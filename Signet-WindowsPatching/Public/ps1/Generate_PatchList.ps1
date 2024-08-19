function Generate_PatchList {
    [CmdletBinding()]
    param (
        [string]$PatchList_Name = (Get-Date).ToString("MMMM") , # Name of the patch list file. Default is the current month
        [string]$patchList_Path = "$env:Main_Patching_Path\$Patchlist_name", # Path to the patch list file. Default is the main patch list file
        [ScriptBlock]$filterConditions = {
            ($_.patch_window -match "PROD|NONPROD") -and
            ($_.os -match "windows") -and
            ($_.os -match "2016|2019") -and
            ($_.manual_Patch -eq "N") -and
            ($_.location -match "Akron|Cyrus|VMC") -and #Akron|Cyrus|VMC
            ($_.Reboot_only -eq "N") #-and
            #(([DateTime]::ParseExact($_.next_patch_date, "M/d/yyyy hh:mm:ss tt", $null)).Date -eq $providedDate)
        }
    )
    
    begin {
        
        $ModuleRootPath = $PSScriptRoot
        write-host $ModuleRootPath -BackgroundColor Red
        . .\Private\ps1\Get-ApiResponse.ps1
        . .\Private\ps1\Get-EmailAddress.ps1

        $APEX_Filter = "host_Id",
        "VM_name",
        "hostname",
        "Location",
        "OS",
        "Short_os",
        "primary_contact",
        "secondary_contact",
        "group_email",
        "application",
        "patch_window",
        "last_patch_date",
        "last_patch_status",
        "last_os_patch_installed",
        "Reboot_only", 
        "next_patch_date",
        "last_reboot_date",
        "patchable",
        "patch_notes",
        "patch_priority",
        "do_not_reboot_on_patch",
        "manual_patch"
        if (-not (Test-Path $patchList_Path)) {
            New-Item -Path $patchList_Path -ItemType Directory -Force
        }

        $Patchlist = Join-Path $patchList_Path -ChildPath "$PatchList_Name.csv"
        
        if (Test-Path $PatchList) {
            Write-Host "$PatchList_Name is already exist in $patchList_Path . you can use "Generate_PatchList -Patchlist_name "newName" -ForegroundColor Red 
            if ((Read-Host "Do you want to overwrite the file? (Y/N)").ToUpper() -eq "Y") {
                Write-Warning "Moving $PatchList to Archive folder..."
                $NewName = "$PatchList_Name-$(Get-Date -Format 'yyyyMMdd').csv"
                Rename-Item $Patchlist -NewName $NewName 
                Move-Item  "$patchlist_path\$NewName" -Destination "$patchList_Path\Archive" -Force 
            }
            else {
                Write-Host "Exiting..." -ForegroundColor Red
                break
            }
            
        }
        else {
            write-host "Generating Patch List in $Patchlist`n" -ForegroundColor Green -BackgroundColor Black
            

        }

        $headers_get = @{
            Authorization = "Bearer $env:AccessToken_Get" #this is generating in the Initialize-Data.ps1 script
        }
    }
        
    #header for updating the last patch date and reboot time in APEX
    
    process {
     
        # Create a new CSV with headers and add
        try { 
            
            $Apex_servers = Get-ApiResponse -Uri $env:APEX_APIURI_GET -Header $headers_get -ErrorAction Stop
            
            $windowsServers = $Apex_servers.items | Where-Object $filterConditions | Select-Object  $APEX_Filter #| Where-Object { $_.hostname -eq "pwcoslwnapp01" } |Export-Csv -Path $Patchlist -NoTypeInformation -Force
            

            $count = 0
            foreach ($server in $windowsServers) {
                #$NextPatchDate = [DateTime]::ParseExact($server.next_patch_date, "M/d/yyyy hh:mm:ss tt", $null).ToString("MM/dd/yyyy")
                #$NextPatchDate
                #$server.hostname
                #$arg1 = ($server.next_patch_date).TryFormat("d/m/yyyy hh:mm:ss tt")
                $arg1 = $server.next_patch_date.ToString("d/M/yyyy")
                $arg2 = $server.patch_window
                # Parse date from the first argument
                $dateFromArg1 = $arg1 #[datetime]::Parse($arg1, "dddd, MMMM dd, yyyy hh:mm:ss tt", $null)
                
                # Parse time from the second argument
                $timeFromArg2 = ($arg2 -split '-')[2]
                $dateTimeString = "$datefromarg1 $timeFromArg2"
                $NewdateTime = [datetime]::ParseExact($dateTimeString, "dd/M/yyyy HH:mm", [System.Globalization.CultureInfo]::InvariantCulture)
                # Combine date and time into a new DateTime object

                # Add minutes based on the patch priority (lower number means higher urgency)
                if ($server.patch_priority -eq "2") {
                    $newDateTime = $NewdateTime.Addminutes(45)
                }
                elseif ($server.patch_priority -eq "3") {
                    $newDateTime = $NewdateTime.AddMinutes(90)
                }
                elseif ($server.patch_priority -eq "4") {
                    $newDateTime = $NewdateTime.AddMinutes(135)
                }
                elseif ($server.patch_priority -eq "5") {
                    $newDateTime = $NewdateTime.AddMinutes(180)
                }
                elseif ($server.patch_priority -eq "6") {
                    $newDateTime = $NewdateTime.AddMinutes(225)
                }
                # add Reboot Time to for each server
                $server | Add-Member -Name "rebootTime" -Value $NewdateTime -MemberType NoteProperty


                #replace email address with the display name
                if ($server.primary_contact) {
                    $primaryEmail = Get-EmailAddress -displayName $server.primary_contact
                    $server.primary_contact = $primaryEmail
                }
                if ($null -ne $server.secondary_contact) {
                    
                    
                    $secondaryEmail = Get-EmailAddress -displayName  $server.secondary_contact
                    $server.secondary_contact = $secondaryEmail
                }
                $domains = "jewels.com", "jewels.local", "irving.zalecorp.com"

                foreach ($domain in $domains) {
                    try {
                        $FQDN = Get-ADComputer -Identity $server -Server $domain -Properties DNSHostName -ErrorAction Stop | Select-Object -ExpandProperty DNSHostName
                        $server | Add-Member -Name "FQDN" -Value $FQDN -MemberType NoteProperty
                    }
                    catch {
                        continue
                    }
                }
                
                $server  | Export-Csv -Path $Patchlist -NoTypeInformation -Append -Force
                $count++

            }
            
        }
        catch {
            Write-Host "Error: $_" -ForegroundColor Red
            break
        }

    }
    
    end {

        write-host "$count servers exported to $Patchlist successfully" -ForegroundColor Green
    }
}


#Generate_PatchList