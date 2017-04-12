BuildTask Clean -Stage Build -Properties @{
    ValidWhen      = { -not (Test-Path 'classes\*.sln') -and (Test-Path 'classes\*.cs') }
    Implementation = {}
}