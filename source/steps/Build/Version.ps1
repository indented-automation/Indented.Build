function Version {

    # Prefer to use version numbers from git.
    try {
        $currentVersion = (git describe --tags) -replace '^v'
    } catch {
        $currentVersion = ''
    }
    if (-not $currentVersion -or -not [Version]::TryParse($currentVersion, [Ref]$null)) {
        # Fall back to version numbers in the manifest.
        $sourceManifest = [Path]::Combine($BuildInfo.Source, 'source', ('{0}.psd1' -f $this.ModuleName))
        if (Test-Path $sourceManifest) {
            $currentVersion = Get-Metadata -Path $sourceManifest -PropertyName ModuleVersion
        }
    }
    if ($currentVersion) {
        $newVersion = [Version]$currentVersion | Select-Object * | Add-Member ToString -MemberType ScriptMethod -PassThru -Force -Value {
            if ($this.Build -eq -1) {
                $this.Build = 0
            }
            return '{0}.{1}.{2}' -f $this.Major, $this.Minor, $this.Build
        }

        switch ($this.ReleaseType) {
            'Major' { $newVersion.Major++; $newVersion.Minor = 0; $newVersion.Build = 0 }
            'Minor' { $newVersion.Minor++; $newVersion.Build = 0 }
            'Build' { $newVersion.Build++ }
        }

        return [Version]$newVersion.ToString()
    } else {
        return [Version]'0.0.1'
    }
}