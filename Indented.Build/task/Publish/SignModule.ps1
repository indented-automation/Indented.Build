BuildTask SignModule -Stage Publish -Order 1 -If {
    $env:CodeSigningCertificate
} -Definition {
    Set-AuthenticodeSignature '...'
}