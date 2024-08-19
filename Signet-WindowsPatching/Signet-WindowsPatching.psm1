# Define the root path of the module
$ModuleRootPath = Split-Path -Parent $PSScriptRoot
#requires -Version 3.0
$script:ModuleRoot = $PSScriptRoot
# Export the root path so it's available to other scripts
$global:dirroot = $ModuleRootPath

$directorySeparator = [System.IO.Path]::DirectorySeparatorChar
$moduleName = $PSScriptRoot.Split($directorySeparator)[-1]
$moduleManifest = $PSScriptRoot + $directorySeparator + $moduleName + '.psd1'
$publicFunctionsPath = $PSScriptRoot + $directorySeparator + 'Public' + $directorySeparator + 'ps1'
$privateFunctionsPath = $PSScriptRoot + $directorySeparator + 'Private' + $directorySeparator + 'ps1'
$classesPath = $PSScriptRoot + $directorySeparator + 'Classes' 
$currentManifest = Test-ModuleManifest $moduleManifest

$aliases = @()
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath | Where-Object { $_.Extension -eq '.ps1' }
$privateFunctions = Get-ChildItem -Path $privateFunctionsPath | Where-Object { $_.Extension -eq '.ps1' }
$classes = Get-ChildItem -Path $classesPath | Where-Object { $_.Extension -eq '.ps1' }
$publicFunctions | ForEach-Object { . $_.FullName }
$privateFunctions | ForEach-Object { . $_.FullName }
$classes | ForEach-Object { . $_.FullName }

$publicFunctions | ForEach-Object { # Export all of the public functions from this module

    # The command has already been sourced in above. Query any defined aliases.
    $alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
    if ($alias) {
        $aliases += $alias
        Export-ModuleMember -Function $_.BaseName -Alias $alias
    }
    else {
        Export-ModuleMember -Function $_.BaseName
    }

}

$functionsAdded = $publicFunctions | Where-Object { $_.BaseName -notin $currentManifest.ExportedFunctions.Keys }
$functionsRemoved = $currentManifest.ExportedFunctions.Keys | Where-Object { $_ -notin $publicFunctions.BaseName }
$aliasesAdded = $aliases | Where-Object { $_ -notin $currentManifest.ExportedAliases.Keys }
$aliasesRemoved = $currentManifest.ExportedAliases.Keys | Where-Object { $_ -notin $aliases }

if ($functionsAdded -or $functionsRemoved -or $aliasesAdded -or $aliasesRemoved) {

    try {

        $updateModuleManifestParams = @{}
        $updateModuleManifestParams.Add('Path', $moduleManifest)
        $updateModuleManifestParams.Add('ErrorAction', 'Stop')
        if ($aliases.Count -gt 0) { $updateModuleManifestParams.Add('AliasesToExport', $aliases) }
        if ($publicFunctions.Count -gt 0) { $updateModuleManifestParams.Add('FunctionsToExport', $publicFunctions.BaseName) }

        Update-ModuleManifest @updateModuleManifestParams

    }
    catch {

        $_ | Write-Error

    }

}