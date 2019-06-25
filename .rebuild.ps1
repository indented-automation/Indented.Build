Invoke-Build .\.build.bootstrap.ps1 -Task Build
Invoke-build -Task Setup, Build, Test -BuildInfo (Get-BuildInfo)