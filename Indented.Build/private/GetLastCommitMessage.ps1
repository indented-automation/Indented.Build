function GetLastCommitMessage {
    <#
    .SYNOPSIS
        Get the last git commit message.
    .DESCRIPTION
        Attempt to get the last git commit message.
    #>

    [OutputType([String])]
    param ( )

    return (git log -1 --pretty=%B 2> $null | Where-Object { $_ } | Out-String).Trim()
}