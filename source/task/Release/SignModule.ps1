BuildTask SignModule -Stage Release -Properties @{
    Order          = 1
    ValidWhen      = { $null -ne $env:CODESIGNINGCERTIFICATE }
    Implementation = {
        Set-AuthenticodeSignature '...'
    }
}