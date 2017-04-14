BuildTask SignModule -Stage Release -Properties @{
    Order          = 1
    ValidWhen      = { $null -ne $env:CodeSigningCertificate }
    Implementation = {
        Set-AuthenticodeSignature '...'
    }
}