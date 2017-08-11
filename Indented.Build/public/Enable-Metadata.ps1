filter Enable-Metadata {
    <#
    .SYNOPSIS
        Enable a metadata property which has been commented out.
    .DESCRIPTION
        This function is derived Get and Update-Metadata from PoshCode\Configuration.
    
        A boolean value is returned indicating if the property is available in the metadata file.

        If the property does not exist, or exists more than once within the specified file this command will return false.
    .INPUTS
        System.String
    .EXAMPLE
        Enable-Metadata .\module.psd1 -PropertyName RequiredAssemblies

        Enable an existing (commented) RequiredAssemblies property within the module.psd1 file.
    .NOTES
        Change log:
            04/08/2016 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        # A valid metadata file or string containing the metadata.
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias("PSPath")]
        [String]$Path,

        # The property to enable.
        [String]$PropertyName
    )

    # If the element can be found using Get-Metadata leave it alone and return true
    $shouldEnable = $false
    try {
        $null = Get-Metadata @psboundparameters -ErrorAction Stop
    } catch [System.Management.Automation.ItemNotFoundException] {
        # The function will only execute where the requested value is not present
        $shouldEnable = $true
    } catch {
        # Ignore other errors which may be raised by Get-Metadata except path not found.
        if ($_.Exception.Message -eq 'Path must point to a .psd1 file') {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }
    if (-not $shouldEnable) {
        return $true
    }

    $manifestContent = Get-Content $Path -Raw

    $tokens = $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $manifestContent,
        $Path,
        [Ref]$tokens,
        [Ref]$parseErrors
    )

    # Attempt to find a comment which matches the requested property
    $regex = '^ *# *({0}) *=' -f $PropertyName
    $existingValue = @($tokens | Where-Object { $_.Kind -eq 'Comment' -and $_.Text -match $regex })
    if ($existingValue.Count -eq 1) {
        $manifestContent = $ast.Extent.Text.Remove(
            $existingValue.Extent.StartOffset,
            $existingValue.Extent.EndOffset - $existingValue.Extent.StartOffset
        ).Insert(
            $existingValue.Extent.StartOffset,
            $existingValue.Extent.Text -replace '^# *'
        )

        try {
            Set-Content -Path $Path -Value $manifestContent -NoNewline -ErrorAction Stop
            $true
        } catch {
            $false
        }
    } elseif ($existingValue.Count -eq 0) {
        # Item not found
        Write-Warning "Cannot find disabled property '$PropertyName' in $Path"
        $false
    } else {
        # Ambiguous match
        Write-Warning "Found more than one '$PropertyName' in $Path"
        $false
    }
}