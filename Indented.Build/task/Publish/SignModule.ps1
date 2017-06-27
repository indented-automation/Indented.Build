BuildTask SignModule -Stage Publish -Order 1 -If { $null -ne $env:CodeSigningCertificate } -Definition {
    Set-AuthenticodeSignature '...'
}