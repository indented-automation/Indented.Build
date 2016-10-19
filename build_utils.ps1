function ConvertTo-Hashtable {
    # A very short function to convert a PSObject into a Hashtable. Generates splattable params.

    param(
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$PSObject
    )

    process {
        $hashtable = @{}
        foreach ($property in $PSObject.PSObject.Properties) {
            $hashtable.($property.Name) = $property.Value
        }
        $hashtable
    }
}

function Enable-Metadata {
    # .SYNOPSIS
    #   Enable a metadata property which has been commented out.
    # .DESCRIPTION
    #   This function is derived Get and Update-Metadata from PoshCode\Configuration.
    #
    #   A boolean value is returned indicating if the property is available in the metadata file.
    # .PARAMETER Path
    #   A valid metadata file or string containing the metadata.
    # .PARAMETER PropertyName
    #   The property to enable.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Boolean
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     04/08/2016 - Chris Dent - Created.

    [CmdletBinding()]
