BuildTask SignModule -Stage Publish -Order 1 -If {
    $env:CodeSigningCertificate
} -Definition {
    # If a code signing certificate is defined, sign the module content.

    Set-AuthenticodeSignature '...'
}