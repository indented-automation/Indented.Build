function TestAdministrator {
    [OutputType([Boolean])]
    param ( )

    ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).
        IsInRole([System.Security.Principal.WindowsBuiltInRole]'Administrator')
}