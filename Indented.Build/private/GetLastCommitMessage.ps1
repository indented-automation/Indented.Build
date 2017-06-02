function GetLastCommitMessage {
    [OutputType([String])]
    param ( )

    return (git log -1 --pretty=%B | Where-Object { $_ } | Out-String).Trim()
}