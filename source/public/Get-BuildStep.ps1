function Get-BuildStep {
    [CmdletBinding()]
    param(
        [String]$StepName
    )

    Get-ChildItem $pwd\steps -File -Recurse |
        Where-Object { $_.BaseName -like $StepName -and $_.Length -gt 0 } |
        Get-FunctionInfo
        # |
        #ForEach-Object {
        #    [PSCustomObject]@{
        #        Name       = $_.BaseName
        #        Definition = $stepDefinition.Length
        #        BuildStep  = Get-FunctionInfo -ScriptBlock $stepDefinition
        #    }
        #}
}