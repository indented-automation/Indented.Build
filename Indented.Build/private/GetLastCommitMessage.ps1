function GetLastCommitMessage {
    [OutputType([String])]
    param ( )

    return (git log -1 --pretty=%B 2> $null | Where-Object { $_ } | Out-String).Trim()
}