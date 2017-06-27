task CreateNuspec {
    Add-Type -AssemblyName System.Xml.Linq

    [String]$path = New-Item (Join-Path $buildInfo.Path.Output 'pack') -ItemType Directory

    Push-Location $path
    $nuspecPath = Join-Path $path 'Package.nuspec'
    nuget spec

    $manifest = Import-PowerShellDataFile -Path $buildInfo.Path.Manifest.FullName
    $nuspec = [System.Xml.Linq.XDocument]::Load($nuspecPath)
    $metadata = $nuspec.Element('package').Element('metadata')

    $metadata.Element('id').Value = $buildInfo.ModuleName.ToLower()
    if ($manifest.Description) {
        $metadata.Element('description').Value = $manifest.Description
    } else {
        $metadata.Element('description').Value = $buildInfo.ModuleName
    }
    $metadata.Element('version').Value = $manifest.ModuleVersion
    $metadata.Element('authors').Value = $manifest.Author
    $metadata.Element('owners').Value = $manifest.CompanyName
    $metadata.Element('copyright').Value = $manifest.Copyright

    $tags = @('PowerShell')
    if ($manifest.Contains('DscResourcesToExport') -and $manifest.DscResourcesToExport.Count -gt 0) {
        $tags += 'DSC'
    }
    $metadata.Element('tags').Value = $tags -join ' '

    if ($manifest.PrivateData.PSData.ProjectUri) {
        $metadata.Element('projectUrl').Value = $manifest.PrivateData.PSData.ProjectUri
    } else {
        $metadata.Element('projectUrl').Remove()
    }

    foreach ($nodeName in 'iconUrl', 'licenseUrl', 'releaseNotes', 'dependencies') {
        $metadata.Element($nodeName).Remove()
    }

    $nuspec.Save((Join-Path $path ('{0}.nuspec' -f $buildInfo.ModuleName)))
    Remove-Item $nuspecPath

    Pop-Location
}
