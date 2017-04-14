InModuleScope Indented.Build {
    Describe Enable-Metadata {
        Mock Get-Content {
            '@{
                Enabled = 1
                # Disabled = 2     
            }'
        }
        Mock Get-Metadata
        Mock Set-Content
    
    }
}