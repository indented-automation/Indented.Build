BuildTask SignModule -Stage Release -Order 1 -If { $null -ne $env:CodeSigningCertificate } -Definition {
    Set-AuthenticodeSignature '...'
}