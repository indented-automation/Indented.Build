function GetBranchName {
    [OutputType([String])]
    param ( )

    git rev-parse --abbrev-ref HEAD
}