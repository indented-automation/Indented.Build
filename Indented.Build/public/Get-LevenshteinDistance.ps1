function Get-LevenshteinDistance {
    <#
    .SYNOPSIS
        Get the Levenshtein distance between two strings.
    .DESCRIPTION
        The Levenshtein distance represents the number of changes required to change one string into another. This algorithm can be used to test for typing errors.

        This command makes use of the Fastenshtein library.

        Credit for this algorithm goes to Dan Harltey. Converted to PowerShell from https://github.com/DanHarltey/Fastenshtein/blob/master/src/Fastenshtein/StaticLevenshtein.cs.
    #>

    [CmdletBinding()]
    param (
        # The reference string.
        [Parameter(Mandatory)]
        [String]$ReferenceString,

        # The different string.
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [String]$DifferenceString
    )

    process {
        if ($DifferenceString.Length -eq 0) {
            return $ReferenceString.Length
        }

        $costs = [Int[]]::new($DifferenceString.Length)

        for ($i = 0; $i -lt $costs.Count; $i++) {
            $costs[$i] = $i + 1
        }

        for ($i = 0; $i -lt $ReferenceString.Length; $i++) {
            $cost = $i
            $additionCost = $i

            $value1Char = $ReferenceString[$i]

            for ($j = 0; $j -lt $DifferenceString.Length; $j++) {
                $insertionCost = $cost
                $cost = $additionCost

                $additionCost = $costs[$j]

                if ($value1Char -ne $DifferenceString[$j]) {
                    if ($insertionCost -lt $cost) {
                        $cost = $insertionCost
                    }
                    if ($additionCost -lt $cost) {
                        $cost = $additionCost
                    }

                    ++$cost
                }

                $costs[$j] = $cost
            }
        }

        [PSCustomObject]@{
            ReferenceString  = $ReferenceString
            DifferenceString = $DifferenceString
            Distance         = $costs[$costs.Count - 1]
        }
    }
}