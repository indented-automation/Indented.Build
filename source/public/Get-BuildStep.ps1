function Get-BuildStep {
    [CmdletBinding()]
    param(
        [String]$StepName
    )

    Get-ChildItem $psscriptroot\steps -File -Recurse |
        Where-Object { $_.StepName -like $StepName } |
        ForEach-Object {
            [PSCustomObject]@{
                Name = $_.BaseName
                Definition = (Get-Content $_.FullName) -Raw
            }
        }
}