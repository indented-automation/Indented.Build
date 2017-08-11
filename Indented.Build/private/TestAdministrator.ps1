using namespace System.Security.Principal

function TestAdministrator {
    [OutputType([Boolean])]
    param ( )

    ([WindowsPrincipal][WindowsIdentity]::GetCurrent()).
        IsInRole([WindowsBuiltInRole]'Administrator')
}