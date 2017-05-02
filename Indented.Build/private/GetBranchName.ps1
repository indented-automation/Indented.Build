function GetBranchName {
    [OutputType([String])]
    param ( )

    return git rev-parse --abbrev-ref HEAD 2> $null
}