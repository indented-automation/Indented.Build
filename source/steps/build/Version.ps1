function Version {
    # .SYNOPSIS
    #   Update the version number in the module manifest.
    # .DESCRIPTION
    #   Increments the version according to the release type.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     01/02/2017 - Chris Dent - Added help.
    
    $path = Join-Path 'source' $buildInfo.Manifest

    # Increment the version according to the release type.
    if (Test-Path $path) {
        $buildInfo.Version = Update-Metadata $path -Increment $buildInfo.ReleaseType -PassThru
        $buildInfo.ModuleName = (Get-Item 'source').GetFiles($buildInfo.Manifest).BaseName
    } else {
        $params = @{
            ModuleVersion = $Script:buildInfo.Version
        }
        New-ModuleManifest $path @params
    }
}