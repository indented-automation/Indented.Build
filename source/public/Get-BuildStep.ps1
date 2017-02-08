function Get-BuildStep {
    # .SYNOPSIS
    #   Get a build step definition.
    # .DESCRIPTION
    #   Get the definition of a build step.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     08/02/2017 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        # The name of a step.
        [String]$StepName = '*'
    )

    Get-ChildItem $psscriptroot\steps -File -Recurse |
        Where-Object { $_.BaseName -like $StepName -and $_.Length -gt 0 } |
        ForEach-Object {
            $buildStep = ($_ | Get-FunctionInfo).ScriptBlock.Attributes | Where-Object { $_ -is [BuildStep] }
            
            [PSCustomObject]@{
                Name           = $_.BaseName
                Definition     = (Get-Content $_.FullName -Raw).Trim()
                BuildStep      = $buildStep
                BuildStepType  = $buildStep.BuildType
                BuildSteporder = $buildStep.Order
            }
        }
}