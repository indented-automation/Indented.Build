BuildTask PublishToCurrentUser -Stage Publish -Properties @{
    Implementation = {
        Copy-Item $buildInfo.Package -Destination "$home\Documents\WindowsPowerShell\Modules" -Recurse
    }
}